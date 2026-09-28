# Validação local da P1 — 28/09/2026

A implementação foi executada no computador do projeto. Este relatório comprova
os testes locais; não substitui a conferência do PDF original nem a submissão
na plataforma da disciplina.

## Resultado

| Verificação | Resultado observado |
|---|---|
| Criação pelo OpenTofu | `Resources: 1 added, 0 changed, 0 destroyed` na primeira criação |
| Reaplicação do OpenTofu | `No changes` na demonstração final |
| Cloud-init | `status: done`; diagnóstico sem erros |
| SSH para o destino | hostname `pi-track-field`, kernel `6.8.0-142-generic` |
| Primeira aplicação do Ansible | `ok=3 changed=2 unreachable=0 failed=0` |
| Transferência SCP | módulos R transferidos para `/opt/pi-track-field` |
| Execução do simulador na VM | dois CSVs, com 1.000 registros cada |
| Identificadores entre lotes | 2.000 identificadores compostos únicos |
| Preservação | SHA-256 do primeiro CSV conferido após gerar o segundo |
| Segunda aplicação do Ansible | `ok=3 changed=0 unreachable=0 failed=0` |
| Cópia para o host | comando `baixar` executado com sucesso |
| Desligamento seguro | VM desligada ao final, com disco e dados preservados |
| Validação do código | testes R, ShellCheck, sintaxe Bash, OpenTofu validate/fmt e diff sem erros |

O [log completo da demonstração final](evidencias-p1.txt) contém os resultados.
A primeira criação e a configuração inicial do cloud-init ocorreram antes dessa
demonstração; por isso o log final mostra o OpenTofu sem alterações. A primeira
tentativa foi interrompida durante a atualização dos scripts; a execução final
com os scripts estabilizados terminou com código zero.

## Ambiente e lotes gerados

- Host: Ubuntu no WSL2, sobre Windows; QEMU 10.2.1 em emulação TCG.
- VM: Ubuntu 24.04.5 LTS, 2 CPUs virtuais, 1.536 MiB de RAM, disco virtual de 12 GiB.
- Infraestrutura: OpenTofu 1.12.6, `terraform_data` e provisionador `local-exec`.
- Simulador na VM: R 4.3.3, usando apenas R base.
- Lote `exec-20260928T155323-d533c5857cb`: 1.000 registros, semente 25086.
- Lote `exec-20260928T155332-dbf41239e0f`: 1.000 registros, semente 29404.

Os CSVs originais permanecem no disco da VM em `/opt/pi-track-field/dados/`.
A VM foi deixada desligada. Retome com `bash infraestrutura/p1.sh iniciar`.
A cópia local está em
`infraestrutura/evidencias/dados-20260928T155354-2993/dados/`.
Os arquivos de dados e os logs locais completos estão ignorados no Git; o log
selecionado neste documento pode ser versionado junto ao relatório.

O primeiro boot levou aproximadamente cinco minutos. A primeira configuração
com Ansible também demorou vários minutos por causa da emulação, especialmente
na atualização dos índices do Ubuntu. Prepare a VM antes da apresentação.

## O que ainda depende da entrega acadêmica

1. Conferir as exigências com o PDF original, inclusive aceitação do QEMU e do
   provisionamento via `local-exec` caso a disciplina determine outro provedor.
2. Adicionar a identificação dos integrantes e as capturas de tela exigidas.
3. Revisar e publicar as alterações no repositório do grupo.
4. Submeter o endereço do repositório e os anexos na plataforma da disciplina.

Use o [roteiro de apresentação](apresentacao-p1.md) e o
[guia de execução](../infraestrutura/README.md). O painel de análise em R permanece
disponível pelo comando `bash painel/iniciar.sh`.
