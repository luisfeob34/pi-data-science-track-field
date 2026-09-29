# Dois lotes controlados com defeitos para a verificacao de integracao Spark/R.
source("R/dados.R", encoding="UTF-8")
pasta <- "results/bigdata/fixtures"
dir.create(pasta, recursive=TRUE,showWarnings=FALSE)
a <- gerar_vendas(20,101); a[["ID Execucao"]] <- "teste-a"
b <- gerar_vendas(20,202); b[["ID Execucao"]] <- "teste-b"
a$Quantidade[2] <- 0
a[["Data da Venda"]][3] <- "2026-02-30"
a <- rbind(a,a[4,])
conflito <- a[5,]; conflito$Produto <- "Conflito"
a <- rbind(a,conflito)
for (item in list(list("a",a),list("b",b))) {
  dir.create(file.path(pasta,item[[1]]),showWarnings=FALSE)
  write.csv(item[[2]],file.path(pasta,item[[1]],"vendas.csv"),row.names=FALSE,fileEncoding="UTF-8")
}
referencia <- tratar_vendas(rbind(a,b))$dados
stopifnot(nrow(referencia)==37)
write.csv(referencia,file.path(pasta,"esperado.csv"),row.names=FALSE,fileEncoding="UTF-8")
