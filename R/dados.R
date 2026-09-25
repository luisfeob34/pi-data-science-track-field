# Regras de dados compartilhadas pelo pipeline e pelo Shiny. UTF-8.
colunas_vendas <- c("ID Pedido", "Data da Venda", "Cliente", "Produto", "Categoria",
                    "Canal de Venda", "Região", "Preço Unitário", "Quantidade", "Desconto", "Valor Total")
meses_pt <- c("Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho",
              "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro")

ler_vendas <- function(caminho) {
  if (!file.exists(caminho)) stop("CSV de vendas não encontrado: ", caminho)
  x <- read.csv(caminho, check.names = FALSE, colClasses = "character",
                fileEncoding = "UTF-8-BOM", na.strings = c("", "NA"))
  if (anyDuplicated(names(x))) stop("O CSV contém nomes de colunas repetidos.")
  x
}

tratar_vendas <- function(x) {
  faltantes <- setdiff(colunas_vendas, names(x))
  if (length(faltantes)) stop("Colunas obrigatórias ausentes: ", paste(faltantes, collapse = ", "))
  x <- x[, colunas_vendas, drop = FALSE]
  recebidos <- nrow(x)
  for (nm in names(x)) x[[nm]] <- trimws(as.character(x[[nm]]))
  duplicados <- sum(duplicated(x))
  x <- unique(x)
  descartar <- function(invalidos) {
    n <- sum(invalidos)
    x <<- x[!invalidos, , drop = FALSE]
    n
  }
  ausentes <- descartar(!complete.cases(x) | apply(x == "", 1, any))
  datas <- suppressWarnings(as.Date(x[["Data da Venda"]], format = "%Y-%m-%d"))
  ruins <- is.na(datas) | !grepl("^\\d{4}-\\d{2}-\\d{2}$", x[["Data da Venda"]])
  ruins <- ruins | (!is.na(datas) & format(datas, "%Y-%m-%d") != x[["Data da Venda"]])
  datas_invalidas <- descartar(ruins)
  x[["Data da Venda"]] <- as.Date(x[["Data da Venda"]], format = "%Y-%m-%d")
  numericas <- c("Preço Unitário", "Quantidade", "Desconto", "Valor Total")
  for (nm in numericas) x[[nm]] <- suppressWarnings(as.numeric(x[[nm]]))
  numeros_invalidos <- descartar(!Reduce(`&`, lapply(x[numericas], is.finite)))
  limites_invalidos <- descartar(x[["Preço Unitário"]] <= 0 | x$Quantidade <= 0 |
    x$Quantidade != floor(x$Quantidade) | x$Desconto < 0 | x$Desconto > 1 | x[["Valor Total"]] < 0)
  # IDs divergentes são ambíguos: não escolher arbitrariamente um dos pedidos.
  ids_conflitantes <- descartar(duplicated(x[["ID Pedido"]]) | duplicated(x[["ID Pedido"]], fromLast = TRUE))
  x[["Valor Bruto"]] <- round(x[["Preço Unitário"]] * x$Quantidade, 2)
  x[["Valor Desconto"]] <- round(x[["Valor Bruto"]] * x$Desconto, 2)
  total <- round(x[["Valor Bruto"]] - x[["Valor Desconto"]], 2)
  totais_corrigidos <- sum(abs(x[["Valor Total"]] - total) > 0.011)
  x[["Valor Total"]] <- total
  x[["Possui Desconto"]] <- ifelse(x$Desconto > 0, "Sim", "Não")
  x[["Desconto Percentual"]] <- 100 * x$Desconto
  x[["Faixa de Desconto"]] <- ifelse(x$Desconto == 0, "Sem desconto", ifelse(x$Desconto <= .05,
    "Até 5%", ifelse(x$Desconto <= .10, "De 6% a 10%", "Acima de 10%")))
  x[["Valor por Item"]] <- round(x[["Valor Total"]] / x$Quantidade, 2)
  x[["Porte do Pedido"]] <- ifelse(x$Quantidade == 1, "Unitário", ifelse(x$Quantidade <= 3, "Pequeno", "Grande"))
  x[["Faixa de Valor"]] <- as.character(cut(total, c(-Inf, 250, 500, 1000, Inf), right = FALSE,
    labels = c("Até R$ 249,99", "R$ 250 a R$ 499,99", "R$ 500 a R$ 999,99", "R$ 1.000 ou mais")))
  x$Ano <- as.integer(format(x[["Data da Venda"]], "%Y"))
  x[["Número do Mês"]] <- as.integer(format(x[["Data da Venda"]], "%m"))
  x$Mês <- meses_pt[x[["Número do Mês"]]]
  x$Periodo <- format(x[["Data da Venda"]], "%Y-%m")
  x$Trimestre <- if (nrow(x)) paste0(x$Ano, "-T", ceiling(x[["Número do Mês"]] / 3)) else character()
  dias <- c("Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado")
  x[["Dia da Semana"]] <- dias[as.integer(format(x[["Data da Venda"]], "%w")) + 1L]
  x <- x[order(x[["Data da Venda"]], x[["ID Pedido"]]), , drop = FALSE]
  rownames(x) <- NULL
  auditoria <- data.frame(Etapa = c("Recebidos", "Duplicados exatos removidos", "Ausentes removidos",
    "Datas inválidas removidas", "Números inválidos removidos", "Fora dos limites removidos",
    "Registros com ID conflitante removidos", "Aceitos", "Totais recalculados com diferença > R$ 0,01"),
    Registros = c(recebidos, duplicados, ausentes, datas_invalidas, numeros_invalidos,
                  limites_invalidos, ids_conflitantes, nrow(x), totais_corrigidos))
  list(dados = x, auditoria = auditoria)
}

