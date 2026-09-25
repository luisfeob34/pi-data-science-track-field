testthat::test_that("testes usam Holm, relatam efeitos e lidam com amostras pequenas", {
  x <- tratar_vendas(gerar_vendas(1000))$dados
  t <- testes_estatisticos(x)
  testthat::expect_equal(nrow(t), 5L)
  testthat::expect_true(all(is.finite(t$p_valor)))
  testthat::expect_equal(t$p_ajustado, p.adjust(t$p_valor, "holm"))
  testthat::expect_true(all(t$p_ajustado >= t$p_valor))
  testthat::expect_true(all(abs(t$Efeito) <= 1))
  pequeno <- testes_estatisticos(x[1:2, ])
  testthat::expect_true(all(is.na(pequeno$p_valor)))
  testthat::expect_identical(t, testes_estatisticos(x))
})

testthat::test_that("backtest separa passado e futuro, e intervalos são ordenados", {
  s <- data.frame(Data = seq(as.Date("2024-01-01"), by = "month", length.out = 18),
    Faturamento = 1000 + seq_len(18) * 100 + rep(c(-10, 0, 10), 6), Completo = TRUE)
  p <- prever_vendas(s, 6)
  testthat::expect_true(p$disponivel)
  testthat::expect_equal(p$modelo, "Tendência linear")
  testthat::expect_equal(nrow(p$previsao), 6L)
  testthat::expect_true(all(p$erros$Treino_ate < p$erros$Teste_em))
  testthat::expect_true(all(p$previsao$Inferior <= p$previsao$Previsao & p$previsao$Previsao <= p$previsao$Superior))
  testthat::expect_true(all(p$previsao$Inferior >= 0))
  # Alterar apenas o último valor não pode modificar a previsão para esse valor.
  alterada <- s
  alterada$Faturamento[18] <- 99999
  q <- prever_vendas(alterada)
  testthat::expect_equal(p$erros$Previsto, q$erros$Previsto)
  testthat::expect_equal(as.character(p$previsao$Data[1]), "2025-07-01")
})

testthat::test_that("histórico curto, lacunas e extremidades parciais são explícitos", {
  d <- tratar_vendas(gerar_vendas(1000))$dados
  s <- serie_mensal(d, as.Date(c("2026-01-02", "2026-12-20")))
  testthat::expect_false(s$Completo[1])
  testthat::expect_false(tail(s$Completo, 1))
  testthat::expect_false(prever_vendas(s[1:5, ])$disponivel)
  s$Faturamento[5] <- NA_real_
  testthat::expect_match(prever_vendas(s)$motivo, "sem registros")
  testthat::expect_error(prever_vendas(s, 7), "Horizonte")
  d <- d[format(d[["Data da Venda"]], "%m") != "05", ]
  s <- serie_mensal(d, as.Date(c("2026-01-01", "2026-12-31")), TRUE)
  testthat::expect_equal(s$Faturamento[5], 0)
})

testthat::test_that("série constante e série zero produzem resultados finitos", {
  for (valor in c(0, 1000)) {
    s <- data.frame(Data = seq(as.Date("2025-01-01"), by = "month", length.out = 12),
      Faturamento = valor, Completo = TRUE)
    p <- prever_vendas(s)
    testthat::expect_true(p$disponivel)
    testthat::expect_true(all(is.finite(p$previsao$Previsao)))
  }
})
