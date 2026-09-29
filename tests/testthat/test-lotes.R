testthat::test_that("pedidos iguais em lotes diferentes sobrevivem e conflitos internos sao rejeitados", {
  a <- gerar_vendas(20, 1); a[["ID Execucao"]] <- "a"
  b <- gerar_vendas(20, 2); b[["ID Execucao"]] <- "b"
  x <- rbind(a,b)
  testthat::expect_equal(nrow(tratar_vendas(x)$dados), 40)
  conflito <- a[1,,drop=FALSE]; conflito$Produto <- "Outro"
  d <- tratar_vendas(rbind(x,conflito))$dados
  testthat::expect_equal(nrow(d),39)
  testthat::expect_equal(sum(d[["ID Execucao"]] == "b"),20)
})

testthat::test_that("painel carrega Spark completo e preserva a base diante de execucao incompleta", {
  raiz <- tempfile(); dir.create(raiz)
  on.exit(unlink(raiz, recursive = TRUE), add = TRUE)
  pasta <- file.path(raiz, "results", "bigdata", "exec-teste")
  dir.create(pasta, recursive = TRUE)
  writeLines("exec-teste", file.path(dirname(pasta), "ultima.txt"))
  testthat::expect_error(ultima_base_spark(raiz), "incompleta")
  writeLines("ok", file.path(pasta, "CONCLUIDO"))
  testthat::expect_error(ultima_base_spark(raiz), "limite")
  write.csv(gerar_vendas(50), file.path(pasta, "vendas_painel.csv"), row.names = FALSE)
  shiny::testServer(criar_servidor(raiz), {
    session$flushReact()
    testthat::expect_equal(nrow(base()$dados), 50)
    testthat::expect_match(fonte(), "Spark")
    writeLines("exec-incompleta", file.path(raiz, "results", "bigdata", "ultima.txt"))
    session$setInputs(carregar_spark = 1)
    testthat::expect_equal(nrow(base()$dados), 50)
    testthat::expect_match(fonte(), "exec-teste")
  })
})
testthat::test_that("ingestao repetida preserva originais e nao duplica lotes", {
  raiz <- tempfile(); dir.create(raiz)
  on.exit(unlink(raiz,recursive=TRUE),add=TRUE)
  origem <- file.path(raiz,"vendas.csv")
  write.csv(gerar_vendas(20),origem,row.names=FALSE,fileEncoding="UTF-8")
  lake <- file.path(raiz,"lake")
  testthat::expect_output(testthat::expect_equal(ingerir_lotes(origem,lake),1L),"Lotes novos")
  hash <- tools::md5sum(origem)
  testthat::expect_output(testthat::expect_equal(ingerir_lotes(origem,lake),0L),"Lotes novos")
  testthat::expect_equal(tools::md5sum(origem),hash)
  testthat::expect_length(list.files(file.path(lake,"bronze")),1)
})
testthat::test_that("arredondamento monetario resolve empates de desconto em centavos", {
  testthat::expect_equal(arredondar_moeda(c(149.7 * .15, 2.345, 2.355)), c(22.46, 2.34, 2.36))
})

testthat::test_that("estatisticas e probabilidades possuem denominadores corretos", {
  x <- tratar_vendas(gerar_vendas(20))$dados
  x$Desconto <- 0; x$Desconto[1:4] <- .1
  x[["Valor Total"]] <- 100; x[["Valor Total"]][1:2] <- 600
  p <- probabilidades_vendas(x)
  testthat::expect_equal(p$Probabilidade_empirica[2],.2)
  testthat::expect_equal(p$Probabilidade_empirica[5],.5)
  x$Desconto <- 0
  testthat::expect_true(is.na(probabilidades_vendas(x)$Probabilidade_empirica[5]))
  testthat::expect_equal(moda_descritiva(c(1,1,2,2,3)),"1; 2")
  testthat::expect_equal(moda_descritiva(c(1,2,3)),"Sem moda")
  testthat::expect_equal(descrever_vendas(x)$Variancia[4],var(x[["Valor Total"]]))
  f <- frequencias_vendas(x)
  testthat::expect_equal(as.numeric(tapply(f$Proporcao,f$Variavel,sum)),rep(1,3))
  testthat::expect_equal(nrow(frequencias_vendas(x[0, ])), 0)
  testthat::expect_true(all(is.na(probabilidades_vendas(x[0, ])$Probabilidade_empirica)))
})
