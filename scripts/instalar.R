#!/usr/bin/env Rscript
pacotes <- c("shiny", "ggplot2", "plotly", "DT", "testthat")
faltantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) {
  biblioteca <- Sys.getenv("R_LIBS_USER")
  dir.create(biblioteca, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(biblioteca, .libPaths()))
  install.packages(faltantes, repos = "https://cloud.r-project.org", lib = biblioteca)
}
if (!all(vapply(pacotes, requireNamespace, logical(1), quietly = TRUE))) stop("Há pacotes pendentes.")
print(vapply(pacotes, function(p) as.character(packageVersion(p)), character(1)))
