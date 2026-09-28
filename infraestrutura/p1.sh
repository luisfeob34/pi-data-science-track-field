#!/usr/bin/env bash
set -euo pipefail
infra=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
raiz=$(dirname "$infra")
export P1_RUNTIME="${P1_RUNTIME:-$HOME/.local/share/pi-track-field-p1}"
P1_RUNTIME=$(realpath -m "$P1_RUNTIME")
export P1_RUNTIME
[[ "$P1_RUNTIME" == /home/*/pi-track-field-p1 ]] || { echo 'Use uma pasta Linux em /home/ terminada em /pi-track-field-p1.' >&2; exit 1; }
mkdir -p "$P1_RUNTIME" "$infra/evidencias"
chmod 700 "$P1_RUNTIME"
export TF_VAR_runtime_dir="$P1_RUNTIME"
ssh_opcoes=(-i "$P1_RUNTIME/id_ed25519" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15
  -o StrictHostKeyChecking=accept-new -o "UserKnownHostsFile=$P1_RUNTIME/known_hosts")
remoto() { ssh "${ssh_opcoes[@]}" -p 2222 pi@127.0.0.1 "$@"; }
esperar() {
  echo 'Aguardando SSH da VM (ate 15 minutos)...'
  local limite=$((SECONDS + 900))
  while (( SECONDS < limite )); do
    if remoto true 2>"$P1_RUNTIME/ssh-espera.txt"; then
      remoto 'sudo cloud-init status --wait'
      return
    fi
    sleep 5
  done
  echo "SSH indisponivel. Consulte $P1_RUNTIME/console.log" >&2
  cat "$P1_RUNTIME/ssh-espera.txt" >&2
  return 1
}
inventario() {
  # JSON evita problemas com espacos em caminhos.
  python3 - "$P1_RUNTIME" <<'PY'
import json, pathlib, shlex, sys
p = pathlib.Path(sys.argv[1])
host = dict(ansible_host='127.0.0.1', ansible_port=2222, ansible_user='pi',
            ansible_ssh_private_key_file=str(p/'id_ed25519'),
            ansible_python_interpreter='/usr/bin/python3',
            ansible_ssh_common_args='-o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o '+shlex.quote('UserKnownHostsFile='+str(p/'known_hosts')))
(p/'inventory.yml').write_text(json.dumps({'all': {'children': {'p1': {'hosts': {'vm_p1': host}}}}}, indent=2))
PY
}
case "${1:-ajuda}" in
  criar)
    for cmd in tofu qemu-system-x86_64 qemu-img cloud-localds ansible-playbook; do
      command -v "$cmd" >/dev/null || { echo 'Execute bash infraestrutura/preparar-host.sh primeiro.' >&2; exit 1; }
    done
    if [[ ! -f "$P1_RUNTIME/id_ed25519" ]]; then
      ssh-keygen -q -t ed25519 -N '' -C pi-track-field-p1 -f "$P1_RUNTIME/id_ed25519"
    fi
    if [[ ! -f "$P1_RUNTIME/base.img" ]]; then
      url=https://cloud-images.ubuntu.com/noble/current
      curl -fL --retry 3 "$url/SHA256SUMS" -o "$P1_RUNTIME/SHA256SUMS"
      curl -fL --retry 3 "$url/noble-server-cloudimg-amd64.img" -o "$P1_RUNTIME/noble-server-cloudimg-amd64.img"
      (cd "$P1_RUNTIME"; grep ' noble-server-cloudimg-amd64.img$\|\*noble-server-cloudimg-amd64.img$' SHA256SUMS | sha256sum --check --strict)
      mv "$P1_RUNTIME/noble-server-cloudimg-amd64.img" "$P1_RUNTIME/base.img"
    fi
    tofu -chdir="$infra" init -no-color
    tofu -chdir="$infra" plan -no-color -out=p1.tfplan
    tofu -chdir="$infra" apply -no-color p1.tfplan
    bash "$infra/vm.sh" start
    esperar
    ;;
  configurar)
    esperar
    inventario
    ANSIBLE_NOCOLOR=1 ansible-playbook -i "$P1_RUNTIME/inventory.yml" "$infra/ansible/playbook.yml"
    ;;
  transferir)
    scp "${ssh_opcoes[@]}" -P 2222 "$raiz/R/dados.R" pi@127.0.0.1:/opt/pi-track-field/R/dados.R
    scp "${ssh_opcoes[@]}" -P 2222 "$raiz/simulador/gerar_dados.R" "$raiz/simulador/validar.R" pi@127.0.0.1:/opt/pi-track-field/simulador/
    echo 'Simulador e regras R transferidos por SCP.'
    ;;
  simular)
    quantidade=${2:-1000}
    semente=${3:-$RANDOM}
    [[ "$quantidade" =~ ^[0-9]+$ && "$semente" =~ ^[0-9]+$ ]] || {
      echo 'Quantidade e semente devem ser inteiros positivos.' >&2; exit 1;
    }
    remoto "Rscript /opt/pi-track-field/simulador/gerar_dados.R /opt/pi-track-field/dados $quantidade $semente"
    ;;
  validar)
    remoto 'set -e; hostname; uname -r; cloud-init status; Rscript /opt/pi-track-field/simulador/validar.R /opt/pi-track-field/dados'
    ;;
  demonstrar)
    exec > >(tee "$infra/evidencias/demonstracao-$(date -u +%Y%m%dT%H%M%S)-$$.txt") 2>&1
    date -u
    for etapa in criar configurar transferir simular; do
      echo "===== $etapa ====="
      bash "$infra/p1.sh" "$etapa"
    done
    remoto 'find /opt/pi-track-field/dados -name vendas.csv -type f -exec sha256sum {} \;' > "$P1_RUNTIME/antes.sha256"
    bash "$infra/p1.sh" simular
    remoto 'sha256sum --check' < "$P1_RUNTIME/antes.sha256"
    bash "$infra/p1.sh" validar
    bash "$infra/p1.sh" configurar | tee "$P1_RUNTIME/ansible-segunda.txt"
    grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' "$P1_RUNTIME/ansible-segunda.txt" || {
      echo 'A segunda aplicacao nao confirmou idempotencia.' >&2; exit 1;
    }
    echo 'Concluido: dados preservados e Ansible idempotente (changed=0).'
    ;;
  baixar)
    destino="$infra/evidencias/dados-$(date -u +%Y%m%dT%H%M%S)-$$"
    mkdir "$destino"
    scp "${ssh_opcoes[@]}" -P 2222 -r pi@127.0.0.1:/opt/pi-track-field/dados "$destino/"
    echo "Dados copiados para $destino"
    ;;
  ssh) ssh "${ssh_opcoes[@]}" -t -p 2222 pi@127.0.0.1 ;;
  iniciar) bash "$infra/vm.sh" start; esperar ;;
  parar) bash "$infra/vm.sh" stop ;;
  status) bash "$infra/vm.sh" status ;;
  *) echo 'Uso: bash infraestrutura/p1.sh criar|configurar|transferir|simular|validar|demonstrar|baixar|ssh|iniciar|parar|status' ;;
esac
