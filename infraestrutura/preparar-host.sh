#!/usr/bin/env bash
# Prepara as ferramentas de virtualização e automação no host Linux.
# Encerra ao detectar comandos com erro, variáveis ausentes ou pipelines com falha.
set -euo pipefail
# Os pacotes e o binário do OpenTofu abaixo são destinados à arquitetura x86_64.
[[ $(uname -m) == x86_64 ]] || { echo 'Este roteiro requer Linux x86_64.' >&2; exit 1; }
# Instala QEMU, utilitários de cloud-init, SSH e Ansible pelo gerenciador APT.
sudo apt-get update
sudo apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils cloud-image-utils curl unzip openssh-client ansible
# Fixa a versão do OpenTofu para tornar a instalação reproduzível.
versao=1.12.6
# Remove os arquivos temporários ao sair, inclusive se ocorrer uma falha.
pasta=$(mktemp -d)
trap 'rm -rf -- "$pasta"' EXIT
arquivo="tofu_${versao}_linux_amd64.zip"
url="https://github.com/opentofu/opentofu/releases/download/v${versao}"
# Baixa o pacote e os hashes publicados para conferir a integridade do arquivo.
curl --fail --location --retry 3 "$url/$arquivo" -o "$pasta/$arquivo"
curl --fail --location --retry 3 "$url/tofu_${versao}_SHA256SUMS" -o "$pasta/SHA256SUMS"
(cd "$pasta"; grep " $arquivo\$" SHA256SUMS | sha256sum --check --strict)
# Extrai apenas o executável, instala para todos os usuários e exibe a versão.
unzip -q "$pasta/$arquivo" tofu -d "$pasta"
sudo install -m 0755 "$pasta/tofu" /usr/local/bin/tofu
tofu version
