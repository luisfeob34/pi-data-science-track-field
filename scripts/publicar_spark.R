#!/usr/bin/env Rscript
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- dirname(dirname(normalizePath(arquivo)))
for (m in c("dados", "estatistica", "previsao", "visualizacao", "pipeline"))
  source(file.path(raiz, "R", paste0(m, ".R")), encoding = "UTF-8")
args <- commandArgs(TRUE)
if (length(args) != 1 || !grepl("^exec-[A-Za-z0-9-]+$", args[1])) stop("Execucao invalida.")
saida <- Sys.getenv("PI_PIPELINE_ROOT", unset = raiz)
pasta <- file.path(saida, "results", "bigdata", args[1])
if (!file.exists(file.path(pasta, "CONCLUIDO"))) stop("Spark nao concluiu esta execucao.")
csv <- file.path(pasta, "vendas_painel.csv")
if (file.exists(csv)) {
  x <- ler_vendas(csv)
  resultado <- executar_pipeline(x, saida)
  resumo <- read.csv(file.path(pasta, "resumo.csv"))
  stopifnot(nrow(resultado$tratamento$dados) == resumo$Aceitos,
    abs(sum(resultado$tratamento$dados[["Valor Total"]]) - resumo$Faturamento) < .02)
  writeLines(resultado$pasta, file.path(pasta, "analise_r.txt"))
}
ponteiro <- file.path(saida, "results", "bigdata", "ultima.txt")
tmp <- tempfile(".ultima-", tmpdir = dirname(ponteiro))
writeLines(args[1], tmp)
if (!file.rename(tmp, ponteiro)) stop("Falha ao atualizar ultima execucao.")
cat("Execucao publicada:", args[1], "\n")