agregar_vendas <- function(x, coluna) {
  vazio <- data.frame(Grupo = character(), Pedidos = integer(), Itens = numeric(),
                      Faturamento = numeric(), Ticket = numeric())
  if (!nrow(x)) return(vazio)
  grupos <- split(seq_len(nrow(x)), x[[coluna]])
  resultado <- do.call(rbind, lapply(names(grupos), function(nome) {
    z <- x[grupos[[nome]], , drop = FALSE]
    data.frame(Grupo = nome, Pedidos = nrow(z), Itens = sum(z$Quantidade),
      Faturamento = sum(z[["Valor Total"]]), Ticket = mean(z[["Valor Total"]]))
  }))
  resultado <- resultado[order(resultado$Faturamento, decreasing = TRUE), ]
  rownames(resultado) <- NULL
  resultado
}

filtrar_vendas <- function(x, periodo = NULL, categorias = NULL, canais = NULL, regioes = NULL) {
  manter <- rep(TRUE, nrow(x))
  if (length(periodo) == 2 && all(!is.na(periodo)))
    manter <- manter & x[["Data da Venda"]] >= as.Date(periodo[1]) & x[["Data da Venda"]] <= as.Date(periodo[2])
  for (item in list(list("Categoria", categorias), list("Canal de Venda", canais), list("Região", regioes)))
    if (length(item[[2]])) manter <- manter & x[[item[[1]]]] %in% item[[2]]
  x[manter, , drop = FALSE]
}

com_semente <- function(semente, funcao) {
  tinha <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (tinha) anterior <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (tinha) assign(".Random.seed", anterior, envir = .GlobalEnv) else
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv))
  set.seed(semente)
  funcao()
}

gerar_vendas <- function(n = 1000L, semente = 42L) {
  if (length(n) != 1 || !is.finite(n) || n < 1 || n != floor(n) || n > 1000000)
    stop("Quantidade deve ser um inteiro entre 1 e 1.000.000.")
  com_semente(semente, function() {
    produtos <- c("Camiseta Performance", "Shorts Running", "Legging Compressão", "Tênis Running",
      "Tênis Training", "Top Esportivo", "Jaqueta Corta-Vento", "Meia Esportiva", "Mochila Esportiva", "Garrafa Térmica")
    categorias <- c("Vestuário", "Vestuário", "Vestuário", "Calçados", "Calçados", "Vestuário", "Vestuário", "Acessórios", "Acessórios", "Acessórios")
    precos <- c(149.9, 129.9, 199.9, 499.9, 449.9, 119.9, 299.9, 49.9, 249.9, 99.9)
    ids <- sample(seq_along(produtos), n, replace = TRUE)
    datas <- as.Date("2026-01-01") + sample(0:364, n, replace = TRUE)
    quantidade <- sample(1:5, n, replace = TRUE)
    desconto <- sample(c(0, .05, .10, .15), n, replace = TRUE)
    bruto <- round(precos[ids] * quantidade, 2)
    x <- data.frame(seq_len(n), as.character(datas), sprintf("Cliente_%05d", seq_len(n)),
      produtos[ids], categorias[ids], sample(c("Loja Física", "E-commerce", "Marketplace"), n, TRUE),
      sample(c("Norte", "Nordeste", "Centro-Oeste", "Sudeste", "Sul"), n, TRUE),
      precos[ids], quantidade, desconto, round(bruto - round(bruto * desconto, 2), 2), check.names = FALSE)
    names(x) <- colunas_vendas
    x
  })
}
