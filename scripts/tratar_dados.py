import os

import pandas as pd


ARQUIVO_ENTRADA = "data/raw/vendas_simuladas.csv"
ARQUIVO_SAIDA = "data/processed/vendas_processadas.csv"


def main():
    print("=" * 60)
    print("TRATAMENTO DOS DADOS")
    print("=" * 60)

    # ---------------------------------------------------------
    # 1. Carregar os dados brutos
    # ---------------------------------------------------------
    df = pd.read_csv(ARQUIVO_ENTRADA)

    quantidade_inicial = len(df)

    print(f"\nRegistros recebidos: {quantidade_inicial}")

    # ---------------------------------------------------------
    # 2. Remover registros duplicados
    # ---------------------------------------------------------
    duplicados = df.duplicated().sum()

    df = df.drop_duplicates()

    print(f"Registros duplicados encontrados: {duplicados}")

    # ---------------------------------------------------------
    # 3. Verificar valores ausentes
    # ---------------------------------------------------------
    total_ausentes = df.isnull().sum().sum()

    print(f"Valores ausentes encontrados: {total_ausentes}")

    if total_ausentes > 0:
        df = df.dropna()

    # ---------------------------------------------------------
    # 4. Padronizar colunas de texto
    # ---------------------------------------------------------
    colunas_texto = [
        "Cliente",
        "Produto",
        "Categoria",
        "Canal de Venda",
        "Região",
    ]

    for coluna in colunas_texto:
        df[coluna] = df[coluna].str.strip()

    # ---------------------------------------------------------
    # 5. Converter e validar a Data da Venda
    # ---------------------------------------------------------
    df["Data da Venda"] = pd.to_datetime(
        df["Data da Venda"],
        errors="coerce",
    )

    datas_invalidas = df["Data da Venda"].isnull().sum()

    if datas_invalidas > 0:
        df = df.dropna(subset=["Data da Venda"])

    print(
        "Registros com datas inválidas: "
        f"{datas_invalidas}"
    )

    # ---------------------------------------------------------
    # 6. Garantir os tipos das colunas numéricas
    # ---------------------------------------------------------
    colunas_numericas = [
        "Preço Unitário",
        "Quantidade",
        "Desconto",
        "Valor Total",
    ]

    for coluna in colunas_numericas:
        df[coluna] = pd.to_numeric(
            df[coluna],
            errors="coerce",
        )

    invalidos_numericos = (
        df[colunas_numericas]
        .isnull()
        .any(axis=1)
        .sum()
    )

    if invalidos_numericos > 0:
        df = df.dropna(subset=colunas_numericas)

    print(
        "Registros com valores numéricos inválidos: "
        f"{invalidos_numericos}"
    )

    # ---------------------------------------------------------
    # 7. Validar valores impossíveis
    # ---------------------------------------------------------
    registros_invalidos = (
        (df["Preço Unitário"] <= 0)
        | (df["Quantidade"] <= 0)
        | (df["Desconto"] < 0)
        | (df["Desconto"] > 1)
    )

    quantidade_invalidos = registros_invalidos.sum()

    df = df[~registros_invalidos].copy()

    print(
        "Registros com valores fora dos limites esperados: "
        f"{quantidade_invalidos}"
    )

    # ---------------------------------------------------------
    # 8. Criar Valor Bruto
    # ---------------------------------------------------------
    df["Valor Bruto"] = (
        df["Preço Unitário"]
        * df["Quantidade"]
    ).round(2)

    # ---------------------------------------------------------
    # 9. Criar Valor Desconto
    # ---------------------------------------------------------
    df["Valor Desconto"] = (
        df["Valor Bruto"]
        * df["Desconto"]
    ).round(2)

    # ---------------------------------------------------------
    # 10. Recalcular Valor Total
    # ---------------------------------------------------------
    df["Valor Total"] = (
        df["Valor Bruto"]
        - df["Valor Desconto"]
    ).round(2)

    # ---------------------------------------------------------
    # 11. Identificar pedidos com desconto
    # ---------------------------------------------------------
    df["Possui Desconto"] = df["Desconto"].apply(
        lambda valor: "Sim" if valor > 0 else "Não"
    )

    # ---------------------------------------------------------
    # 12. Criar percentual de desconto
    # ---------------------------------------------------------
    df["Desconto Percentual"] = (
        df["Desconto"] * 100
    ).round(2)

    # ---------------------------------------------------------
    # 13. Criar faixa de desconto
    # ---------------------------------------------------------
    def classificar_desconto(valor):
        if valor == 0:
            return "Sem desconto"
        elif valor <= 0.05:
            return "Até 5%"
        elif valor <= 0.10:
            return "De 6% a 10%"
        else:
            return "Acima de 10%"

    df["Faixa de Desconto"] = df["Desconto"].apply(
        classificar_desconto
    )

    # ---------------------------------------------------------
    # 14. Calcular valor efetivamente pago por item
    # ---------------------------------------------------------
    df["Valor por Item"] = (
        df["Valor Total"]
        / df["Quantidade"]
    ).round(2)

    # ---------------------------------------------------------
    # 15. Classificar o porte do pedido
    # ---------------------------------------------------------
    def classificar_quantidade(quantidade):
        if quantidade == 1:
            return "Unitário"
        elif quantidade <= 3:
            return "Pequeno"
        else:
            return "Grande"

    df["Porte do Pedido"] = df["Quantidade"].apply(
        classificar_quantidade
    )

    # ---------------------------------------------------------
    # 16. Criar faixa de valor do pedido
    # ---------------------------------------------------------
    def classificar_valor(valor):
        if valor < 250:
            return "Até R$ 249,99"
        elif valor < 500:
            return "R$ 250 a R$ 499,99"
        elif valor < 1000:
            return "R$ 500 a R$ 999,99"
        else:
            return "R$ 1.000 ou mais"

    df["Faixa de Valor"] = df["Valor Total"].apply(
        classificar_valor
    )

    # ---------------------------------------------------------
    # 17. Criar variáveis temporais
    # ---------------------------------------------------------
    df["Ano"] = df["Data da Venda"].dt.year

    df["Número do Mês"] = df["Data da Venda"].dt.month

    meses = {
        1: "Janeiro",
        2: "Fevereiro",
        3: "Março",
        4: "Abril",
        5: "Maio",
        6: "Junho",
        7: "Julho",
        8: "Agosto",
        9: "Setembro",
        10: "Outubro",
        11: "Novembro",
        12: "Dezembro",
    }

    df["Mês"] = df["Número do Mês"].map(meses)

    df["Trimestre"] = (
        "T"
        + df["Data da Venda"]
        .dt.quarter
        .astype(str)
    )

    dias_semana = {
        0: "Segunda-feira",
        1: "Terça-feira",
        2: "Quarta-feira",
        3: "Quinta-feira",
        4: "Sexta-feira",
        5: "Sábado",
        6: "Domingo",
    }

    df["Dia da Semana"] = (
        df["Data da Venda"]
        .dt.dayofweek
        .map(dias_semana)
    )

    # ---------------------------------------------------------
    # 18. Ordenar os registros pela data
    # ---------------------------------------------------------
    df = df.sort_values(
        by=["Data da Venda", "ID Pedido"]
    )

    # ---------------------------------------------------------
    # 19. Formatar a data para gravação no CSV
    # ---------------------------------------------------------
    df["Data da Venda"] = (
        df["Data da Venda"]
        .dt.strftime("%Y-%m-%d")
    )

    # ---------------------------------------------------------
    # 20. Criar pasta de saída
    # ---------------------------------------------------------
    os.makedirs(
        os.path.dirname(ARQUIVO_SAIDA),
        exist_ok=True,
    )

    # ---------------------------------------------------------
    # 21. Salvar os dados processados
    # ---------------------------------------------------------
    df.to_csv(
        ARQUIVO_SAIDA,
        index=False,
        encoding="utf-8-sig",
    )

    # ---------------------------------------------------------
    # 22. Resumo do processamento
    # ---------------------------------------------------------
    print(f"\nRegistros iniciais: {quantidade_inicial}")
    print(f"Registros finais: {len(df)}")

    print(f"\nArquivo gerado: {ARQUIVO_SAIDA}")

    print("\nVariáveis derivadas criadas:")
    print("- Valor Bruto")
    print("- Valor Desconto")
    print("- Possui Desconto")
    print("- Desconto Percentual")
    print("- Faixa de Desconto")
    print("- Valor por Item")
    print("- Porte do Pedido")
    print("- Faixa de Valor")
    print("- Ano")
    print("- Número do Mês")
    print("- Mês")
    print("- Trimestre")
    print("- Dia da Semana")

    print("\n" + "=" * 60)
    print("TRATAMENTO CONCLUÍDO COM SUCESSO")
    print("=" * 60)


if __name__ == "__main__":
    main()