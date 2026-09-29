#!/usr/bin/env bash
set -euo pipefail
raiz=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=infraestrutura/bigdata/ambiente.sh
source "$raiz/infraestrutura/bigdata/ambiente.sh"
export PI_PIPELINE_ROOT="${PI_PIPELINE_ROOT:-$raiz}"
mkdir -p "$PI_PIPELINE_ROOT"
PI_PIPELINE_ROOT=$(cd "$PI_PIPELINE_ROOT" && pwd)
saida=$PI_PIPELINE_ROOT
hdfs_base=${PI_HDFS_BASE:-/pi-track-field}
[[ "$hdfs_base" =~ ^/[a-zA-Z0-9/_-]+$ ]] || { echo 'PI_HDFS_BASE invalido'; exit 1; }
[[ $# -ge 1 && $# -le 2 ]] || { echo 'Uso: pipeline_bigdata.sh pasta_dos_lotes [local|hdfs]'; exit 1; }
modo=${2:-local}
[[ "$modo" == local || "$modo" == hdfs ]] || exit 1
[[ -x "$SPARK_HOME/bin/spark-submit" ]] || { echo 'Execute infraestrutura/bigdata/instalar.sh'; exit 1; }
mkdir -p "$saida/results/monitoramento" "$saida/results/bigdata" "$saida/data/lake"
exec 9>"$saida/data/lake/pipeline.lock"
flock -n 9 || { echo 'Ja existe um pipeline em execucao.'; exit 1; }
id="exec-$(date -u +%Y%m%dT%H%M%S)-$$"
inicio=$(date +%s)
etapa=ingestao
log="$saida/results/monitoramento/$id.log"
exec > >(tee "$log") 2>&1
registrar() {
  codigo=$?
  trap - EXIT
  local estado=sucesso
  [[ $codigo == 0 ]] || estado=falha
  printf 'Execucao,Estado,Etapa,Codigo,Duracao_segundos,Modo\n%s,%s,%s,%s,%s,%s\n' \
    "$id" "$estado" "$etapa" "$codigo" "$(( $(date +%s) - inicio ))" "$modo" > "$saida/results/monitoramento/$id.csv"
  exit "$codigo"
}
trap registrar EXIT
Rscript "$raiz/scripts/ingerir_lotes.R" "$1" "$saida/data/lake"
bronze="file://$saida/data/lake/bronze"
lake="file://$saida/data/lake"
if [[ "$modo" == hdfs ]]; then
  etapa=hdfs
  # Daemons persistem apos o pipeline e nao podem herdar seu bloqueio.
  bash "$raiz/infraestrutura/bigdata/hdfs.sh" iniciar 9>&-
  hdfs dfs -mkdir -p "$hdfs_base/bronze"
  for pasta in "$saida"/data/lake/bronze/*; do
    [[ -f "$pasta/CONCLUIDO" ]] || continue
    nome=$(basename "$pasta")
    if ! hdfs dfs -test -e "$hdfs_base/bronze/$nome/CONCLUIDO"; then
      # Upload para nome temporario e rename evitam lotes parciais visiveis.
      destino="$hdfs_base/.upload-$id-$nome"
      hdfs dfs -put "$pasta" "$destino"
      hdfs dfs -mv "$destino" "$hdfs_base/bronze/$nome"
    fi
  done
  bronze="hdfs://127.0.0.1:19000$hdfs_base/bronze"
  lake="hdfs://127.0.0.1:19000$hdfs_base"
fi
etapa=spark
Rscript "$raiz/spark/processar.R" "$bronze" "$lake" "$saida/results/bigdata/$id"
etapa=analise_r
Rscript "$raiz/scripts/publicar_spark.R" "$id"
etapa=concluido
echo "Pipeline concluido: $id"
