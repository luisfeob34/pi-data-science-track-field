#!/usr/bin/env python3
"""Atualiza os resultados do painel a partir das vendas geradas."""

from __future__ import annotations

import csv
from collections import defaultdict
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BRUTO = RAIZ / "data" / "raw" / "vendas_simuladas.csv"
PROCESSADO = RAIZ / "data" / "processed" / "vendas_processadas.csv"
SPARK = RAIZ / "results" / "spark"

MESES = [
    "",
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro",
]


def ler_vendas() -> list[dict[str, str]]:
    with BRUTO.open(encoding="utf-8-sig", newline="") as fonte:
        return list(csv.DictReader(fonte))


def faixa_desconto(valor: float) -> str:
    if valor == 0:
        return "Sem desconto"
    if valor <= 0.05:
        return "Até 5%"
    if valor <= 0.10:
        return "De 6% a 10%"
    return "Acima de 10%"


def enriquecer(vendas: list[dict[str, str]]) -> list[dict[str, str]]:
    linhas = []
    for venda in vendas:
        preco = float(venda["Preço Unitário"])
        quantidade = int(venda["Quantidade"])
        desconto = float(venda["Desconto"])
        total = float(venda["Valor Total"])
        bruto = round(preco * quantidade, 2)
        data = datetime.strptime(venda["Data da Venda"], "%Y-%m-%d")
        linhas.append({
            **venda,
            "Quantidade": str(quantidade),
            "Valor Bruto": f"{bruto:.2f}",
            "Valor Desconto": f"{round(bruto - total, 2):.2f}",
            "Desconto Percentual": f"{round(desconto * 100, 2):.2f}",
            "Valor por Item": f"{round(total / quantidade, 2):.2f}",
            "Faixa de Desconto": faixa_desconto(desconto),
            "Número do Mês": str(data.month),
            "Mês": MESES[data.month],
        })
    return linhas


def agregar(linhas: list[dict[str, str]], chave: str) -> list[dict[str, object]]:
    grupos: dict[str, dict[str, float]] = defaultdict(lambda: {"Pedidos": 0, "Itens": 0, "Faturamento": 0.0})
    for linha in linhas:
        grupo = grupos[linha[chave]]
        grupo["Pedidos"] += 1
        grupo["Itens"] += int(linha["Quantidade"])
        grupo["Faturamento"] += float(linha["Valor Total"])
    saida = []
    for nome, grupo in grupos.items():
        saida.append({
            chave: nome,
            "Pedidos": int(grupo["Pedidos"]),
            "Itens Vendidos": int(grupo["Itens"]),
            "Faturamento": round(grupo["Faturamento"], 2),
        })
    saida.sort(key=lambda item: item["Faturamento"], reverse=True)
    return saida


def gravar(pasta: Path, cabecalho: list[str], linhas: list[dict]) -> None:
    pasta.mkdir(parents=True, exist_ok=True)
    for item in pasta.iterdir():
        if item.is_file():
            item.unlink()
    with (pasta / "part-00000.csv").open("w", encoding="utf-8", newline="") as destino:
        escritor = csv.DictWriter(destino, fieldnames=cabecalho)
        escritor.writeheader()
        for linha in linhas:
            escritor.writerow({coluna: linha[coluna] for coluna in cabecalho})


def gravar_processado(linhas: list[dict[str, str]]) -> None:
    PROCESSADO.parent.mkdir(parents=True, exist_ok=True)
    colunas = [
        "ID Pedido",
        "Data da Venda",
        "Produto",
        "Categoria",
        "Canal de Venda",
        "Região",
        "Preço Unitário",
        "Quantidade",
        "Desconto",
        "Valor Total",
        "Valor Bruto",
        "Valor Desconto",
        "Desconto Percentual",
        "Faixa de Desconto",
        "Valor por Item",
        "Número do Mês",
        "Mês",
    ]
    with PROCESSADO.open("w", encoding="utf-8-sig", newline="") as destino:
        escritor = csv.DictWriter(destino, fieldnames=colunas, extrasaction="ignore")
        escritor.writeheader()
        escritor.writerows(linhas)


def main() -> None:
    vendas = enriquecer(ler_vendas())
    gravar_processado(vendas)

    gravar(
        SPARK / "faturamento_produto",
        ["Produto", "Pedidos", "Itens Vendidos", "Faturamento"],
        agregar(vendas, "Produto"),
    )
    gravar(
        SPARK / "faturamento_categoria",
        ["Categoria", "Pedidos", "Itens Vendidos", "Faturamento"],
        agregar(vendas, "Categoria"),
    )
    gravar(
        SPARK / "faturamento_canal",
        ["Canal de Venda", "Pedidos", "Itens Vendidos", "Faturamento"],
        agregar(vendas, "Canal de Venda"),
    )
    gravar(
        SPARK / "faturamento_regiao",
        ["Região", "Pedidos", "Itens Vendidos", "Faturamento"],
        agregar(vendas, "Região"),
    )

    meses: dict[int, dict[str, float]] = defaultdict(lambda: {"Pedidos": 0, "Itens": 0, "Faturamento": 0.0, "Mês": ""})
    for linha in vendas:
        numero = int(linha["Número do Mês"])
        grupo = meses[numero]
        grupo["Mês"] = linha["Mês"]
        grupo["Pedidos"] += 1
        grupo["Itens"] += int(linha["Quantidade"])
        grupo["Faturamento"] += float(linha["Valor Total"])
    mensal = []
    for numero in sorted(meses):
        grupo = meses[numero]
        mensal.append({
            "Número do Mês": numero,
            "Mês": grupo["Mês"],
            "Pedidos": int(grupo["Pedidos"]),
            "Itens Vendidos": int(grupo["Itens"]),
            "Faturamento": round(grupo["Faturamento"], 2),
        })
    gravar(
        SPARK / "faturamento_mensal",
        ["Número do Mês", "Mês", "Pedidos", "Itens Vendidos", "Faturamento"],
        mensal,
    )

    categorias = agregar(vendas, "Categoria")
    gravar(
        SPARK / "spark_sql_categoria",
        ["Categoria", "Pedidos", "Itens_Vendidos", "Faturamento", "Ticket_Medio"],
        [
            {
                "Categoria": item["Categoria"],
                "Pedidos": item["Pedidos"],
                "Itens_Vendidos": item["Itens Vendidos"],
                "Faturamento": item["Faturamento"],
                "Ticket_Medio": round(item["Faturamento"] / item["Pedidos"], 2) if item["Pedidos"] else 0,
            }
            for item in categorias
        ],
    )
    print(f"Resultados atualizados com {len(vendas)} vendas.")


if __name__ == "__main__":
    main()
