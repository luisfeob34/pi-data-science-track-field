tema_painel <- function() {
  ggplot2::theme_minimal(base_size = 12) + ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", colour = "#153e38"),
    panel.grid.minor = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA))
}

grafico_ranking <- function(x, dimensao = "Produto", metrica = "Faturamento", top = 10L) {
  a <- agregar_vendas(x, dimensao)
  a <- head(a[order(a[[metrica]], decreasing = TRUE), ], top)
  a$Valor <- a[[metrica]]
  ggplot2::ggplot(a, ggplot2::aes(x = reorder(Grupo, Valor), y = Valor)) +
    ggplot2::geom_col(fill = "#1f6c5b", width = .7) + ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = metrica, title = paste(metrica, "por", tolower(dimensao))) + tema_painel()
}

grafico_serie <- function(serie) {
  ggplot2::ggplot(serie, ggplot2::aes(x = Data, y = Faturamento)) +
    ggplot2::geom_line(colour = "#1f6c5b", linewidth = .8, na.rm = TRUE) +
    ggplot2::geom_point(ggplot2::aes(shape = Completo), colour = "#1f6c5b", size = 2.5, na.rm = TRUE) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16), labels = c("Parcial", "Completo")) +
    ggplot2::labs(x = NULL, y = "Faturamento (R$)", shape = "Mês", title = "Evolução mensal") + tema_painel()
}

grafico_distribuicao <- function(x, grupo = "Categoria") {
  a <- data.frame(Grupo = x[[grupo]], Valor = x[["Valor Total"]])
  ggplot2::ggplot(a, ggplot2::aes(x = Grupo, y = Valor)) +
    ggplot2::geom_boxplot(fill = "#c8ded4", colour = "#1f6c5b", outlier.alpha = .4) +
    ggplot2::labs(x = NULL, y = "Valor do pedido (R$)", title = "Distribuição dos pedidos") + tema_painel()
}

grafico_previsao <- function(resultado) {
  p <- grafico_serie(resultado$historico)
  if (!resultado$disponivel) return(p)
  p + ggplot2::geom_ribbon(data = resultado$previsao,
        ggplot2::aes(x = Data, ymin = Inferior, ymax = Superior), inherit.aes = FALSE, fill = "#e5b85c", alpha = .25) +
    ggplot2::geom_line(data = resultado$previsao, ggplot2::aes(x = Data, y = Previsao),
        inherit.aes = FALSE, colour = "#a86411", linewidth = 1) +
    ggplot2::geom_point(data = resultado$previsao, ggplot2::aes(x = Data, y = Previsao),
        inherit.aes = FALSE, colour = "#a86411", size = 2) +
    ggplot2::labs(title = paste("Previsão ·", resultado$modelo), subtitle = "Faixa: intervalo de previsão nominal de 95%")
}

# Widgets nativos evitam dependência da conversão entre versões de ggplot2 e Plotly.
interativo_ranking <- function(x, dimensao, metrica, top) {
  a <- agregar_vendas(x, dimensao)
  a <- head(a[order(a[[metrica]], decreasing = TRUE), ], top)
  a$Valor <- a[[metrica]]
  rotulo <- c(Faturamento = "Total vendido (R$)", Pedidos = "Número de pedidos",
    Itens = "Itens vendidos", Ticket = "Valor médio por pedido (R$)")[[metrica]]
  dica <- if (metrica %in% c("Faturamento", "Ticket")) "%{y}<br>R$ %{x:,.2f}<extra></extra>" else
    "%{y}<br>%{x:,.0f}<extra></extra>"
  p <- plotly::plot_ly(a, x = ~Valor, y = ~Grupo, type = "bar", orientation = "h",
    marker = list(color = "#1f6c5b"), hovertemplate = dica)
  plotly::layout(p, margin = list(l = 160), separators = ",.",
    xaxis = list(title = rotulo, tickformat = ",.0f"), yaxis = list(title = "", categoryorder = "array", categoryarray = rev(a$Grupo)))
}

interativo_serie <- function(serie) {
  p <- plotly::plot_ly(serie, x = ~Data, y = ~Faturamento, type = "scatter", mode = "lines+markers",
    name = "Vendas registradas", line = list(color = "#1f6c5b"),
    marker = list(symbol = ifelse(serie$Completo, "circle", "circle-open")),
    text = ifelse(serie$Completo, "Mês completo", "Mês parcial"),
    hovertemplate = "%{x|%m/%Y}<br>R$ %{y:,.2f}<br>%{text}<extra></extra>")
  plotly::layout(p, separators = ",.", xaxis = list(title = "Mês", tickformat = "%m/%Y"), yaxis = list(title = "Vendas (R$)", tickformat = ",.0f"),
    legend = list(orientation = "h", y = -0.25))
}

interativo_distribuicao <- function(x) {
  a <- data.frame(Grupo = x$Categoria, Valor = x[["Valor Total"]])
  p <- plotly::plot_ly(a, x = ~Grupo, y = ~Valor, type = "box", color = ~Grupo,
    colors = c("#1f6c5b", "#b48136", "#5e85a0"), boxpoints = "outliers")
  plotly::layout(p, showlegend = FALSE, xaxis = list(title = "Categoria"), yaxis = list(title = "Valor do pedido (R$)"))
}

interativo_previsao <- function(resultado) {
  p <- interativo_serie(resultado$historico)
  if (!resultado$disponivel) return(p)
  z <- resultado$previsao
  p <- plotly::add_ribbons(p, data = z, x = ~Data, ymin = ~Inferior, ymax = ~Superior,
    inherit = FALSE, name = "Faixa estimada", fillcolor = "rgba(229,184,92,0.25)",
    line = list(color = "transparent"), hoverinfo = "skip")
  plotly::add_trace(p, data = z, x = ~Data, y = ~Previsao, type = "scatter", mode = "lines+markers",
    inherit = FALSE, name = "Venda estimada", line = list(color = "#a86411"),
    hovertemplate = "%{x|%m/%Y}<br>R$ %{y:,.2f}<extra>Previsão</extra>")
}
