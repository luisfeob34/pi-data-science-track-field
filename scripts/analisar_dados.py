import pandas as pd


ARQUIVO = "data/processed/vendas_processadas.csv"


def titulo(texto):
    print("\n" + "=" * 70)
    print(texto)
    print("=" * 70)


def main():
    # ---------------------------------------------------------
    # 1. Carregar os dados processados
    # ---------------------------------------------------------
    df = pd.read_csv(ARQUIVO)

    df["Data da Venda"] = pd.to_datetime(
        df["Data da Venda"],
        errors="coerce",
    )

    titulo("ANÁLISE EXPLORATÓRIA DOS DADOS")

    # ---------------------------------------------------------
    # 2. Dimensões da base
    # ---------------------------------------------------------
    print("\n1. DIMENSÕES DA BASE")
    print(f"Quantidade de registros: {df.shape[0]}")
    print(f"Quantidade de colunas: {df.shape[1]}")

    # ---------------------------------------------------------
    # 3. Colunas
    # ---------------------------------------------------------
    print("\n2. COLUNAS")

    for coluna in df.columns:
        print(f"- {coluna}")

    # ---------------------------------------------------------
    # 4. Tipos dos dados
    # ---------------------------------------------------------
    print("\n3. TIPOS DE DADOS")
    print(df.dtypes)

    # ---------------------------------------------------------
    # 5. Qualidade dos dados
    # ---------------------------------------------------------
    print("\n4. QUALIDADE DOS DADOS")

    print(
        f"Valores ausentes: "
        f"{df.isnull().sum().sum()}"
    )

    print(
        f"Registros duplicados: "
        f"{df.duplicated().sum()}"
    )

    # ---------------------------------------------------------
    # 6. Estatísticas descritivas
    # ---------------------------------------------------------
    print("\n5. ESTATÍSTICAS DESCRITIVAS")

    colunas_estatisticas = [
        "Preço Unitário",
        "Quantidade",
        "Desconto Percentual",
        "Valor Bruto",
        "Valor Desconto",
        "Valor Total",
        "Valor por Item",
    ]

    print(
        df[colunas_estatisticas]
        .describe()
        .round(2)
    )

    # ---------------------------------------------------------
    # 7. Indicadores gerais
    # ---------------------------------------------------------
    print("\n6. INDICADORES GERAIS")

    faturamento_total = df["Valor Total"].sum()

    faturamento_bruto = df["Valor Bruto"].sum()

    descontos_concedidos = df["Valor Desconto"].sum()

    quantidade_itens = df["Quantidade"].sum()

    ticket_medio = df["Valor Total"].mean()

    valor_medio_item = (
        df["Valor Total"].sum()
        / df["Quantidade"].sum()
    )

    print(
        f"Faturamento bruto: "
        f"R$ {faturamento_bruto:,.2f}"
    )

    print(
        f"Descontos concedidos: "
        f"R$ {descontos_concedidos:,.2f}"
    )

    print(
        f"Faturamento líquido: "
        f"R$ {faturamento_total:,.2f}"
    )

    print(
        f"Quantidade de itens vendidos: "
        f"{quantidade_itens}"
    )

    print(
        f"Ticket médio por pedido: "
        f"R$ {ticket_medio:,.2f}"
    )

    print(
        f"Valor médio por item vendido: "
        f"R$ {valor_medio_item:,.2f}"
    )

    # ---------------------------------------------------------
    # 8. Análise por produto
    # ---------------------------------------------------------
    print("\n7. ANÁLISE POR PRODUTO")

    produtos = (
        df.groupby("Produto")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(produtos.round(2))

    # ---------------------------------------------------------
    # 9. Análise por categoria
    # ---------------------------------------------------------
    print("\n8. ANÁLISE POR CATEGORIA")

    categorias = (
        df.groupby("Categoria")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(categorias.round(2))

    # ---------------------------------------------------------
    # 10. Análise por canal
    # ---------------------------------------------------------
    print("\n9. ANÁLISE POR CANAL DE VENDA")

    canais = (
        df.groupby("Canal de Venda")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(canais.round(2))

    # ---------------------------------------------------------
    # 11. Análise por região
    # ---------------------------------------------------------
    print("\n10. ANÁLISE POR REGIÃO")

    regioes = (
        df.groupby("Região")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(regioes.round(2))

    # ---------------------------------------------------------
    # 12. Análise de descontos
    # ---------------------------------------------------------
    print("\n11. ANÁLISE DE DESCONTOS")

    descontos = (
        df.groupby("Faixa de Desconto")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Faturamento=("Valor Total", "sum"),
            Desconto_Concedido=(
                "Valor Desconto",
                "sum",
            ),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(descontos.round(2))

    # ---------------------------------------------------------
    # 13. Análise mensal
    # ---------------------------------------------------------
    print("\n12. ANÁLISE MENSAL")

    mensal = (
        df.groupby(
            ["Número do Mês", "Mês"]
        )
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .reset_index()
        .sort_values("Número do Mês")
    )

    print(
        mensal[
            [
                "Mês",
                "Pedidos",
                "Itens_Vendidos",
                "Faturamento",
            ]
        ].round(2).to_string(index=False)
    )

    # ---------------------------------------------------------
    # 14. Análise trimestral
    # ---------------------------------------------------------
    print("\n13. ANÁLISE TRIMESTRAL")

    trimestral = (
        df.groupby("Trimestre")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Itens_Vendidos=("Quantidade", "sum"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_index()
    )

    print(trimestral.round(2))

    # ---------------------------------------------------------
    # 15. Análise por dia da semana
    # ---------------------------------------------------------
    print("\n14. ANÁLISE POR DIA DA SEMANA")

    dias = (
        df.groupby("Dia da Semana")
        .agg(
            Pedidos=("ID Pedido", "count"),
            Faturamento=("Valor Total", "sum"),
        )
        .sort_values(
            "Faturamento",
            ascending=False,
        )
    )

    print(dias.round(2))

    # ---------------------------------------------------------
    # 16. Porte dos pedidos
    # ---------------------------------------------------------
    print("\n15. PORTE DOS PEDIDOS")

    print(
        df["Porte do Pedido"]
        .value_counts()
    )

    # ---------------------------------------------------------
    # 17. Faixas de valor
    # ---------------------------------------------------------
    print("\n16. FAIXAS DE VALOR DOS PEDIDOS")

    print(
        df["Faixa de Valor"]
        .value_counts()
    )

    # ---------------------------------------------------------
    # 18. Relações entre variáveis numéricas
    # ---------------------------------------------------------
    print("\n17. CORRELAÇÕES")

    colunas_correlacao = [
        "Preço Unitário",
        "Quantidade",
        "Desconto Percentual",
        "Valor Bruto",
        "Valor Desconto",
        "Valor Total",
        "Valor por Item",
    ]

    correlacoes = (
        df[colunas_correlacao]
        .corr()
        .round(2)
    )

    print(correlacoes)

    # ---------------------------------------------------------
    # 19. Identificação de valores atípicos
    #     Método IQR aplicado ao Valor Total
    # ---------------------------------------------------------
    print("\n18. VALORES ATÍPICOS - VALOR TOTAL")

    q1 = df["Valor Total"].quantile(0.25)
    q3 = df["Valor Total"].quantile(0.75)

    iqr = q3 - q1

    limite_inferior = q1 - (1.5 * iqr)
    limite_superior = q3 + (1.5 * iqr)

    outliers = df[
        (df["Valor Total"] < limite_inferior)
        | (df["Valor Total"] > limite_superior)
    ]

    print(f"Q1: R$ {q1:.2f}")
    print(f"Q3: R$ {q3:.2f}")
    print(f"IQR: R$ {iqr:.2f}")

    print(
        f"Limite inferior: "
        f"R$ {limite_inferior:.2f}"
    )

    print(
        f"Limite superior: "
        f"R$ {limite_superior:.2f}"
    )

    print(
        f"Quantidade de possíveis valores atípicos: "
        f"{len(outliers)}"
    )

    # ---------------------------------------------------------
    # 20. Período analisado
    # ---------------------------------------------------------
    print("\n19. PERÍODO ANALISADO")

    print(
        "Primeira venda: "
        f"{df['Data da Venda'].min().date()}"
    )

    print(
        "Última venda: "
        f"{df['Data da Venda'].max().date()}"
    )

    titulo("ANÁLISE EXPLORATÓRIA CONCLUÍDA")


if __name__ == "__main__":
    main()