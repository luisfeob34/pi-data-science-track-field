#!/usr/bin/env Rscript
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), mustWork = TRUE)
for (modulo in c("dados", "estatistica", "previsao", "visualizacao", "pipeline"))
  source(file.path(raiz, "R", paste0(modulo, ".R")), encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
valor <- function(chave, padrao) {
  pos <- match(chave, args)
  if (is.na(pos)) return(padrao)
  if (pos == length(args) || startsWith(args[pos + 1], "--")) stop("Falta valor para ", chave)
  args[pos + 1]
}
permitidos <- c("--entrada", "--horizonte", "--gerar", "--quantidade", "--semente", "--meses-zero")
if (any(startsWith(args, "--") & !args %in% permitidos)) stop("Opção desconhecida.")
entrada <- valor("--entrada", file.path(raiz, "data", "raw", "vendas_simuladas.csv"))
if ("--gerar" %in% args) {
  brutos <- gerar_vendas(as.numeric(valor("--quantidade", "1000")), as.integer(valor("--semente", "42")))
  # A simulação é executada em memória; a base original não é sobrescrita.
} else {
  brutos <- ler_vendas(entrada)
}
resultado <- executar_pipeline(brutos, raiz, as.numeric(valor("--horizonte", "3")),
                               meses_sem_venda_zero = "--meses-zero" %in% args)
cat("Análise concluída:\n", resultado$pasta, "\n", resultado$previsao$motivo, "\n")
