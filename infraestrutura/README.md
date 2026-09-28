# P1 — VM Linux, infraestrutura como código e simulador R

Este roteiro implementa as etapas descritas na conversa compartilhada sobre a P1.
O PDF original da disciplina ainda precisa ser conferido antes da submissão,
principalmente se exigir um hipervisor ou provedor específico.

## Arquitetura

```text
Windows
└── Ubuntu WSL (host de administração)
    ├── OpenTofu → QEMU → VM Ubuntu 24.04 (kernel e disco próprios)
    ├── cloud-init → usuário pi e chave SSH
    ├── Ansible → SSH → instalação do R e criação de pastas
    └── SCP → simulador + R/dados.R → Rscript dentro da VM
                                      └── /opt/pi-track-field/dados/exec-*/vendas.csv
```

O WSL hospeda as ferramentas; a VM QEMU é o destino da entrega. Ela usa 2 CPUs,
1,5 GiB de RAM e disco virtual de 12 GiB (alocação sob demanda). O QEMU escolhe
KVM quando disponível; sem `/dev/kvm`, usa emulação TCG, mais lenta.
São necessários Linux x86_64, internet na primeira instalação, cerca de 3 GiB
de RAM disponíveis e espaço para imagem, disco e eventuais arquivos anteriores.
A porta 2222 deve estar livre; ela fica vinculada somente a `127.0.0.1` do host.

O OpenTofu usa `terraform_data`, do provedor embutido, com `local-exec` para
gerenciar o ciclo de criação do QEMU. Não há um provedor nativo de QEMU neste
projeto: o estado do OpenTofu não detecta sozinho desligamentos ou alterações
manuais no disco. O comando `iniciar` e a verificação SSH tratam a inicialização.

## Preparação e demonstração

Execute **no terminal Ubuntu/WSL**, na raiz do projeto:

```bash
cd /mnt/c/Users/lipe/Desktop/PI-Data-Science-Track-Field
bash infraestrutura/preparar-host.sh
bash infraestrutura/p1.sh demonstrar
```

O primeiro comando solicita a senha do sudo para instalar ferramentas no host.
Instala OpenTofu 1.12.6 com verificação SHA-256. A imagem Ubuntu oficial também
tem checksum conferido antes da criação da VM. O download usa a imagem `noble/current`;
o arquivo `SHA256SUMS` local registra a versão efetivamente baixada.

A demonstração cria a VM, aguarda cloud-init, aplica Ansible, transfere o código
por SCP e gera dois lotes de 1.000 vendas. Confere os hashes dos arquivos anteriores,
valida os registros e executa Ansible novamente. A segunda execução deve mostrar
`changed=0`, `unreachable=0` e `failed=0`.

O log fica em `infraestrutura/evidencias/demonstracao-*.txt`. Em TCG, o primeiro
boot e a instalação do R podem levar vários minutos. Veja o boot, em outro terminal:

```bash
tail -f ~/.local/share/pi-track-field-p1/console.log
```

Para explicar cada etapa durante a apresentação, execute separadamente:

```bash
bash infraestrutura/p1.sh criar
bash infraestrutura/p1.sh configurar
bash infraestrutura/p1.sh transferir
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh validar
bash infraestrutura/p1.sh configurar
```

## Acesso, dados e encerramento

```bash
bash infraestrutura/p1.sh ssh       # entra na VM como pi
bash infraestrutura/p1.sh baixar    # copia os CSVs da VM para evidencias/
bash infraestrutura/p1.sh parar     # desligamento seguro, preservando dados
bash infraestrutura/p1.sh iniciar   # retoma a mesma VM e os mesmos dados
bash infraestrutura/p1.sh status
```

Dentro da VM:

```bash
hostname
uname -r
cloud-init status
Rscript /opt/pi-track-field/simulador/gerar_dados.R /opt/pi-track-field/dados 1000 123
find /opt/pi-track-field/dados -name vendas.csv
head -n 4 /opt/pi-track-field/dados/exec-*/vendas.csv
```

Não feche o WSL durante a demonstração. Antes de desligar o Windows, use `parar`.
Chave privada, imagem base, discos e console ficam em
`~/.local/share/pi-track-field-p1/`, com diretório restrito ao usuário.
Não compartilhe essa pasta. Estado e planos do OpenTofu também estão ignorados no Git.

O ciclo de destruição do OpenTofu desliga a VM e preserva seu disco. Recriações
arquivam o disco anterior em `arquivo-*`; não apagam os CSVs. Esses arquivos podem
consumir espaço. Não mova a imagem base enquanto houver discos que dependam dela.
Este comportamento é intencional para proteger os dados acadêmicos.

## Dados e critérios demonstráveis

| Etapa | Arquivo/evidência |
|---|---|
| Provisionamento por OpenTofu | `main.tf`, saída de `tofu plan/apply` no log |
| Inicialização por cloud-init | `cloud-init.yaml.tftpl`, `cloud-init status: done` |
| SSH host → VM | comandos remotos, hostname e kernel da VM |
| Configuração idempotente | `ansible/playbook.yml`, segunda aplicação sem mudanças |
| Transferência por SSH | etapa `transferir`, SCP dos arquivos R |
| Simulador dentro da VM | execução remota do `Rscript` |
| Persistência | dois diretórios `exec-*` e hashes anteriores preservados |
| Registros e esquema | validação de pelo menos 10 linhas por CSV |

Cada CSV tem identificador do pedido, data da venda, cliente, produto, categoria,
canal, região, preço, quantidade, desconto e total. Acrescenta identificador da
execução e instante de geração UTC. A chave entre lotes é `(ID Execucao, ID Pedido)`.
A mesma semente reproduz as vendas; cada execução permanece em uma pasta distinta.
O comando `simular` escolhe uma nova semente; para repetir um cenário, use
`bash infraestrutura/p1.sh simular 1000 42`. A semente fica no `metadados.txt` do lote.
Os dados são sintéticos de 2026 e não representam a empresa real.

O simulador usa apenas R base e compartilha as regras de `R/dados.R` com o painel.
Python é utilizado pelo Ansible e pela administração do host, não para analisar
ou gerar os dados. O painel continua sendo iniciado por `bash painel/iniciar.sh`.

## Entrega e apresentação

Consulte o [relatório da validação executada](../docs/validacao-p1.md) e o
[roteiro de apresentação](../docs/apresentacao-p1.md).

1. Confira o roteiro com o PDF original e com os integrantes do grupo.
2. Execute `demonstrar` e guarde o log final sem erros.
3. Capture a tela do OpenTofu, do SSH, do segundo Ansible e dos CSVs dentro da VM.
4. Use `baixar` para obter uma cópia das saídas que serão anexadas à entrega.
5. Revise o `git diff`, faça commit dos códigos e publique no repositório do grupo.
6. Entregue o endereço do repositório e as evidências exigidas na plataforma da disciplina.

Logs e dados locais não entram automaticamente no Git. Selecione as evidências da
apresentação e confira seu conteúdo antes de anexar. Publicação e submissão são
etapas separadas da preparação local.

Referências: [terraform_data](https://opentofu.org/docs/language/resources/tf-data/),
[QEMU](https://www.qemu.org/docs/master/system/invocation.html),
[imagens oficiais Ubuntu](https://cloud-images.ubuntu.com/noble/current/).
