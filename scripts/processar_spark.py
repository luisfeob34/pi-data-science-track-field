from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    DateType,
    DoubleType,
    IntegerType,
    StringType,
    StructField,
    StructType,
)


ARQUIVO_ENTRADA = "data/processed/vendas_processadas.csv"
PASTA_SAIDA = Path("results/spark")
SCHEMA_VENDAS = StructType([
    StructField("ID Pedido", IntegerType(), True),
    StructField("Data da Venda", DateType(), True),
    StructField("Cliente", StringType(), True),
    StructField("Produto", StringType(), True),
    StructField("Categoria", StringType(), True),
    StructField("Canal de Venda", StringType(), True),
    StructField("Região", StringType(), True),
    StructField("Preço Unitário", DoubleType(), True),
    StructField("Quantidade", IntegerType(), True),
    StructField("Desconto", DoubleType(), True),
    StructField("Valor Total", DoubleType(), True),
    StructField("Valor Bruto", DoubleType(), True),
    StructField("Valor Desconto", DoubleType(), True),
    StructField("Possui Desconto", StringType(), True),
    StructField("Desconto Percentual", DoubleType(), True),
    StructField("Faixa de Desconto", StringType(), True),
    StructField("Valor por Item", DoubleType(), True),
    StructField("Porte do Pedido", StringType(), True),
    StructField("Faixa de Valor", StringType(), True),
    StructField("Ano", IntegerType(), True),
    StructField("Número do Mês", IntegerType(), True),
    StructField("Mês", StringType(), True),
    StructField("Trimestre", StringType(), True),
    StructField("Dia da Semana", StringType(), True),
])


def criar_sessao_spark():
    spark = (
        SparkSession.builder
        .appName("PI-Data-Science-Track-Field")
        .master("local[*]")
        .getOrCreate()
    )

    spark.sparkContext.setLogLevel("ERROR")

    return spark


