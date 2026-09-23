#!/usr/bin/env python3
"""Executa a geração quando o painel pede dados novos."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ESTADO = Path(__file__).resolve().parent / "estado"
PEDIDO = ESTADO / "pedido"
STATUS = ESTADO / "status.json"


def gravar(estado: str, mensagem: str) -> None:
    ESTADO.mkdir(parents=True, exist_ok=True)
    STATUS.write_text(
        json.dumps({"estado": estado, "mensagem": mensagem}, ensure_ascii=False),
        encoding="utf-8",
    )


def gerar() -> None:
    subprocess.run(
        [sys.executable, str(RAIZ / "scripts" / "gerar_dados.py")],
        cwd=RAIZ,
        check=True,
    )
    subprocess.run(
        [sys.executable, str(RAIZ / "painel" / "atualizar_resultados.py")],
        cwd=RAIZ,
        check=True,
    )


def main() -> None:
    ESTADO.mkdir(parents=True, exist_ok=True)
    while True:
        if PEDIDO.exists():
            PEDIDO.unlink(missing_ok=True)
            gravar("rodando", "Gerando novas vendas…")
            try:
                gerar()
            except subprocess.CalledProcessError:
                gravar("erro", "Não foi possível gerar os dados. Tente de novo.")
            else:
                gravar("pronto", "Dados gerados. Os gráficos já usam a nova base.")
        time.sleep(0.4)


if __name__ == "__main__":
    main()
