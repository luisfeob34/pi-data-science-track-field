#!/bin/bash
set -euo pipefail
RAIZ_PROJETO="$(cd "$(dirname "$0")/.." && pwd)"
command -v Rscript >/dev/null 2>&1 || { echo "Instale o R e as dependências conforme o README."; exit 1; }
exec Rscript "$RAIZ_PROJETO/scripts/iniciar_painel.R" "${1:-8080}"
