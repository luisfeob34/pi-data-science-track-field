#!/usr/bin/env Rscript
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- dirname(dirname(normalizePath(arquivo)))
source(file.path(raiz, "R", "dados.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "lotes.R"), encoding = "UTF-8")
args <- commandArgs(TRUE)
if (length(args) != 2) stop("Uso: Rscript scripts/ingerir_lotes.R origem lake")
ingerir_lotes(args[1], args[2])
