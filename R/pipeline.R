gravar_csv <- function(x, caminho) {
  write.csv(x, caminho, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}

executar_pipeline <- function(brutos, raiz, horizonte = 3L, cobertura = NULL,
                              meses_sem_venda_zero = FALSE) {
  tratamento <- tratar_vendas(brutos)
  x <- tratamento$dados
  if (!nrow(x)) stop("Nenhuma venda válida. Consulte as regras do CSV antes de executar novamente.")
  serie <- serie_mensal(x, cobertura, meses_sem_venda_zero)
  testes <- testes_estatisticos(x)
  previsao <- prever_vendas(serie, horizonte)
  pasta <- file.path(raiz, "results", "r")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  temporario <- tempfile(".preparando-", tmpdir = pasta)
  dir.create(temporario)
  on.exit(unlink(temporario, recursive = TRUE), add = TRUE)
  gravar_csv(x, file.path(temporario, "vendas_processadas.csv"))
  gravar_csv(tratamento$auditoria, file.path(temporario, "qualidade.csv"))
  gravar_csv(descrever_vendas(x), file.path(temporario, "estatisticas_descritivas.csv"))
  gravar_csv(testes, file.path(temporario, "testes_estatisticos.csv"))
  gravar_csv(serie, file.path(temporario, "faturamento_mensal.csv"))
  for (item in list(c("Produto", "produto"), c("Categoria", "categoria"), c("Canal de Venda", "canal"),
                    c("Região", "regiao"), c("Trimestre", "trimestre"), c("Faixa de Desconto", "desconto")))
    gravar_csv(agregar_vendas(x, item[1]), file.path(temporario, paste0("faturamento_", item[2], ".csv")))
  if (previsao$disponivel) {
    gravar_csv(previsao$previsao, file.path(temporario, "previsao.csv"))
    gravar_csv(previsao$validacao, file.path(temporario, "validacao_modelos.csv"))
    gravar_csv(previsao$erros, file.path(temporario, "backtest.csv"))
  }
  graficos <- list(ranking = grafico_ranking(x), mensal = grafico_serie(serie),
                   distribuicao = grafico_distribuicao(x), previsao = grafico_previsao(previsao))
  for (nome in names(graficos)) ggplot2::ggsave(file.path(temporario, paste0(nome, ".png")),
    graficos[[nome]], width = 10, height = 5.5, dpi = 140)
  writeLines(c("# Relatório de análise em R", "", paste("Pedidos válidos:", nrow(x)),
    paste("Faturamento: R$", format(round(sum(x[["Valor Total"]]), 2), nsmall = 2)),
    paste("Período:", min(x[["Data da Venda"]]), "a", max(x[["Data da Venda"]])), "",
    "## Testes", "Kruskal-Wallis, Spearman e qui-quadrado. Ajuste de Holm; alfa de 5%.",
    "Pedidos devem ser independentes. Comparações exploratórias não demonstram causalidade.",
    "A correção cobre os testes desta execução, não sucessivas buscas por filtros.", "",
    "## Previsão", previsao$motivo, paste("Modelo:", previsao$modelo),
    "Meses parciais excluídos do ajuste; ano e mês permanecem separados.",
    paste("Meses sem registro interpretados como zero:", meses_sem_venda_zero),
    "Intervalos dependem das hipóteses dos modelos e não garantem resultados futuros.",
    "A base padrão é simulada: resultados demonstram o método e não a operação real da empresa."),
    file.path(temporario, "relatorio.md"), useBytes = TRUE)
  capture.output(sessionInfo(), file = file.path(temporario, "sessionInfo.txt"))
  destino <- file.path(pasta, paste0("exec-", format(Sys.time(), "%Y%m%d-%H%M%S"), "-",
                                    sub(".preparando-", "", basename(temporario), fixed = TRUE)))
  if (!file.rename(temporario, destino)) stop("Não foi possível publicar a execução.")
  # Cada execução é independente: não apagar nem sobrescrever resultados anteriores.
  list(pasta = destino, tratamento = tratamento, testes = testes, previsao = previsao)
}
