testthat::test_that("pipeline publica arquivos coerentes sem sobrescrever a execução anterior", {
  pasta <- tempfile("teste-pipeline-")
  dir.create(pasta)
  on.exit(unlink(pasta, recursive = TRUE))
  brutos <- gerar_vendas(1000)
  resultado <- executar_pipeline(brutos, pasta)
  esperado <- c("vendas_processadas.csv", "testes_estatisticos.csv", "qualidade.csv", "previsao.csv",
    "validacao_modelos.csv", "backtest.csv", "relatorio.md", "ranking.png", "mensal.png", "previsao.png")
  testthat::expect_true(all(file.exists(file.path(resultado$pasta, esperado))))
  d <- read.csv(file.path(resultado$pasta, "vendas_processadas.csv"), check.names = FALSE)
  testthat::expect_equal(nrow(d), 1000L)
  checksum <- tools::md5sum(file.path(resultado$pasta, "vendas_processadas.csv"))
  segunda <- executar_pipeline(brutos[1:20, ], pasta)
  testthat::expect_false(identical(resultado$pasta, segunda$pasta))
  testthat::expect_equal(checksum, tools::md5sum(file.path(resultado$pasta, "vendas_processadas.csv")))
})

testthat::test_that("Shiny aplica filtros e atualiza testes e horizonte reativamente", {
  shiny::testServer(criar_servidor(raiz_teste), {
    session$setInputs(dimensao = "Produto", metrica = "Faturamento", top = 10, horizonte = 3, meses_zero = FALSE)
    total <- nrow(dados())
    categoria <- unique(base()$dados$Categoria)[1]
    session$setInputs(categorias = categoria)
    testthat::expect_true(nrow(dados()) < total)
    testthat::expect_true(all(dados()$Categoria == categoria))
    testthat::expect_equal(testes()$N, rep(nrow(dados()), 5))
    session$setInputs(categorias = character(), horizonte = 6)
    testthat::expect_equal(nrow(dados()), total)
    testthat::expect_equal(nrow(previsao()$previsao), 6L)
    # Força a conversão real dos gráficos em widgets, além do cálculo dos dados.
    testthat::expect_true(nzchar(output$ranking))
    testthat::expect_true(nzchar(output$previsao_grafico))
    testthat::expect_match(output$destaques$html, "Produto com mais receita")
    testthat::expect_match(output$leituras$html, "O gasto por pedido")
    testthat::expect_match(output$nota_previsao$html, "Faixa estimada")
    # Um upload sem as colunas exigidas deve preservar a base corrente.
    invalido <- tempfile(fileext = ".csv")
    writeLines("coluna\nvalor", invalido)
    session$setInputs(arquivo = data.frame(name = "invalido.csv", size = file.info(invalido)$size, datapath = invalido))
    testthat::expect_equal(nrow(dados()), total)
    valido <- tempfile(fileext = ".csv")
    gravar_csv(gerar_vendas(50), valido)
    session$setInputs(arquivo = data.frame(name = "valido.csv", size = file.info(valido)$size, datapath = valido))
    testthat::expect_equal(nrow(base()$dados), 50L)
    testthat::expect_equal(fonte(), "CSV importado: valido.csv")
    unlink(c(invalido, valido))
  })
})

testthat::test_that("CSV local inválido permite recuperar o painel por importação", {
  pasta <- tempfile("teste-shiny-invalido-")
  dir.create(file.path(pasta, "data", "raw"), recursive = TRUE)
  on.exit(unlink(pasta, recursive = TRUE))
  writeLines("incorreto\nvalor", file.path(pasta, "data", "raw", "vendas_simuladas.csv"))
  shiny::testServer(criar_servidor(pasta), {
    testthat::expect_equal(nrow(base()$dados), 1000L)
    testthat::expect_match(fonte(), "não pôde ser lido")
  })
})
