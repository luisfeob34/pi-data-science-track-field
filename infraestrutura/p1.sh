#!/usr/bin/env bash
# Gerencia as duas VMs do projeto, sua configuração, a geração de dados e a publicação no DW.
# - geradora (SSH 2222): executa o simulador em R e guarda os lotes CSV;
# - exibicao (SSH 2223): Data Warehouse PostgreSQL e painel Shiny em http://localhost:8080.
# Interrompe em erros, variáveis não definidas e falhas em pipelines.
set -euo pipefail
# Resolve os caminhos a partir deste arquivo, independentemente da pasta atual.
infra=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
raiz=$(dirname "$infra")
# Guarda imagens, chaves e arquivos de execução fora do repositório.
# P1_RUNTIME permite escolher outro caminho que respeite a validação abaixo.
export P1_RUNTIME="${P1_RUNTIME:-$HOME/.local/share/pi-track-field-p1}"
P1_RUNTIME=$(realpath -m "$P1_RUNTIME")
export P1_RUNTIME
# Exige um caminho absoluto em /home/ com o nome de pasta esperado.
[[ "$P1_RUNTIME" == /home/*/pi-track-field-p1 ]] || { echo 'Use uma pasta Linux em /home/ terminada em /pi-track-field-p1.' >&2; exit 1; }
mkdir -p "$P1_RUNTIME" "$infra/evidencias"
# Restringe o acesso à pasta de execução ao seu proprietário.
chmod 700 "$P1_RUNTIME"
# Disponibiliza o caminho como variável de entrada do OpenTofu.
export TF_VAR_runtime_dir="$P1_RUNTIME"
# Usa a chave dedicada sem prompts e mantém os hosts conhecidos nesta execução.
# Chaves de hosts novos são aceitas; alterações de chaves conhecidas são recusadas.
ssh_opcoes=(-i "$P1_RUNTIME/id_ed25519" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15
  -o StrictHostKeyChecking=accept-new -o "UserKnownHostsFile=$P1_RUNTIME/known_hosts")
VMS=(geradora exibicao)
# Porta SSH de cada VM no host local (a mesma definida em vm.sh).
porta() {
  case "$1" in
    geradora) echo 2222 ;;
    exibicao) echo 2223 ;;
    *) echo "VM desconhecida: $1 (use geradora ou exibicao)" >&2; return 1 ;;
  esac
}
# Executa comandos em uma VM pelo encaminhamento SSH: em_vm <vm> <comando>.
em_vm() { local p; p=$(porta "$1"); shift; ssh "${ssh_opcoes[@]}" -p "$p" pi@127.0.0.1 "$@"; }
# A maior parte dos comandos da P1 atua na VM geradora.
remoto() { em_vm geradora "$@"; }
# Tenta conectar por até 15 minutos e, depois, aguarda o cloud-init terminar.
esperar() {
  local vm=${1:-geradora}
  echo "Aguardando SSH da VM $vm (ate 15 minutos)..."
  local limite=$((SECONDS + 900))
  while (( SECONDS < limite )); do
    if em_vm "$vm" true 2>"$P1_RUNTIME/ssh-espera.txt"; then
      em_vm "$vm" 'sudo cloud-init status --wait'
      return
    fi
    sleep 5
  done
  echo "SSH indisponivel. Consulte o console.log da VM $vm em $P1_RUNTIME" >&2
  cat "$P1_RUNTIME/ssh-espera.txt" >&2
  return 1
}
# Valida o nome da VM opcional dos comandos iniciar, parar, status e ssh.
alvo() {
  case "${1:-geradora}" in
    geradora|exibicao) echo "${1:-geradora}" ;;
    todas) echo "${VMS[*]}" ;;
    *) echo "VM desconhecida: $1 (use geradora, exibicao ou todas)" >&2; return 1 ;;
  esac
}
inventario() {
  # Gera o inventário do Ansible com um grupo por VM, endereço e chave de acesso.
  # JSON evita problemas com espacos em caminhos.
  python3 - "$P1_RUNTIME" <<'PY'
import json, pathlib, shlex, sys
p = pathlib.Path(sys.argv[1])
def host(porta):
    return dict(ansible_host='127.0.0.1', ansible_port=porta, ansible_user='pi',
                ansible_ssh_private_key_file=str(p/'id_ed25519'),
                ansible_python_interpreter='/usr/bin/python3',
                ansible_ssh_common_args='-o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o '+shlex.quote('UserKnownHostsFile='+str(p/'known_hosts')))
grupos = {'geradora': {'hosts': {'vm_geradora': host(2222)}},
          'exibicao': {'hosts': {'vm_exibicao': host(2223)}}}
(p/'inventory.yml').write_text(json.dumps({'all': {'children': grupos}}, indent=2))
PY
}
# O primeiro argumento seleciona a operação; sem argumento, exibe o uso.
case "${1:-ajuda}" in
  criar)
    # Confere as ferramentas necessárias antes de provisionar a infraestrutura.
    for cmd in tofu qemu-system-x86_64 qemu-img cloud-localds ansible-playbook; do
      command -v "$cmd" >/dev/null || { echo 'Execute bash infraestrutura/preparar-host.sh primeiro.' >&2; exit 1; }
    done
    # Reutiliza a chave SSH existente ou cria uma chave exclusiva para as VMs.
    if [[ ! -f "$P1_RUNTIME/id_ed25519" ]]; then
      ssh-keygen -q -t ed25519 -N '' -C pi-track-field-p1 -f "$P1_RUNTIME/id_ed25519"
    fi
    # Baixa a imagem Ubuntu apenas se necessário e verifica seu SHA-256.
    if [[ ! -f "$P1_RUNTIME/base.img" ]]; then
      url=https://cloud-images.ubuntu.com/noble/current
      curl -fL --retry 3 "$url/SHA256SUMS" -o "$P1_RUNTIME/SHA256SUMS"
      curl -fL --retry 3 "$url/noble-server-cloudimg-amd64.img" -o "$P1_RUNTIME/noble-server-cloudimg-amd64.img"
      (cd "$P1_RUNTIME"; grep ' noble-server-cloudimg-amd64.img$\|\*noble-server-cloudimg-amd64.img$' SHA256SUMS | sha256sum --check --strict)
      mv "$P1_RUNTIME/noble-server-cloudimg-amd64.img" "$P1_RUNTIME/base.img"
    fi
    # Inicializa o OpenTofu, salva o plano e aplica exatamente esse plano (as duas VMs).
    tofu -chdir="$infra" init -no-color
    tofu -chdir="$infra" plan -no-color -out=p1.tfplan
    # Uma VM por vez: evita pico de memória e disputa pelo known_hosts compartilhado.
    tofu -chdir="$infra" apply -no-color -parallelism=1 p1.tfplan
    # Inicia as VMs e aguarda a preparação inicial de cada uma.
    for vm in "${VMS[@]}"; do VM=$vm bash "$infra/vm.sh" start; done
    for vm in "${VMS[@]}"; do esperar "$vm"; done
    ;;
  configurar)
    # Configura as VMs ligadas; uma VM desligada é ignorada em vez de travar a espera.
    ativas=()
    for vm in "${VMS[@]}"; do
      if VM=$vm bash "$infra/vm.sh" status >/dev/null 2>&1; then
        esperar "$vm"
        ativas+=("$vm")
      else
        echo "VM $vm desligada: configuracao ignorada (ligue com p1.sh iniciar $vm)."
      fi
    done
    (( ${#ativas[@]} )) || { echo 'Nenhuma VM ligada para configurar.' >&2; exit 1; }
    inventario
    ANSIBLE_NOCOLOR=1 ansible-playbook -i "$P1_RUNTIME/inventory.yml" --limit "$(IFS=,; echo "${ativas[*]}")" \
      "$infra/ansible/playbook.yml"
    ;;
  transferir)
    # Copia as regras e os scripts R para as pastas já preparadas na VM geradora.
    scp "${ssh_opcoes[@]}" -P 2222 "$raiz/R/dados.R" pi@127.0.0.1:/opt/pi-track-field/R/dados.R
    scp "${ssh_opcoes[@]}" -P 2222 "$raiz/simulador/gerar_dados.R" "$raiz/simulador/validar.R" pi@127.0.0.1:/opt/pi-track-field/simulador/
    echo 'Simulador e regras R transferidos por SCP para a VM geradora.'
    ;;
  simular)
    # Aceita quantidade e semente opcionais; usa 1000 e uma semente aleatória.
    quantidade=${2:-1000}
    semente=${3:-$RANDOM}
    # Permite somente dígitos antes de inserir os argumentos no comando remoto.
    [[ "$quantidade" =~ ^[0-9]+$ && "$semente" =~ ^[0-9]+$ ]] || {
      echo 'Quantidade e semente devem ser inteiros positivos.' >&2; exit 1;
    }
    remoto "Rscript /opt/pi-track-field/simulador/gerar_dados.R /opt/pi-track-field/dados $quantidade $semente"
    ;;
  validar)
    # Mostra informações das VMs, valida os dados gerados e confere os serviços da exibição.
    remoto 'set -e; hostname; uname -r; cloud-init status; Rscript /opt/pi-track-field/simulador/validar.R /opt/pi-track-field/dados'
    em_vm exibicao "set -e; hostname; cloud-init status; systemctl is-active postgresql pi-painel
      echo -n 'Ultima carga do DW: '
      psql -X -d dw_vendas -Atc \"SELECT coalesce((SELECT execucao_spark FROM dw.cargas ORDER BY carregado_em DESC LIMIT 1), 'nenhuma')\""
    ;;
  publicar)
    # Carrega a última execução Spark no Data Warehouse da VM de exibição e reinicia o painel.
    # Opcional: informe o identificador exec-... de outra execução já concluída.
    resultados="${PI_PIPELINE_ROOT:-$raiz}/results/bigdata"
    id=${2:-$(cat "$resultados/ultima.txt" 2>/dev/null || true)}
    [[ "$id" =~ ^exec-[A-Za-z0-9-]+$ ]] || { echo 'Nenhuma execucao Spark publicada. Rode scripts/pipeline_bigdata.sh antes.' >&2; exit 1; }
    pasta="$resultados/$id/dw"
    for tabela in dim_produto dim_canal dim_regiao dim_data fato_vendas; do
      [[ -s "$pasta/$tabela.csv" ]] || { echo "Arquivo ausente: $pasta/$tabela.csv" >&2; exit 1; }
    done
    esperar exibicao
    # Copia para uma pasta temporária e só então publica, para não misturar cargas.
    em_vm exibicao "rm -rf /opt/pi-track-field/carga/.recebendo && mkdir -p /opt/pi-track-field/carga/.recebendo"
    scp "${ssh_opcoes[@]}" -P 2223 "$pasta"/*.csv pi@127.0.0.1:/opt/pi-track-field/carga/.recebendo/
    # A carga roda em uma transação: se falhar, o DW mantém a carga anterior.
    em_vm exibicao "set -e; rm -rf /opt/pi-track-field/carga/$id; mv /opt/pi-track-field/carga/.recebendo /opt/pi-track-field/carga/$id
      cd /opt/pi-track-field/carga/$id
      psql -X -v ON_ERROR_STOP=1 -v execucao=$id -d dw_vendas -f /opt/pi-track-field/dw/carregar.sql
      sudo systemctl restart pi-painel"
    echo "Execucao $id carregada no Data Warehouse. Painel: http://localhost:8080"
    ;;
  demonstrar)
    # Exibe e grava toda a saída, incluindo erros, em um arquivo de evidência.
    exec > >(tee "$infra/evidencias/demonstracao-$(date -u +%Y%m%dT%H%M%S)-$$.txt") 2>&1
    date -u
    # Executa o fluxo completo de provisionamento e geração de dados.
    for etapa in criar configurar transferir simular; do
      echo "===== $etapa ====="
      bash "$infra/p1.sh" "$etapa"
    done
    # Registra os hashes existentes para confirmar que outra simulação os preserva.
    remoto 'find /opt/pi-track-field/dados -name vendas.csv -type f -exec sha256sum {} \;' > "$P1_RUNTIME/antes.sha256"
    bash "$infra/p1.sh" simular
    remoto 'sha256sum --check' < "$P1_RUNTIME/antes.sha256"
    bash "$infra/p1.sh" validar
    # Reaplica o Ansible e exige, nas duas VMs, resumo sem mudanças, hosts inacessíveis ou falhas.
    bash "$infra/p1.sh" configurar | tee "$P1_RUNTIME/ansible-segunda.txt"
    ok=$(grep -cE '^vm_(geradora|exibicao)[[:space:]].*changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' "$P1_RUNTIME/ansible-segunda.txt" || true)
    [[ "$ok" == 2 ]] || { echo 'A segunda aplicacao nao confirmou idempotencia nas duas VMs.' >&2; exit 1; }
    echo 'Concluido: dados preservados e Ansible idempotente nas duas VMs (changed=0).'
    echo 'As VMs continuam ligadas. Desligue com: bash infraestrutura/p1.sh parar todas'
    ;;
  baixar)
    # Copia os dados da VM geradora para uma nova pasta local de evidências.
    destino="$infra/evidencias/dados-$(date -u +%Y%m%dT%H%M%S)-$$"
    mkdir "$destino"
    scp "${ssh_opcoes[@]}" -P 2222 -r pi@127.0.0.1:/opt/pi-track-field/dados "$destino/"
    echo "Dados copiados para $destino"
    ;;
  # Atalhos para abrir uma sessão interativa e controlar o estado das VMs.
  # O segundo argumento escolhe a VM: geradora (padrão), exibicao ou todas.
  # A atribuição separada faz o set -e interromper quando o nome da VM é inválido.
  ssh)
    vm=$(alvo "${2:-geradora}")
    [[ "$vm" != *' '* ]] || { echo 'Escolha uma VM: geradora ou exibicao.' >&2; exit 1; }
    p=$(porta "$vm")
    ssh "${ssh_opcoes[@]}" -t -p "$p" pi@127.0.0.1 ;;
  iniciar)
    vms=$(alvo "${2:-}")
    for vm in $vms; do VM=$vm bash "$infra/vm.sh" start; esperar "$vm"; done ;;
  parar)
    vms=$(alvo "${2:-}")
    for vm in $vms; do VM=$vm bash "$infra/vm.sh" stop; done ;;
  status)
    vms=$(alvo "${2:-todas}")
    codigo=0
    for vm in $vms; do VM=$vm bash "$infra/vm.sh" status || codigo=1; done
    exit "$codigo" ;;
  *) echo 'Uso: bash infraestrutura/p1.sh criar|configurar|transferir|simular|validar|publicar|demonstrar|baixar'
     echo '     bash infraestrutura/p1.sh iniciar|parar|status|ssh [geradora|exibicao|todas]' ;;
esac
