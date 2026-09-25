testes_estatisticos <- function(x) {
  linhas <- list()
  adicionar <- function(nome, hipotese, n, estatistica = NA_real_, efeito = NA_real_,
                        medida = "", p = NA_real_, nota = "") {
    linhas[[length(linhas) + 1L]] <<- data.frame(Teste = nome, Hipotese_nula = hipotese,
      N = n, Estatistica = estatistica, Efeito = efeito, Medida = medida, p_valor = p, Nota = nota)
  }
  for (coluna in c("Categoria", "Canal de Venda", "Região")) {
    grupos <- factor(x[[coluna]])
    k <- nlevels(grupos)
    nome <- paste("Kruskal-Wallis:", coluna)
    h0 <- "Distribuições do valor dos pedidos iguais entre os grupos"
    if (k < 2 || any(table(grupos) < 5) || length(unique(x[["Valor Total"]])) < 2) {
      adicionar(nome, h0, nrow(x), nota = "Não calculado: requer ≥2 grupos, ≥5 pedidos por grupo e valores variáveis.")
    } else {
      teste <- kruskal.test(x[["Valor Total"]], grupos)
      efeito <- max(0, (unname(teste$statistic) - k + 1) / (nrow(x) - k))
      adicionar(nome, h0, nrow(x), unname(teste$statistic), efeito, "Epsilon²", teste$p.value,
        "Teste de distribuições; diferença de medianas só com formas comparáveis. Não identifica quais pares diferem.")
    }
  }
  if (nrow(x) >= 10 && length(unique(x$Desconto)) > 1 && length(unique(x[["Valor Total"]])) > 1) {
    teste <- cor.test(x$Desconto, x[["Valor Total"]], method = "spearman", exact = FALSE)
    adicionar("Spearman: desconto × valor", "Associação monotônica igual a zero", nrow(x),
      unname(teste$statistic), unname(teste$estimate), "Rho", teste$p.value,
      "O desconto participa do cálculo do valor. Associação não mede efeito causal nem impacto comercial.")
  } else adicionar("Spearman: desconto × valor", "Associação monotônica igual a zero", nrow(x),
                   nota = "Não calculado: requer ≥10 pedidos e variação nas duas variáveis.")
  tab <- table(x$Categoria, x[["Canal de Venda"]])
  if (nrow(tab) >= 2 && ncol(tab) >= 2 && sum(tab) >= 10) {
    teste <- com_semente(42, function() chisq.test(tab, simulate.p.value = TRUE, B = 4999))
    v <- sqrt(unname(teste$statistic) / (sum(tab) * min(nrow(tab) - 1, ncol(tab) - 1)))
    adicionar("Qui-quadrado: categoria × canal", "Categoria e canal independentes", sum(tab),
      unname(teste$statistic), v, "V de Cramér", teste$p.value, "p-valor por Monte Carlo (4.999 simulações; semente 42).")
  } else adicionar("Qui-quadrado: categoria × canal", "Categoria e canal independentes", nrow(x),
                   nota = "Não calculado: requer ≥10 pedidos e ao menos duas categorias e dois canais.")
  saida <- do.call(rbind, linhas)
  saida$p_ajustado <- p.adjust(saida$p_valor, method = "holm")
  saida$Conclusao <- ifelse(is.na(saida$p_ajustado), "Amostra insuficiente",
    ifelse(saida$p_ajustado < .05, "Evidência contra H0 (5%)", "Sem evidência suficiente contra H0"))
  saida
}

descrever_vendas <- function(x) {
  campos <- c("Preço Unitário", "Quantidade", "Desconto Percentual", "Valor Total", "Valor por Item")
  do.call(rbind, lapply(campos, function(campo) {
    y <- x[[campo]]
    data.frame(Variavel = campo, N = length(y), Media = if (length(y)) mean(y) else NA_real_,
      Desvio = if (length(y) > 1) sd(y) else NA_real_,
      Minimo = if (length(y)) min(y) else NA_real_,
      Q1 = if (length(y)) unname(quantile(y, .25)) else NA_real_,
      Mediana = if (length(y)) median(y) else NA_real_,
      Q3 = if (length(y)) unname(quantile(y, .75)) else NA_real_,
      Maximo = if (length(y)) max(y) else NA_real_)
  }))
}
