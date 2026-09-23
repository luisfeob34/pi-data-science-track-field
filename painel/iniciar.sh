#!/bin/bash
cd "$(dirname "$0")"
PORTA="${1:-8080}"
RAIZ_PROJETO="$(cd .. && pwd)"

python3 "$(dirname "$0")/observar_geracao.py" >/tmp/pi-gerar.log 2>&1 &

if command -v php >/dev/null 2>&1; then
  echo "Painel em http://127.0.0.1:${PORTA}"
  exec php -S "127.0.0.1:${PORTA}" -t public
fi

if [[ -x bin/php ]]; then
  echo "Painel em http://127.0.0.1:${PORTA}"
  exec bin/php -S "127.0.0.1:${PORTA}" -t public
fi

if command -v podman >/dev/null 2>&1; then
  echo "Painel em http://127.0.0.1:${PORTA}"
  exec podman run --rm --name pi-painel \
    -p "127.0.0.1:${PORTA}:8080" \
    -v "${RAIZ_PROJETO}:/app:z" \
    -w /app/painel/public \
    docker.io/library/php:8.3-cli \
    php -S 0.0.0.0:8080
fi

echo "Não encontrei o PHP. Instale o pacote php-cli e rode este script de novo."
exit 1
