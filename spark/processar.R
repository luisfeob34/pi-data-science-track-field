#!/usr/bin/env Rscript
# SparkR executa DataFrames e SQL no motor Spark. Nenhum processamento em Python.
args <- commandArgs(TRUE)
if (length(args) != 3) stop("Uso: processar.R bronze_uri lake_uri pasta_resultados")
library(SparkR, lib.loc = file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
sparkR.session(master = Sys.getenv("SPARK_MASTER", "local[2]"), enableHiveSupport = FALSE,
  sparkConfig = list(spark.sql.shuffle.partitions = "2", spark.driver.memory = "768m",
    spark.sql.ansi.enabled = "false", spark.sql.session.timeZone = "UTC",
    spark.sql.legacy.timeParserPolicy = "CORRECTED", spark.ui.enabled = "false",
    spark.driver.bindAddress = "127.0.0.1", spark.driver.host = "127.0.0.1"))
executar <- function() {
  pasta <- args[3]
  if (dir.exists(pasta)) stop("Destino ja existe: ", pasta)
  dir.create(pasta, recursive = TRUE)
  id <- basename(pasta)
  if (!grepl("^exec-[A-Za-z0-9-]+$", id)) stop("Identificador de execucao invalido.")
  inicio <- Sys.time()
  consultas <- character()
  consulta <- function(q) { consultas <<- c(consultas, q); sql(q) }
  salvar <- function(df, nome) write.df(df, paste0(args[2], "/", nome, "/", id), "parquet", "error")
  csv <- function(df, nome) write.csv(collect(df), file.path(pasta, nome), row.names = FALSE, fileEncoding = "UTF-8")
  bruto <- read.df(paste0(args[1], "/*/entrada.csv"), "csv", header = "true", inferSchema = "false",
    mode = "FAILFAST", quote = '"', escape = '"', multiLine = "true")
  # API DataFrame: selecao explicita e nomes estaveis para SQL/Parquet.
  campos <- c("ID Pedido", "Data da Venda", "Cliente", "Produto", "Categoria", "Canal de Venda", "Região",
    "Preço Unitário", "Quantidade", "Desconto", "Valor Total", "ID Execucao")
  nomes <- c("pedido", "data_venda", "cliente", "produto", "categoria", "canal", "regiao", "preco", "quantidade", "desconto", "total_informado", "execucao")
  df <- do.call(selectExpr, c(list(bruto), as.list(paste0("trim(`", campos, "`) AS ", nomes))))
  createOrReplaceTempView(df, "brutos")
  recebidos <- count(df)
  unicos <- distinct(df)
  createOrReplaceTempView(unicos, "unicos")
  tipados <- consulta("SELECT *, to_date(data_venda, 'yyyy-MM-dd') AS data_ok,
    try_cast(preco AS DOUBLE) AS preco_ok, try_cast(quantidade AS DOUBLE) AS quantidade_ok,
    try_cast(desconto AS DOUBLE) AS desconto_ok, try_cast(total_informado AS DOUBLE) AS total_ok FROM unicos")
  createOrReplaceTempView(tipados, "tipados")
  nulos <- paste(paste0(nomes, " IS NULL OR ", nomes, " = ''"), collapse = " OR ")
  marcados <- consulta(paste0("SELECT *, CASE WHEN ", nulos, " THEN 'Campo ausente'
    WHEN data_ok IS NULL OR date_format(data_ok,'yyyy-MM-dd') <> data_venda THEN 'Data invalida'
    WHEN preco_ok IS NULL OR quantidade_ok IS NULL OR desconto_ok IS NULL OR total_ok IS NULL
      OR isnan(preco_ok) OR isnan(quantidade_ok) OR isnan(desconto_ok) OR isnan(total_ok)
      OR abs(preco_ok) = cast('Infinity' AS DOUBLE) OR abs(quantidade_ok) = cast('Infinity' AS DOUBLE)
      OR abs(desconto_ok) = cast('Infinity' AS DOUBLE) OR abs(total_ok) = cast('Infinity' AS DOUBLE)
      THEN 'Numero invalido'
    WHEN preco_ok <= 0 OR quantidade_ok <= 0 OR quantidade_ok <> floor(quantidade_ok)
      OR desconto_ok < 0 OR desconto_ok > 1 OR total_ok < 0 THEN 'Fora dos limites'
    ELSE NULL END AS motivo FROM tipados"))
  createOrReplaceTempView(marcados, "marcados")
  validos <- consulta("SELECT * FROM marcados WHERE motivo IS NULL")
  createOrReplaceTempView(validos, "validos")
  finais <- consulta("SELECT *, count(*) OVER (PARTITION BY execucao,pedido) AS repeticoes FROM validos")
  createOrReplaceTempView(finais, "finais")
  rejeitados <- consulta("SELECT pedido,execucao,motivo FROM marcados WHERE motivo IS NOT NULL
    UNION ALL SELECT pedido,execucao,'ID conflitante no lote' AS motivo FROM finais WHERE repeticoes > 1")
  salvar(rejeitados, "quarentena")
  silver <- consulta("SELECT pedido,execucao,data_ok AS data_venda,cliente,produto,categoria,canal,regiao,
    preco_ok AS preco,cast(quantidade_ok AS BIGINT) AS quantidade,desconto_ok AS desconto,
    bround(round(preco_ok * quantidade_ok * 100,6),0)/100 AS valor_bruto,
    bround(round((bround(round(preco_ok * quantidade_ok * 100,6),0)/100) * desconto_ok * 100,6),0)/100 AS valor_desconto,
    (bround(round(preco_ok * quantidade_ok * 100,6),0) -
      bround(round((bround(round(preco_ok * quantidade_ok * 100,6),0)/100) * desconto_ok * 100,6),0))/100 AS valor_total
    FROM finais WHERE repeticoes = 1")
  cache(silver)
  createOrReplaceTempView(silver, "vendas")
  aceitos <- count(silver)
  if (aceitos == 0) stop("Nenhuma venda valida para publicar.")
  salvar(silver, "silver")
  # API DataFrame: filtro, agrupamento, agregacao e ordenacao.
  positivos <- filter(select(silver, "categoria", "valor_total"), silver$valor_total >= 0)
  ranking_df <- arrange(summarize(groupBy(positivos, "categoria"), faturamento = sum(positivos$valor_total)), "categoria")
  ranking_sql <- consulta("SELECT categoria,sum(valor_total) AS faturamento FROM vendas GROUP BY categoria ORDER BY categoria")
  stopifnot(isTRUE(all.equal(collect(ranking_df), collect(ranking_sql), tolerance = 1e-8)))
  csv(ranking_df, "categorias_dataframe.csv")
  indicadores <- consulta("SELECT categoria,canal,regiao,count(*) AS pedidos,sum(quantidade) AS itens,
    round(sum(valor_total),2) AS faturamento,round(avg(valor_total),2) AS ticket
    FROM vendas GROUP BY categoria,canal,regiao ORDER BY faturamento DESC")
  salvar(indicadores, "gold/indicadores")
  csv(indicadores, "indicadores.csv")
  csv(consulta("SELECT date_format(data_venda,'yyyy-MM') AS mes,count(*) AS pedidos,round(sum(valor_total),2) AS faturamento
    FROM vendas GROUP BY date_format(data_venda,'yyyy-MM') ORDER BY mes"), "mensal.csv")
  # Modelo estrela em Parquet, com chaves deterministicas e dimensoes unicas.
  dimensoes <- list(produto = "produto,categoria", canal = "canal", regiao = "regiao")
  for (nome in names(dimensoes)) {
    cols <- dimensoes[[nome]]
    chave <- paste0("sha2(to_json(named_struct(", if (nome == "produto") "'produto',produto,'categoria',categoria" else paste0("'", nome, "',", nome), ")),256)")
    d <- consulta(paste0("SELECT DISTINCT ", chave, " AS id_", nome, ",", cols, " FROM vendas"))
    salvar(d, paste0("gold/dim_", nome))
  }
  salvar(consulta("SELECT DISTINCT date_format(data_venda,'yyyyMMdd') AS id_data,data_venda,
    year(data_venda) AS ano,month(data_venda) AS mes,quarter(data_venda) AS trimestre FROM vendas"), "gold/dim_data")
  fato <- consulta("SELECT execucao,pedido,date_format(data_venda,'yyyyMMdd') AS id_data,
    sha2(to_json(named_struct('produto',produto,'categoria',categoria)),256) AS id_produto,
    sha2(to_json(named_struct('canal',canal)),256) AS id_canal,
    sha2(to_json(named_struct('regiao',regiao)),256) AS id_regiao,
    quantidade,preco,desconto,valor_bruto,valor_desconto,valor_total FROM vendas")
  salvar(fato, "gold/fato_vendas")
  # Confere os Parquet gravados, incluindo as chaves do modelo estrela.
  for (nome in c("fato_vendas", "dim_produto", "dim_canal", "dim_regiao", "dim_data")) {
    gravado <- read.df(paste0(args[2], "/gold/", nome, "/", id), "parquet")
    createOrReplaceTempView(gravado, nome)
  }
  integridade <- consulta("SELECT count(*) AS pedidos FROM fato_vendas f
    INNER JOIN dim_produto p ON f.id_produto=p.id_produto
    INNER JOIN dim_canal c ON f.id_canal=c.id_canal
    INNER JOIN dim_regiao r ON f.id_regiao=r.id_regiao
    INNER JOIN dim_data d ON f.id_data=d.id_data")
  stopifnot(collect(integridade)$pedidos[1] == aceitos)
  csv(integridade, "integridade_modelo.csv")
  csv(consulta("SELECT motivo,count(*) AS registros FROM (SELECT * FROM marcados WHERE motivo IS NOT NULL) GROUP BY motivo"), "rejeicoes_campos.csv")
  total <- collect(consulta("SELECT round(sum(valor_total),2) AS total FROM vendas"))$total[1]
  descartados <- count(rejeitados)
  duplicados <- recebidos - count(unicos)
  stopifnot(recebidos == aceitos + descartados + duplicados)
  exportado <- aceitos <= 200000
  if (exportado) {
    out <- select(silver, "pedido", "data_venda", "cliente", "produto", "categoria", "canal", "regiao", "preco", "quantidade", "desconto", "valor_total", "execucao")
    local <- collect(out)
    names(local) <- campos
    write.csv(local, file.path(pasta, "vendas_painel.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  }
  write.csv(data.frame(Execucao = id, Recebidos = recebidos, Duplicados = duplicados,
    Rejeitados = descartados, Aceitos = aceitos, Faturamento = total,
    Exportado_painel = exportado, Duracao_segundos = as.numeric(difftime(Sys.time(),inicio,units='secs'))),
    file.path(pasta, "resumo.csv"), row.names = FALSE)
  writeLines(consultas, file.path(pasta, "consultas.sql"))
  writeLines(c(paste("Spark:", sparkR.version()), paste("Origem:", args[1]), paste("Lake:", args[2]),
    "Execucao local[2]: dois threads locais, sem comprovacao de escala em multiplos servidores.",
    "Dados simulados. Indicadores descrevem os lotes, nao a operacao real de uma empresa."), file.path(pasta, "ambiente.txt"))
  writeLines("ok", file.path(pasta, "CONCLUIDO"))
  cat("Spark concluido:", aceitos, "vendas em", pasta, "\n")
}
tryCatch(executar(), finally = sparkR.session.stop())
