#!/usr/bin/env bash
# Instala as distribuições locais de Spark e Hadoop com verificação de integridade.
set -euo pipefail
# shellcheck source=infraestrutura/bigdata/ambiente.sh
source "$(dirname "${BASH_SOURCE[0]}")/ambiente.sh"
# Confere Java e R antes de iniciar os downloads.
[[ -x "$JAVA_HOME/bin/java" ]] || { echo 'Instale: sudo apt install openjdk-17-jdk-headless r-base-core curl'; exit 1; }
command -v Rscript >/dev/null
mkdir -p "$PI_BIGDATA_HOME/downloads"
baixar() {
  # Recebe o caminho no servidor Apache e o nome da pasta extraída.
  local caminho=$1 nome=$2
  # Evita baixar novamente uma distribuição cuja pasta já existe.
  [[ -d "$PI_BIGDATA_HOME/$nome" ]] && return
  local destino="$PI_BIGDATA_HOME/downloads/$nome.tar.gz"
  local base=https://dlcdn.apache.org
  # Recorre ao arquivo histórico se a versão não estiver disponível no CDN.
  if ! curl -fsIL --max-time 20 "$base/$caminho" >/dev/null; then base=https://archive.apache.org/dist; fi
  curl -fL --retry 3 "$base/$caminho" -o "$destino"
  curl -fL --retry 3 "$base/$caminho.sha512" -o "$destino.sha512"
  # Apache publica tanto digests puros como linhas com nome do arquivo.
  local esperado atual
  esperado=$(grep -Eo '[A-Fa-f0-9]{128}' "$destino.sha512" | head -n 1 | tr '[:upper:]' '[:lower:]')
  atual=$(sha512sum "$destino" | cut -d ' ' -f 1)
  [[ -n "$esperado" && "$esperado" == "$atual" ]] || { echo "Checksum invalido: $nome"; exit 1; }
  # Só extrai após conferir o SHA-512; move a pasta pronta para o destino final.
  local temporario
  temporario=$(mktemp -d "$PI_BIGDATA_HOME/.extracao-XXXXXX")
  tar -xzf "$destino" -C "$temporario"
  mv "$temporario/$nome" "$PI_BIGDATA_HOME/$nome"
  rmdir "$temporario"
}
# Mantém as versões alinhadas com os caminhos exportados em ambiente.sh.
baixar spark/spark-3.5.8/spark-3.5.8-bin-hadoop3.tgz spark-3.5.8-bin-hadoop3
baixar hadoop/common/hadoop-3.4.2/hadoop-3.4.2.tar.gz hadoop-3.4.2
echo 'SparkR e Hadoop instalados. Execute bash infraestrutura/bigdata/hdfs.sh iniciar.'