def main():
    print("=" * 70)
    print("PROCESSAMENTO COM APACHE SPARK")
    print("=" * 70)

    spark = criar_sessao_spark()

    try:
        # -----------------------------------------------------
        # 1. Carregar a base processada
        # -----------------------------------------------------
        df = (
            spark.read
            .option("header", True)
            .option("encoding", "UTF-8")
            .option("dateFormat", "yyyy-MM-dd")
            .schema(SCHEMA_VENDAS)
            .csv(ARQUIVO_ENTRADA)
        )

        print("\n1. BASE CARREGADA NO SPARK")
        print(f"Quantidade de registros: {df.count()}")
        print(f"Quantidade de colunas: {len(df.columns)}")

        # -----------------------------------------------------
        # 2. Exibir o schema
        # -----------------------------------------------------
        print("\n2. SCHEMA DO DATAFRAME")
        df.printSchema()

        # -----------------------------------------------------
        # 3. Exibir uma amostra
        # -----------------------------------------------------
        print("\n3. AMOSTRA DOS DADOS")

        df.select(
            "ID Pedido",
            "Data da Venda",
            "Produto",
            "Categoria",
            "Canal de Venda",
            "Região",
            "Quantidade",
            "Valor Total",
        ).show(
            10,
            truncate=False,
        )

        # -----------------------------------------------------
        # 4. Indicadores gerais com DataFrame API
        # -----------------------------------------------------
        print("\n4. INDICADORES GERAIS - DATAFRAME API")

        indicadores = df.agg(
            F.count("ID Pedido").alias("Total Pedidos"),
            F.sum("Quantidade").alias("Itens Vendidos"),
            F.round(
                F.sum("Valor Bruto"),
                2,
            ).alias("Faturamento Bruto"),
            F.round(
                F.sum("Valor Desconto"),
                2,
            ).alias("Descontos Concedidos"),
            F.round(
                F.sum("Valor Total"),
                2,
            ).alias("Faturamento Liquido"),
            F.round(
                F.avg("Valor Total"),
                2,
            ).alias("Ticket Medio"),
        )

        indicadores.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 5. Faturamento por produto
        # -----------------------------------------------------
        print("\n5. FATURAMENTO POR PRODUTO")

        por_produto = (
            df.groupBy("Produto")
            .agg(
                F.count("ID Pedido").alias("Pedidos"),
                F.sum("Quantidade").alias("Itens Vendidos"),
                F.round(
                    F.sum("Valor Total"),
                    2,
                ).alias("Faturamento"),
            )
            .orderBy(
                F.desc("Faturamento")
            )
        )

        por_produto.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 6. Faturamento por categoria
        # -----------------------------------------------------
        print("\n6. FATURAMENTO POR CATEGORIA")

        por_categoria = (
            df.groupBy("Categoria")
            .agg(
                F.count("ID Pedido").alias("Pedidos"),
                F.sum("Quantidade").alias("Itens Vendidos"),
                F.round(
                    F.sum("Valor Total"),
                    2,
                ).alias("Faturamento"),
            )
            .orderBy(
                F.desc("Faturamento")
            )
        )

        por_categoria.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 7. Faturamento por região
        # -----------------------------------------------------
        print("\n7. FATURAMENTO POR REGIÃO")

        por_regiao = (
            df.groupBy("Região")
            .agg(
                F.count("ID Pedido").alias("Pedidos"),
                F.sum("Quantidade").alias("Itens Vendidos"),
                F.round(
                    F.sum("Valor Total"),
                    2,
                ).alias("Faturamento"),
            )
            .orderBy(
                F.desc("Faturamento")
            )
        )

        por_regiao.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 8. Faturamento por canal
        # -----------------------------------------------------
        print("\n8. FATURAMENTO POR CANAL")

        por_canal = (
            df.groupBy("Canal de Venda")
            .agg(
                F.count("ID Pedido").alias("Pedidos"),
                F.sum("Quantidade").alias("Itens Vendidos"),
                F.round(
                    F.sum("Valor Total"),
                    2,
                ).alias("Faturamento"),
            )
            .orderBy(
                F.desc("Faturamento")
            )
        )

        por_canal.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 9. Evolução mensal
        # -----------------------------------------------------
        print("\n9. FATURAMENTO MENSAL")

        mensal = (
            df.groupBy(
                "Número do Mês",
                "Mês",
            )
            .agg(
                F.count("ID Pedido").alias("Pedidos"),
                F.sum("Quantidade").alias("Itens Vendidos"),
                F.round(
                    F.sum("Valor Total"),
                    2,
                ).alias("Faturamento"),
            )
            .orderBy(
                "Número do Mês"
            )
        )

        mensal.show(
            12,
            truncate=False,
        )

        # -----------------------------------------------------
        # 10. Criar uma visão temporária para Spark SQL
        # -----------------------------------------------------
        df.createOrReplaceTempView(
            "vendas"
        )

        # -----------------------------------------------------
        # 11. Consulta usando Spark SQL
        # -----------------------------------------------------
        print("\n10. ANÁLISE COM SPARK SQL")

        consulta_sql = spark.sql(
            """
            SELECT
                Categoria,
                COUNT(`ID Pedido`) AS Pedidos,
                SUM(Quantidade) AS Itens_Vendidos,
                ROUND(SUM(`Valor Total`), 2) AS Faturamento,
                ROUND(AVG(`Valor Total`), 2) AS Ticket_Medio
            FROM vendas
            GROUP BY Categoria
            ORDER BY Faturamento DESC
            """
        )

        consulta_sql.show(
            truncate=False
        )

        # -----------------------------------------------------
        # 12. Spark SQL - desempenho mensal
        # -----------------------------------------------------
        print("\n11. DESEMPENHO MENSAL COM SPARK SQL")

        sql_mensal = spark.sql(
            """
            SELECT
                `Número do Mês` AS Numero_Mes,
                `Mês` AS Mes,
                COUNT(`ID Pedido`) AS Pedidos,
                SUM(Quantidade) AS Itens_Vendidos,
                ROUND(SUM(`Valor Total`), 2) AS Faturamento
            FROM vendas
            GROUP BY
                `Número do Mês`,
                `Mês`
            ORDER BY Numero_Mes
            """
        )

        sql_mensal.show(
            12,
            truncate=False,
        )

        # -----------------------------------------------------
        # 13. Criar pasta para resultados
        # -----------------------------------------------------
        PASTA_SAIDA.mkdir(
            parents=True,
            exist_ok=True,
        )

        # -----------------------------------------------------
        # 14. Salvar resultados do Spark
        #
        # coalesce(1) é adequado aqui porque nossa base é
        # pequena e queremos facilitar a inspeção dos arquivos.
        # -----------------------------------------------------
        por_produto.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "faturamento_produto")
        )

        por_categoria.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "faturamento_categoria")
        )

        por_regiao.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "faturamento_regiao")
        )

        por_canal.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "faturamento_canal")
        )

        mensal.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "faturamento_mensal")
        )

        consulta_sql.coalesce(1).write.mode(
            "overwrite"
        ).option(
            "header",
            True,
        ).csv(
            str(PASTA_SAIDA / "spark_sql_categoria")
        )

        print("\n12. RESULTADOS SALVOS")
        print(f"Pasta: {PASTA_SAIDA}")

        print("\n" + "=" * 70)
        print("PROCESSAMENTO SPARK CONCLUÍDO COM SUCESSO")
        print("=" * 70)

    finally:
        spark.stop()


if __name__ == "__main__":
    main()