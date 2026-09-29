# Ingestao por arquivo com rastreabilidade e deduplicacao por conteudo.
ingerir_lotes <- function(origem, lake) {
  arquivos <- if (dir.exists(origem)) list.files(origem, pattern = "^vendas[.]csv$",
    recursive = TRUE, full.names = TRUE) else origem
  if (!length(arquivos) || any(!file.exists(arquivos))) stop("Nenhum vendas.csv encontrado na origem.")
  bronze <- file.path(lake, "bronze")
  dir.create(bronze, recursive = TRUE, showWarnings = FALSE)
  novos <- 0L
  for (arquivo in sort(arquivos)) {
    hash <- unname(tools::md5sum(arquivo))
    destino <- file.path(bronze, hash)
    if (file.exists(file.path(destino, "CONCLUIDO"))) next
    if (dir.exists(destino)) stop("Lote incompleto: ", destino)
    x <- ler_vendas(arquivo)
    if (!all(colunas_vendas %in% names(x))) stop("Colunas ausentes em ", arquivo)
    if (!"ID Execucao" %in% names(x)) x[["ID Execucao"]] <- rep(paste0("arquivo-", hash), nrow(x))
    x <- x[c(colunas_vendas, "ID Execucao")]
    tmp <- tempfile(".ingestao-", tmpdir = bronze)
    dir.create(tmp)
    if (!file.copy(arquivo, file.path(tmp, "original.csv"))) stop("Falha ao preservar original.")
    if (unname(tools::md5sum(file.path(tmp, "original.csv"))) != hash) stop("Origem mudou durante a ingestao.")
    write.csv(x, file.path(tmp, "entrada.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
    write.csv(data.frame(Origem = normalizePath(arquivo), MD5 = hash, Registros = nrow(x),
      Ingerido_UTC = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
      file.path(tmp, "manifesto.csv"), row.names = FALSE)
    writeLines("ok", file.path(tmp, "CONCLUIDO"))
    if (!file.rename(tmp, destino)) stop("Falha ao publicar lote.")
    novos <- novos + 1L
  }
  cat("Lotes novos:", novos, "\n")
  invisible(novos)
}

ultima_base_spark <- function(raiz) {
  ponteiro <- file.path(raiz, "results", "bigdata", "ultima.txt")
  if (!file.exists(ponteiro)) return(NULL)
  id <- readLines(ponteiro, warn = FALSE, n = 1)
  if (length(id) != 1 || !grepl("^exec-[A-Za-z0-9-]+$", id)) stop("Ponteiro Spark invalido.")
  pasta <- file.path(raiz, "results", "bigdata", id)
  csv <- file.path(pasta, "vendas_painel.csv")
  if (!file.exists(file.path(pasta, "CONCLUIDO"))) stop("Execucao Spark incompleta.")
  if (!file.exists(csv)) stop("Base Spark excede o limite do painel local. Consulte os indicadores completos da execucao.")
  list(arquivo = csv, id = id, pasta = pasta)
}
