serie_mensal <- function(x, cobertura = NULL, meses_sem_venda_zero = FALSE) {
  if (!nrow(x)) return(data.frame(Data = as.Date(character()), Faturamento = numeric(), Completo = logical()))
  if (is.null(cobertura)) cobertura <- range(x[["Data da Venda"]])
  cobertura <- as.Date(cobertura)
  inicio <- as.Date(format(cobertura[1], "%Y-%m-01"))
  fim <- as.Date(format(cobertura[2], "%Y-%m-01"))
  meses <- seq(inicio, fim, by = "month")
  ultimos <- seq(inicio, by = "month", length.out = length(meses) + 1L)[-1] - 1
  agregado <- tapply(x[["Valor Total"]], format(x[["Data da Venda"]], "%Y-%m"), sum)
  valores <- as.numeric(agregado[format(meses, "%Y-%m")])
  if (meses_sem_venda_zero) valores[is.na(valores)] <- 0
  data.frame(Data = meses, Faturamento = valores, Completo = meses >= cobertura[1] & ultimos <= cobertura[2])
}

prever_modelo <- function(y, h, modelo) {
  n <- length(y)
  if (modelo == "Média histórica") {
    centro <- rep(mean(y), h)
    margem <- rep(qt(.975, n - 1) * sd(y) * sqrt(1 + 1 / n), h)
  } else if (modelo == "Último mês") {
    centro <- rep(tail(y, 1), h)
    margem <- qnorm(.975) * sqrt(mean(diff(y)^2)) * sqrt(seq_len(h))
  } else {
    ajuste <- lm(valor ~ tempo, data = data.frame(valor = y, tempo = seq_len(n)))
    pred <- suppressWarnings(predict(ajuste, newdata = data.frame(tempo = n + seq_len(h)),
                                     interval = "prediction", level = .95))
    return(data.frame(Previsao = pmax(0, pred[, "fit"]), Inferior = pmax(0, pred[, "lwr"]),
                       Superior = pmax(0, pred[, "upr"])))
  }
  data.frame(Previsao = pmax(0, centro), Inferior = pmax(0, centro - margem), Superior = pmax(0, centro + margem))
}

prever_vendas <- function(serie, horizonte = 3L, modelo = "Automático") {
  modelos <- c("Média histórica", "Último mês", "Tendência linear")
  if (length(modelo) != 1 || is.na(modelo) || !modelo %in% c("Automático", modelos))
    stop("Modelo de previsão inválido.")
  if (length(horizonte) != 1 || !is.finite(horizonte) || horizonte < 1 || horizonte > 6 || horizonte != floor(horizonte))
    stop("Horizonte deve ser um inteiro entre 1 e 6 meses.")
  treino <- serie[serie$Completo, , drop = FALSE]
  vazio <- list(disponivel = FALSE, motivo = "", historico = serie, previsao = data.frame(),
                validacao = data.frame(), erros = data.frame(), modelo = NA_character_)
  if (nrow(treino) < 8) {
    vazio$motivo <- "São necessários pelo menos 8 meses completos; meses parciais das extremidades foram excluídos."
    return(vazio)
  }
  if (any(!is.finite(treino$Faturamento))) {
    vazio$motivo <- "Há meses sem registros. Confirme se representam zero vendas antes de fazer a previsão."
    return(vazio)
  }
  y <- treino$Faturamento
  # Origens móveis: só os meses anteriores entram em cada ajuste. Avaliação de um passo.
  origens <- seq.int(max(5L, length(y) - 5L), length(y) - 1L)
  erros <- do.call(rbind, lapply(modelos, function(modelo) do.call(rbind, lapply(origens, function(i) {
    pred <- prever_modelo(y[seq_len(i)], 1L, modelo)$Previsao[1]
    data.frame(Modelo = modelo, Treino_ate = treino$Data[i], Teste_em = treino$Data[i + 1L],
      Real = y[i + 1L], Previsto = pred, Erro = y[i + 1L] - pred)
  }))))
  validacao <- do.call(rbind, lapply(modelos, function(modelo) {
    e <- erros$Erro[erros$Modelo == modelo]
    data.frame(Modelo = modelo, MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)), Origens = length(e))
  }))
  validacao <- validacao[order(validacao$MAE, match(validacao$Modelo, modelos)), ]
  recomendado <- validacao$Modelo[1]
  melhor <- if (modelo == "Automático") recomendado else modelo
  pred <- prever_modelo(y, horizonte, melhor)
  explicacao <- switch(melhor,
    "Média histórica" = paste("A média histórica teve o menor erro nos testes com meses anteriores.",
      "Esse modelo usa a mesma estimativa central para cada mês futuro.",
      "Isso não significa que as vendas reais serão iguais: elas podem variar dentro ou fora da faixa estimada."),
    "Último mês" = paste("Repetir o valor do último mês teve o menor erro nos testes com meses anteriores.",
      "A estimativa central permanece igual, enquanto a faixa de incerteza aumenta com o prazo.",
      "As vendas reais podem variar."),
    "Tendência linear" = paste("A tendência linear teve o menor erro nos testes com meses anteriores.",
      "Ela projeta a direção observada no histórico; essa tendência pode não continuar no futuro."))
  if (modelo != "Automático") {
    explicacao <- paste(
      switch(melhor,
        "Média histórica" = "Comparação manual: usa a mesma média nos meses futuros.",
        "Último mês" = "Comparação manual: repete o último mês, com incerteza crescente.",
        "Tendência linear" = "Comparação manual: projeta a direção do histórico, que pode não continuar."),
      "O modelo com menor erro nos testes foi", paste0(recomendado, "."),
      if (melhor != recomendado) "O modelo escolhido teve erro maior; esta comparação não substitui a recomendação automática." else "")
  }
  pred <- cbind(Data = seq(tail(treino$Data, 1), by = "month", length.out = horizonte + 1L)[-1], pred)
  list(disponivel = TRUE, motivo = paste(if (modelo == "Automático") "Modelo escolhido por menor MAE em" else "Modelo escolhido manualmente; comparação por MAE em", length(origens),
    "origens temporais de um passo. Intervalos nominais de 95%; não incluem incerteza da seleção do modelo."),
    historico = serie, previsao = pred, validacao = validacao, erros = erros, modelo = melhor,
    explicacao = explicacao, recomendado = recomendado)
}
