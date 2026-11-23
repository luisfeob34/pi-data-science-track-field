# Leitura do Data Warehouse PostgreSQL (VM de exibição) pelo painel. UTF-8.
# A conexão usa o socket local e a autenticação do sistema (peer): não há senha no código.

colunas_vw_vendas <- c("pedido", "data_venda", "cliente", "produto", "categoria", "canal", "regiao",
  "preco", "quantidade", "desconto", "valor_total", "execucao")

consulta_vendas_dw <- paste("SELECT", paste(colunas_vw_vendas, collapse = ", "),
  "FROM dw.vw_vendas ORDER BY execucao, pedido")

# Converte o resultado da visão dw.vw_vendas para as colunas de entrada de tratar_vendas.
# Tudo vira texto, como em um CSV, para passar pelas mesmas regras de qualidade do painel.
vendas_do_dw <- function(x) {
  faltantes <- setdiff(colunas_vw_vendas, names(x))
  if (length(faltantes)) stop("Visão do DW sem as colunas: ", paste(faltantes, collapse = ", "))
  x <- x[colunas_vw_vendas]
  # format() evita notação científica (as.character(1e5) daria "1e+05").
  x[] <- lapply(x, function(v) {
    if (inherits(v, "Date")) format(v, "%Y-%m-%d")
    else if (is.double(v)) format(v, scientific = FALSE, trim = TRUE, digits = 15)
    else as.character(v)
  })
  names(x) <- c(colunas_vendas, "ID Execucao")
  rownames(x) <- NULL
  x
}

# Lê a última carga do Data Warehouse. nome: banco PostgreSQL (variável PI_DW_NOME no serviço).
ler_dw <- function(nome = Sys.getenv("PI_DW_NOME")) {
  if (!nzchar(nome)) stop("Data Warehouse não configurado (defina PI_DW_NOME).")
  for (pacote in c("DBI", "RPostgres"))
    if (!requireNamespace(pacote, quietly = TRUE)) stop("Pacote R ausente para o Data Warehouse: ", pacote)
  con <- DBI::dbConnect(RPostgres::Postgres(), dbname = nome)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  carga <- DBI::dbGetQuery(con,
    "SELECT execucao_spark, carregado_em, vendas FROM dw.cargas ORDER BY id DESC LIMIT 1")
  if (!nrow(carga))
    stop("O Data Warehouse ainda não recebeu carga. No host, execute: bash infraestrutura/p1.sh publicar")
  list(dados = vendas_do_dw(DBI::dbGetQuery(con, consulta_vendas_dw)), carga = carga)
}

descrever_carga_dw <- function(carga) {
  if (is.null(carga) || !nrow(carga)) return("Data Warehouse sem carga registrada.")
  paste0("Última carga do Data Warehouse: ", carga$execucao_spark[1], " · ",
    format(carga$vendas[1], big.mark = "."), " vendas · ",
    format(as.POSIXct(carga$carregado_em[1]), "%d/%m/%Y %H:%M"))
}
