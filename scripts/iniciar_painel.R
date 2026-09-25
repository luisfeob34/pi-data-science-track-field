#!/usr/bin/env Rscript
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), mustWork = TRUE)
args <- commandArgs(trailingOnly = TRUE)
porta <- if (length(args)) suppressWarnings(as.integer(args[1])) else 8080L
if (is.na(porta) || porta < 1024 || porta > 65535) stop("Porta deve estar entre 1024 e 65535.")
pacotes <- c("shiny", "ggplot2", "plotly", "DT")
if (!all(vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)))
  stop("Instale as dependências: Rscript scripts/instalar.R")
shiny::runApp(file.path(raiz, "painel"), host = Sys.getenv("SHINY_HOST", "127.0.0.1"),
              port = porta, launch.browser = FALSE)
