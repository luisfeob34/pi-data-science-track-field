#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -m) == x86_64 ]] || { echo 'Este roteiro requer Linux x86_64.' >&2; exit 1; }
sudo apt-get update
sudo apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils cloud-image-utils curl unzip openssh-client ansible
versao=1.12.6
pasta=$(mktemp -d)
trap 'rm -rf -- "$pasta"' EXIT
arquivo="tofu_${versao}_linux_amd64.zip"
url="https://github.com/opentofu/opentofu/releases/download/v${versao}"
curl --fail --location --retry 3 "$url/$arquivo" -o "$pasta/$arquivo"
curl --fail --location --retry 3 "$url/tofu_${versao}_SHA256SUMS" -o "$pasta/SHA256SUMS"
(cd "$pasta"; grep " $arquivo\$" SHA256SUMS | sha256sum --check --strict)
unzip -q "$pasta/$arquivo" tofu -d "$pasta"
sudo install -m 0755 "$pasta/tofu" /usr/local/bin/tofu
tofu version
