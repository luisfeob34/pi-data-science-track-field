#!/usr/bin/env bash
# Integracao real; requer as dependencias de infraestrutura/bigdata/README.md.
set -euo pipefail
raiz=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$raiz"
modo=${1:-local}
[[ "$modo" == local || "$modo" == hdfs ]] || exit 1
ensaio="ensaio-$(date -u +%Y%m%dT%H%M%S)-$$"
export PI_PIPELINE_ROOT="$raiz/results/bigdata/testes/$modo/$ensaio"
export PI_HDFS_BASE="/pi-track-field-testes/$ensaio"
echo "Evidencias: $PI_PIPELINE_ROOT"
Rscript tests/preparar_bigdata.R
for tentativa in 1 2; do
  echo "Teste $modo: execucao $tentativa"
  bash scripts/pipeline_bigdata.sh results/bigdata/fixtures "$modo"
  Rscript tests/verificar_bigdata.R "$PI_PIPELINE_ROOT"
done
# Falha controlada: deve registrar erro sem trocar a base publicada.
anterior=$(cat "$PI_PIPELINE_ROOT/results/bigdata/ultima.txt")
if bash scripts/pipeline_bigdata.sh "$PI_PIPELINE_ROOT/origem-inexistente" "$modo"; then
  echo 'Uma origem inexistente deveria falhar.'; exit 1
fi
[[ $(cat "$PI_PIPELINE_ROOT/results/bigdata/ultima.txt") == "$anterior" ]]
echo 'OK: resultados equivalentes, reingestao idempotente e publicacao preservada apos falha.'
