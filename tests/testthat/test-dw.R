testthat::test_that("visão do Data Warehouse vira a mesma entrada de um CSV de vendas", {
  bruto <- gerar_vendas(30, 7)
  bruto[["ID Execucao"]] <- "exec-teste"
  # Simula o retorno do RPostgres: datas como Date, números como double/integer.
  vw <- data.frame(pedido = as.character(bruto[["ID Pedido"]]),
    data_venda = as.Date(bruto[["Data da Venda"]]), cliente = bruto$Cliente, produto = bruto$Produto,
    categoria = bruto$Categoria, canal = bruto[["Canal de Venda"]], regiao = bruto[["Região"]],
    preco = bruto[["Preço Unitário"]], quantidade = as.integer(bruto$Quantidade), desconto = bruto$Desconto,
    valor_total = bruto[["Valor Total"]], execucao = bruto[["ID Execucao"]])
  x <- vendas_do_dw(vw)
  testthat::expect_identical(names(x), c(colunas_vendas, "ID Execucao"))
  testthat::expect_true(all(vapply(x, is.character, logical(1))))
  tratado <- tratar_vendas(x)
  testthat::expect_equal(nrow(tratado$dados), 30L)
  testthat::expect_equal(sum(tratado$dados[["Valor Total"]]), sum(bruto[["Valor Total"]]))
  testthat::expect_equal(tratado$auditoria$Registros[tratado$auditoria$Etapa == "Totais recalculados com diferença > R$ 0,01"], 0)
  testthat::expect_error(vendas_do_dw(vw[, -1]), "pedido")
})

testthat::test_that("sem PI_DW_NOME o painel não tenta acessar o Data Warehouse", {
  testthat::expect_error(ler_dw(""), "não configurado")
  testthat::expect_match(descrever_carga_dw(NULL), "sem carga")
  carga <- data.frame(execucao_spark = "exec-1", vendas = 8000L,
    carregado_em = as.POSIXct("2026-11-23 10:00:00", tz = "UTC"))
  testthat::expect_match(descrever_carga_dw(carga), "exec-1 · 8.000 vendas")
})

testthat::test_that("consulta usa a visão do modelo estrela com as colunas esperadas", {
  testthat::expect_match(consulta_vendas_dw, "FROM dw.vw_vendas")
  sql <- readLines(file.path(raiz_teste, "dw", "esquema.sql"), encoding = "UTF-8")
  visao <- paste(sql[grep("CREATE OR REPLACE VIEW", sql):length(sql)], collapse = " ")
  for (coluna in colunas_vw_vendas) testthat::expect_match(visao, coluna, fixed = TRUE)
  carga <- paste(readLines(file.path(raiz_teste, "dw", "carregar.sql"), encoding = "UTF-8"), collapse = " ")
  for (tabela in c("dim_produto", "dim_canal", "dim_regiao", "dim_data", "fato_vendas"))
    testthat::expect_match(carga, paste0(tabela, ".csv"), fixed = TRUE)
  testthat::expect_match(carga, "BEGIN;.*COMMIT;")
})

# Integração opcional com um PostgreSQL real (por exemplo, dentro da VM de exibição).
testthat::test_that("leitura real do Data Warehouse, quando disponível", {
  testthat::skip_if(!nzchar(Sys.getenv("PI_DW_TESTE")), "Defina PI_DW_TESTE=dw_vendas para testar no PostgreSQL.")
  testthat::skip_if_not_installed("RPostgres")
  z <- ler_dw(Sys.getenv("PI_DW_TESTE"))
  testthat::expect_true(nrow(z$dados) > 0)
  testthat::expect_equal(nrow(tratar_vendas(z$dados)$dados), z$carga$vendas[1])
})
