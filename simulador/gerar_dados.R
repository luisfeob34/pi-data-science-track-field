#!/usr/bin/env Rscript
# Uso: Rscript simulador/gerar_dados.R [diretorio_saida] [quantidade] [semente]
argumentos <- commandArgs(trailingOnly = TRUE)
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- dirname(dirname(normalizePath(arquivo)))
source(file.path(raiz, "R", "dados.R"), encoding = "UTF-8")
destino <- if (length(argumentos) >= 1) argumentos[1] else file.path(raiz, "simulador", "saidas")
n <- if (length(argumentos) >= 2) suppressWarnings(as.numeric(argumentos[2])) else 1000
semente <- if (length(argumentos) >= 3) suppressWarnings(as.numeric(argumentos[3])) else 42
if (length(argumentos) > 3 || !is.finite(n) || n < 10 || n > 1e6 || n != floor(n))
  stop("Informe diretorio, quantidade inteira entre 10 e 1000000 e semente inteira.")
if (!is.finite(semente) || semente < 0 || semente > .Machine$integer.max || semente != floor(semente))
  stop("Semente deve ser um inteiro entre 0 e 2147483647.")
dir.create(destino, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(destino) || file.access(destino, 2) != 0)
  stop("Diretorio de saida inexistente ou sem permissao de escrita.")
# mkdir e atomico: nunca reutiliza uma pasta, mesmo em execucoes concorrentes.
repeat {
  execucao <- basename(tempfile(paste0("exec-", format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "-")))
  pasta <- file.path(destino, execucao)
  if (dir.create(pasta, showWarnings = FALSE)) break
  if (file.access(destino, 2) != 0) stop("Diretorio de saida sem permissao de escrita.")
}
dados <- gerar_vendas(n, semente)
dados[["ID Execucao"]] <- execucao
dados[["Gerado em UTC"]] <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
write.csv(dados, file.path(pasta, "vendas.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(paste("execucao:", execucao), paste("registros:", n), paste("semente:", semente),
  "Origem: dados sinteticos; nao representam vendas reais.", R.version.string), file.path(pasta, "metadados.txt"))
cat(normalizePath(file.path(pasta, "vendas.csv")), "\n")
