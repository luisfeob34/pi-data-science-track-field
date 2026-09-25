testthat::test_that("tratamento audita erros e recalcula o valor sem perder campos", {
  x <- gerar_vendas(20)
  x <- rbind(x, x[1, ])
  x$Produto[2] <- "  Produto teste  "
  x$Quantidade[3] <- 0
  x[["Data da Venda"]][4] <- "2026-02-30"
  x[["Preço Unitário"]][5] <- "invalido"
  x$Cliente[6] <- ""
  x[["ID Pedido"]][8] <- x[["ID Pedido"]][7]
  x[["Valor Total"]][9] <- 1
  x$Quantidade[10] <- 1.5
  x$Desconto[11] <- 1.1
  x[["Preço Unitário"]][12] <- Inf
  resultado <- tratar_vendas(x)
  d <- resultado$dados
  testthat::expect_equal(nrow(d), 11L)
  testthat::expect_true("Produto teste" %in% d$Produto)
  testthat::expect_s3_class(d[["Data da Venda"]], "Date")
  testthat::expect_equal(d[["Valor Total"]], round(d[["Valor Bruto"]] - d[["Valor Desconto"]], 2))
  testthat::expect_equal(sum(resultado$auditoria$Registros[2:7]) + nrow(d), nrow(x))
  testthat::expect_true(all(c("Cliente", "Ano", "Trimestre", "Dia da Semana") %in% names(d)))
})

testthat::test_that("casos vazios e schema inválido são previsíveis", {
  x <- gerar_vendas(10)
  testthat::expect_error(tratar_vendas(x[, -1]), "obrigatórias")
  testthat::expect_equal(nrow(tratar_vendas(x[FALSE, ])$dados), 0L)
  x$Quantidade <- 0
  testthat::expect_equal(nrow(tratar_vendas(x)$dados), 0L)
  testthat::expect_error(gerar_vendas(0), "inteiro")
})

testthat::test_that("filtros e agregados conservam o total e não misturam anos", {
  d <- tratar_vendas(gerar_vendas(1000))$dados
  a <- agregar_vendas(d, "Categoria")
  testthat::expect_equal(sum(a$Pedidos), nrow(d))
  testthat::expect_equal(sum(a$Faturamento), sum(d[["Valor Total"]]))
  z <- filtrar_vendas(d, as.Date(c("2026-03-01", "2026-06-30")), "Vestuário", "E-commerce")
  testthat::expect_true(nrow(z) > 0)
  testthat::expect_true(all(z$Categoria == "Vestuário" & z[["Canal de Venda"]] == "E-commerce"))
  testthat::expect_true(all(z[["Data da Venda"]] >= as.Date("2026-03-01") & z[["Data da Venda"]] <= as.Date("2026-06-30")))
  z <- d[1:2, ]
  z[["Data da Venda"]] <- as.Date(c("2025-01-01", "2026-01-31"))
  s <- serie_mensal(z)
  testthat::expect_equal(nrow(s), 13L)
  testthat::expect_equal(sum(s$Faturamento, na.rm = TRUE), sum(z[["Valor Total"]]))
  testthat::expect_true(is.na(s$Faturamento[2]))
})

testthat::test_that("simulação é reproduzível sem alterar o RNG do chamador", {
  set.seed(9)
  anterior <- .Random.seed
  testthat::expect_identical(gerar_vendas(50, 10), gerar_vendas(50, 10))
  testthat::expect_identical(.Random.seed, anterior)
})
