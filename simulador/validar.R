#!/usr/bin/env Rscript
argumentos <- commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1) stop("Informe a pasta de dados da VM.")
arquivos <- list.files(argumentos[1], pattern = "^vendas[.]csv$", recursive = TRUE, full.names = TRUE)
if (length(arquivos) < 2) stop("Execute o simulador pelo menos duas vezes.")
ids <- character()
for (arquivo in arquivos) {
  dados <- read.csv(arquivo, check.names = FALSE, fileEncoding = "UTF-8")
  obrigatorias <- c("ID Pedido", "Data da Venda", "Produto", "Quantidade", "Valor Total", "ID Execucao", "Gerado em UTC")
  stopifnot(all(obrigatorias %in% names(dados)), nrow(dados) >= 10,
    !anyNA(as.Date(dados[["Data da Venda"]])), all(dados$Quantidade > 0),
    all(dados[["Valor Total"]] > 0), !anyDuplicated(dados[["ID Pedido"]]))
  ids <- c(ids, paste(dados[["ID Execucao"]], dados[["ID Pedido"]], sep = ":"))
  cat(basename(dirname(arquivo)), ":", nrow(dados), "registros validos\n")
}
stopifnot(!anyDuplicated(ids))
cat("OK:", length(arquivos), "arquivos;", length(ids), "registros; identificadores compostos unicos.\n")
