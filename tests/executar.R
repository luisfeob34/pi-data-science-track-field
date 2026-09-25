#!/usr/bin/env Rscript
arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), mustWork = TRUE)
testthat::test_dir(file.path(raiz, "tests", "testthat"), reporter = "summary", stop_on_failure = TRUE)
