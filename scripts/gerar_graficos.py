from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ARQUIVO = "data/processed/vendas_processadas.csv"
PASTA_GRAFICOS = Path("results/graficos")


def salvar_grafico(nome):
    caminho = PASTA_GRAFICOS / nome

    plt.tight_layout()
    plt.savefig(
        caminho,
        dpi=300,
        bbox_inches="tight",
    )
    plt.close()

    print(f"Gerado: {caminho}")


def grafico_faturamento_produto(df):
    dados = (
        df.groupby("Produto")["Valor Total"]
        .sum()
        .sort_values()
    )

    plt.figure(figsize=(10, 6))
    dados.plot(kind="barh")

    plt.title("Faturamento por Produto")
    plt.xlabel("Faturamento (R$)")
    plt.ylabel("Produto")

    salvar_grafico(
        "01_faturamento_produto.png"
    )


def grafico_faturamento_categoria(df):
    dados = (
        df.groupby("Categoria")["Valor Total"]
        .sum()
        .sort_values(ascending=False)
    )

    plt.figure(figsize=(8, 5))
    dados.plot(kind="bar")

    plt.title("Faturamento por Categoria")
    plt.xlabel("Categoria")
    plt.ylabel("Faturamento (R$)")
    plt.xticks(rotation=0)

    salvar_grafico(
        "02_faturamento_categoria.png"
    )


def grafico_faturamento_canal(df):
    dados = (
        df.groupby("Canal de Venda")["Valor Total"]
        .sum()
        .sort_values(ascending=False)
    )

    plt.figure(figsize=(8, 5))
    dados.plot(kind="bar")

    plt.title("Faturamento por Canal de Venda")
    plt.xlabel("Canal de Venda")
    plt.ylabel("Faturamento (R$)")
    plt.xticks(rotation=0)

    salvar_grafico(
        "03_faturamento_canal.png"
    )


def grafico_faturamento_regiao(df):
    dados = (
        df.groupby("Região")["Valor Total"]
        .sum()
        .sort_values(ascending=False)
    )

    plt.figure(figsize=(9, 5))
    dados.plot(kind="bar")

    plt.title("Faturamento por Região")
    plt.xlabel("Região")
    plt.ylabel("Faturamento (R$)")
    plt.xticks(rotation=0)

    salvar_grafico(
        "04_faturamento_regiao.png"
    )


def grafico_faturamento_mensal(df):
    dados = (
        df.groupby(
            ["Número do Mês", "Mês"]
        )["Valor Total"]
        .sum()
        .reset_index()
        .sort_values("Número do Mês")
    )

    plt.figure(figsize=(11, 6))

    plt.plot(
        dados["Mês"],
        dados["Valor Total"],
        marker="o",
    )

    plt.title("Evolução Mensal do Faturamento")
    plt.xlabel("Mês")
    plt.ylabel("Faturamento (R$)")
    plt.xticks(rotation=45)

    salvar_grafico(
        "05_faturamento_mensal.png"
    )


def grafico_distribuicao_valor(df):
    plt.figure(figsize=(9, 5))

    plt.hist(
        df["Valor Total"],
        bins=20,
        edgecolor="black",
    )

    plt.title("Distribuição do Valor dos Pedidos")
    plt.xlabel("Valor do Pedido (R$)")
    plt.ylabel("Frequência")

    salvar_grafico(
        "06_distribuicao_valor_pedidos.png"
    )


def grafico_faixa_desconto(df):
    ordem = [
        "Sem desconto",
        "Até 5%",
        "De 6% a 10%",
        "Acima de 10%",
    ]

    dados = (
        df["Faixa de Desconto"]
        .value_counts()
        .reindex(ordem)
        .fillna(0)
    )

    plt.figure(figsize=(8, 5))
    dados.plot(kind="bar")

    plt.title("Quantidade de Pedidos por Faixa de Desconto")
    plt.xlabel("Faixa de Desconto")
    plt.ylabel("Quantidade de Pedidos")
    plt.xticks(rotation=0)

    salvar_grafico(
        "07_pedidos_faixa_desconto.png"
    )


def grafico_quantidade_valor(df):
    plt.figure(figsize=(8, 6))

    plt.scatter(
        df["Quantidade"],
        df["Valor Total"],
        alpha=0.5,
    )

    plt.title(
        "Relação entre Quantidade e Valor do Pedido"
    )
    plt.xlabel("Quantidade de Itens")
    plt.ylabel("Valor Total (R$)")

    salvar_grafico(
        "08_quantidade_valor_total.png"
    )


def grafico_boxplot_valor(df):
    plt.figure(figsize=(8, 5))

    plt.boxplot(
        df["Valor Total"],
        orientation="horizontal",
)

    plt.title(
        "Distribuição e Valores Atípicos dos Pedidos"
    )
    plt.xlabel("Valor Total (R$)")

    salvar_grafico(
        "09_boxplot_valor_total.png"
    )


def grafico_correlacoes(df):
    colunas = [
        "Preço Unitário",
        "Quantidade",
        "Desconto Percentual",
        "Valor Bruto",
        "Valor Desconto",
        "Valor Total",
        "Valor por Item",
    ]

    correlacoes = df[colunas].corr()

    fig, ax = plt.subplots(figsize=(10, 8))

    imagem = ax.imshow(
        correlacoes,
        vmin=-1,
        vmax=1,
    )

    ax.set_xticks(
        range(len(colunas))
    )

    ax.set_yticks(
        range(len(colunas))
    )

    ax.set_xticklabels(
        colunas,
        rotation=45,
        ha="right",
    )

    ax.set_yticklabels(
        colunas
    )

    for i in range(len(colunas)):
        for j in range(len(colunas)):
            ax.text(
                j,
                i,
                f"{correlacoes.iloc[i, j]:.2f}",
                ha="center",
                va="center",
            )

    plt.colorbar(
        imagem,
        ax=ax,
        label="Correlação",
    )

    plt.title(
        "Matriz de Correlação das Variáveis Numéricas"
    )

    salvar_grafico(
        "10_matriz_correlacao.png"
    )


def main():
    print("=" * 60)
    print("GERAÇÃO DE GRÁFICOS")
    print("=" * 60)

    PASTA_GRAFICOS.mkdir(
        parents=True,
        exist_ok=True,
    )

    df = pd.read_csv(ARQUIVO)

    grafico_faturamento_produto(df)
    grafico_faturamento_categoria(df)
    grafico_faturamento_canal(df)
    grafico_faturamento_regiao(df)
    grafico_faturamento_mensal(df)
    grafico_distribuicao_valor(df)
    grafico_faixa_desconto(df)
    grafico_quantidade_valor(df)
    grafico_boxplot_valor(df)
    grafico_correlacoes(df)

    print("\n" + "=" * 60)
    print("GRÁFICOS GERADOS COM SUCESSO")
    print(f"Quantidade de gráficos: 10")
    print(f"Pasta: {PASTA_GRAFICOS}")
    print("=" * 60)


if __name__ == "__main__":
    main()