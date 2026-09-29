raiz_teste <- normalizePath(file.path("..", ".."), mustWork = TRUE)
for (modulo in c("dados", "lotes", "estatistica", "previsao", "visualizacao", "pipeline", "painel"))
  source(file.path(raiz_teste, "R", paste0(modulo, ".R")), encoding = "UTF-8")
