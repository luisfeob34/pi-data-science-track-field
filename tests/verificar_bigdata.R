# Uso: Rscript tests/verificar_bigdata.R pasta_isolada
source("R/dados.R", encoding = "UTF-8")
source("R/lotes.R", encoding = "UTF-8")
args <- commandArgs(TRUE)
stopifnot(length(args) == 1)
base <- ultima_base_spark(args[1])
stopifnot(!is.null(base))
resumo <- read.csv(file.path(base$pasta, "resumo.csv"))
stopifnot(resumo$Recebidos == 42, resumo$Duplicados == 1,
          resumo$Rejeitados == 4, resumo$Aceitos == 37)
esperado <- tratar_vendas(ler_vendas("results/bigdata/fixtures/esperado.csv"))$dados
obtido <- ler_vendas(base$arquivo)
ordenar <- function(x) {
  x <- x[order(x[["ID Execucao"]], x[["ID Pedido"]]), c(colunas_vendas, "ID Execucao")]
  x[["Data da Venda"]] <- as.character(x[["Data da Venda"]])
  for (nm in c("Preço Unitário", "Quantidade", "Desconto", "Valor Total"))
    x[[nm]] <- as.numeric(x[[nm]])
  rownames(x) <- NULL
  x
}
stopifnot(isTRUE(all.equal(ordenar(obtido), ordenar(esperado), check.attributes = FALSE)))
stopifnot(abs(sum(as.numeric(obtido[["Valor Total"]])) - resumo$Faturamento) < .01)
stopifnot(file.exists(file.path(readLines(file.path(base$pasta, "analise_r.txt")), "relatorio.md")))
cat("Integracao validada: 42 recebidos, 1 duplicata, 4 rejeitados, 37 aceitos; todas as linhas conferem com R.\n")
