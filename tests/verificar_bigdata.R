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
# Exportação do modelo estrela para a carga do Data Warehouse PostgreSQL.
dw <- function(nome) read.csv(file.path(base$pasta, "dw", paste0(nome, ".csv")), colClasses = "character")
fato <- dw("fato_vendas")
stopifnot(nrow(fato) == 37, !anyDuplicated(fato[c("execucao", "pedido")]),
  all(c("cliente", "id_produto", "id_canal", "id_regiao", "id_data") %in% names(fato)),
  all(fato$id_produto %in% dw("dim_produto")$id_produto), all(fato$id_canal %in% dw("dim_canal")$id_canal),
  all(fato$id_regiao %in% dw("dim_regiao")$id_regiao), all(fato$id_data %in% dw("dim_data")$id_data),
  abs(sum(as.numeric(fato$valor_total)) - resumo$Faturamento) < .01)
cat("Integracao validada: 42 recebidos, 1 duplicata, 4 rejeitados, 37 aceitos; todas as linhas conferem com R.\n")
cat("Exportacao do Data Warehouse validada: fato com 37 vendas e chaves presentes nas 4 dimensoes.\n")
