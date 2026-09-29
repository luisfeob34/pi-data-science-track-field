#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=infraestrutura/bigdata/ambiente.sh
source "$(dirname "${BASH_SOURCE[0]}")/ambiente.sh"
[[ -x "$JAVA_HOME/bin/java" ]] || { echo 'Instale: sudo apt install openjdk-17-jdk-headless r-base-core curl'; exit 1; }
command -v Rscript >/dev/null
mkdir -p "$PI_BIGDATA_HOME/downloads"
baixar() {
  local caminho=$1 nome=$2
  [[ -d "$PI_BIGDATA_HOME/$nome" ]] && return
  local destino="$PI_BIGDATA_HOME/downloads/$nome.tar.gz"
  local base=https://dlcdn.apache.org
  if ! curl -fsIL --max-time 20 "$base/$caminho" >/dev/null; then base=https://archive.apache.org/dist; fi
  curl -fL --retry 3 "$base/$caminho" -o "$destino"
  curl -fL --retry 3 "$base/$caminho.sha512" -o "$destino.sha512"
  # Apache publica tanto digests puros como linhas com nome do arquivo.
  local esperado atual
  esperado=$(grep -Eo '[A-Fa-f0-9]{128}' "$destino.sha512" | head -n 1 | tr '[:upper:]' '[:lower:]')
  atual=$(sha512sum "$destino" | cut -d ' ' -f 1)
  [[ -n "$esperado" && "$esperado" == "$atual" ]] || { echo "Checksum invalido: $nome"; exit 1; }
  local temporario
  temporario=$(mktemp -d "$PI_BIGDATA_HOME/.extracao-XXXXXX")
  tar -xzf "$destino" -C "$temporario"
  mv "$temporario/$nome" "$PI_BIGDATA_HOME/$nome"
  rmdir "$temporario"
}
baixar spark/spark-3.5.8/spark-3.5.8-bin-hadoop3.tgz spark-3.5.8-bin-hadoop3
baixar hadoop/common/hadoop-3.4.2/hadoop-3.4.2.tar.gz hadoop-3.4.2
echo 'SparkR e Hadoop instalados. Execute bash infraestrutura/bigdata/hdfs.sh iniciar.'
