criar_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(shiny::tags$meta(name = "theme-color", content = "#163e35"),
      shiny::tags$link(rel = "stylesheet", href = "estilo.css"),
      shiny::tags$script(src = "navigation.js", defer = "defer")),
    shiny::tags$a(href = "#aba", class = "pular-conteudo", "Ir para a análise"),
    shiny::div(class = "cabecalho",
      shiny::div(shiny::p(class = "sobretitulo", "TRACK & FIELD / VISÃO DE VENDAS"),
        shiny::h1("Como estão as vendas?"),
        shiny::p("Veja os destaques do período e o que esperar dos próximos meses.")),
      shiny::span(class = "assinatura", "Projeto acadêmico")),
    shiny::sidebarLayout(
      shiny::sidebarPanel(width = 3,
        shiny::tags$details(id = "filtros-painel", open = "open",
        shiny::tags$summary(shiny::span("Filtrar análise"), shiny::span(class = "filtro-ajuda", "Período, categoria, canal e região")),
        shiny::uiOutput("periodo_ui"),
        shiny::selectizeInput("categorias", "Categorias", choices = NULL, multiple = TRUE,
          options = list(placeholder = "Todas as categorias")),
        shiny::selectizeInput("canais", "Canais", choices = NULL, multiple = TRUE,
          options = list(placeholder = "Todos os canais")),
        shiny::selectizeInput("regioes", "Regiões", choices = NULL, multiple = TRUE,
          options = list(placeholder = "Todas as regiões")),
        shiny::actionButton("limpar", "Limpar filtros", class = "btn-block")),
        shiny::hr(),
        shiny::actionButton("salvar", "Salvar esta análise", class = "btn-primary btn-block"),
        shiny::tags$details(class = "detalhes",
        shiny::tags$summary("Trocar dados ou criar demonstração"),
        shiny::textOutput("fonte"),
        shiny::fileInput("arquivo", "Carregar arquivo de vendas", accept = ".csv", buttonLabel = "Escolher", placeholder = "Nenhum arquivo"),
        shiny::helpText("Use as 11 colunas da base de vendas. A importação fica nesta sessão e preserva o arquivo original."),
        shiny::numericInput("quantidade", "Pedidos na simulação", value = 1000, min = 20, max = 100000, step = 100),
        shiny::numericInput("semente", "Código da demonstração (repita para obter os mesmos dados)", value = 42, min = 1, max = 1000000, step = 1),
        shiny::actionButton("gerar", "Criar demonstração", class = "btn-block"))),
      shiny::mainPanel(width = 9,
        shiny::textOutput("contexto", container = function(...) shiny::div(class = "contexto", ...)),
        shiny::uiOutput("filtros_ativos"),
        shiny::uiOutput("kpis"),
        shiny::tabsetPanel(id = "aba", type = "pills",
          shiny::tabPanel("Visão geral", value = "visao",
            shiny::h3("Destaques do período"),
            shiny::uiOutput("destaques"),
            shiny::h3("De onde vêm as vendas?"),
            shiny::fluidRow(
              shiny::column(4, shiny::selectInput("dimensao", "Comparar por", c("Produto", "Categoria", "Canal de Venda", "Região"))),
              shiny::column(4, shiny::selectInput("metrica", "O que mostrar", c("Total vendido (R$)" = "Faturamento", "Número de pedidos" = "Pedidos", "Itens vendidos" = "Itens", "Valor médio por pedido" = "Ticket"))),
              shiny::column(4, shiny::sliderInput("top", "Mostrar os primeiros", min = 3, max = 20, value = 10))),
            plotly::plotlyOutput("ranking", height = "410px"),
            shiny::h3("Como as vendas mudaram mês a mês?"),
            plotly::plotlyOutput("evolucao", height = "330px"),
            shiny::helpText("Passe o mouse para ver valores; arraste para ampliar. Meses parciais aparecem com marcadores abertos.")),
          shiny::tabPanel("O que chama atenção", value = "estatistica",
            shiny::h3("O que os dados indicam?"),
            shiny::p("As respostas abaixo acompanham seus filtros. Elas mostram diferenças e relações, mas não explicam suas causas."),
            shiny::uiOutput("leituras"),
            shiny::h3("Quanto os clientes gastam em cada categoria?"),
            shiny::helpText("A linha dentro da caixa indica o valor central dos pedidos. Caixas mais altas mostram maior variação nos valores."),
            plotly::plotlyOutput("distribuicao", height = "350px"),
            shiny::tags$details(class = "detalhes", shiny::tags$summary("Ver testes e números detalhados"),
            shiny::p("Testes com ajuste de Holm (5%). Pressupõem pedidos independentes. A correção não cobre buscas repetidas por filtros."),
            DT::DTOutput("testes"),
            shiny::downloadButton("baixar_testes", "Baixar testes"),
            shiny::h3("Estatísticas descritivas"), DT::DTOutput("descritivas"))),
          shiny::tabPanel("Próximos meses", value = "previsoes",
            shiny::h3("Quanto podemos esperar em vendas?"),
            shiny::sliderInput("horizonte", "Meses a projetar", min = 1, max = 6, value = 3),
            shiny::uiOutput("nota_previsao"), plotly::plotlyOutput("previsao_grafico", height = "390px"),
            shiny::helpText("A linha verde mostra as vendas registradas. A linha dourada é a estimativa; a faixa ao redor mostra a incerteza. Não é uma garantia de vendas."),
            DT::DTOutput("previsao_tabela"), shiny::downloadButton("baixar_previsao", "Baixar previsão"),
            shiny::tags$details(class = "detalhes", shiny::tags$summary("Como calculamos esta previsão?"),
            shiny::checkboxInput("meses_zero", "Confirmo que meses sem registros representam zero vendas", FALSE),
            shiny::textOutput("metodo_previsao"),
            shiny::p("Cada ajuste vê apenas os meses anteriores ao mês avaliado. Seleção pelo menor erro absoluto médio (MAE); RMSE também é exibido. A validação é de um mês à frente, não de todo o horizonte."),
            DT::DTOutput("validacao"),
            shiny::p("Intervalos nominais de 95% dependem das hipóteses de cada modelo e desconsideram a incerteza de seleção. Valores negativos são limitados a zero. Não se estima sazonalidade anual com este histórico curto."))),
          shiny::tabPanel("Ver pedidos", value = "dados",
            shiny::h3("Pedidos selecionados"), shiny::downloadButton("baixar_dados", "Baixar pedidos"),
            DT::DTOutput("pedidos"),
            shiny::tags$details(class = "detalhes", shiny::tags$summary("Conferir a qualidade dos dados"),
            DT::DTOutput("qualidade"),
            shiny::p("Totais são recalculados com preço, quantidade e desconto. IDs conflitantes são descartados e registrados na auditoria."))))
      )), shiny::div(class = "rodape", "Todos os valores acompanham os filtros escolhidos.")
  )
}

criar_servidor <- function(raiz) {
  force(raiz)
  function(input, output, session) {
    entrada <- file.path(raiz, "data", "raw", "vendas_simuladas.csv")
    inicial <- tryCatch({
      tratado <- tratar_vendas(if (file.exists(entrada)) ler_vendas(entrada) else gerar_vendas())
      if (!nrow(tratado$dados)) stop("O CSV local não contém vendas válidas.")
      tratado
    }, error = identity)
    if (inherits(inicial, "error")) {
      estado_inicial <- tratar_vendas(gerar_vendas())
      fonte_inicial <- "Simulação de demonstração (CSV local não pôde ser lido)"
      shiny::showNotification(conditionMessage(inicial), type = "error", duration = NULL)
    } else {
      estado_inicial <- inicial
      fonte_inicial <- if (file.exists(entrada)) "CSV local: vendas_simuladas.csv" else "Simulação de demonstração · semente 42"
    }
    base <- shiny::reactiveVal(estado_inicial)
    fonte <- shiny::reactiveVal(fonte_inicial)
    output$periodo_ui <- shiny::renderUI({
      datas <- base()$dados[["Data da Venda"]]
      shiny::dateRangeInput("periodo", "Período", start = min(datas), end = max(datas),
        min = min(datas), max = max(datas), language = "pt-BR", format = "dd/mm/yyyy", separator = "até")
    })
    redefinir_filtros <- function() {
      x <- base()$dados
      if (!nrow(x)) return(invisible(NULL))
      shiny::updateDateRangeInput(session, "periodo", start = min(x[["Data da Venda"]]), end = max(x[["Data da Venda"]]),
        min = min(x[["Data da Venda"]]), max = max(x[["Data da Venda"]]))
      shiny::updateSelectizeInput(session, "categorias", choices = sort(unique(x$Categoria)), selected = character())
      shiny::updateSelectizeInput(session, "canais", choices = sort(unique(x[["Canal de Venda"]])), selected = character())
      shiny::updateSelectizeInput(session, "regioes", choices = sort(unique(x$Região)), selected = character())
    }
    shiny::observeEvent(base(), redefinir_filtros())
    shiny::observeEvent(input$limpar, redefinir_filtros())
    aceitar_base <- function(brutos, descricao) {
      novo <- tratar_vendas(brutos)
      if (!nrow(novo$dados)) stop("O arquivo não contém pedidos válidos. A base anterior foi mantida.")
      base(novo)
      fonte(descricao)
    }
    shiny::observeEvent(input$arquivo, {
      tryCatch({
        if (input$arquivo$size > 20 * 1024^2) stop("O limite do CSV é de 20 MB.")
        aceitar_base(ler_vendas(input$arquivo$datapath), paste("CSV importado:", input$arquivo$name))
      }, error = function(e) shiny::showNotification(conditionMessage(e), type = "error", duration = 10))
    })
    shiny::observeEvent(input$gerar, {
      tryCatch({
        if (is.null(input$quantidade) || input$quantidade < 20 || input$quantidade > 100000)
          stop("Escolha entre 20 e 100.000 pedidos.")
        if (is.null(input$semente) || !is.finite(input$semente) || input$semente < 1 || input$semente > 1000000 || input$semente != floor(input$semente))
          stop("Escolha uma semente inteira entre 1 e 1.000.000.")
        aceitar_base(gerar_vendas(input$quantidade, input$semente), paste("Simulação em R · semente", input$semente))
      }, error = function(e) shiny::showNotification(conditionMessage(e), type = "error"))
    })
    dados <- shiny::reactive({
      x <- filtrar_vendas(base()$dados, input$periodo, input$categorias, input$canais, input$regioes)
      shiny::validate(shiny::need(nrow(x) > 0, "Nenhum pedido neste recorte. Ajuste os filtros."))
      x
    })
    cobertura <- shiny::reactive({
      intervalo <- range(base()$dados[["Data da Venda"]])
      if (length(input$periodo) == 2 && all(!is.na(input$periodo)))
        intervalo <- c(max(intervalo[1], as.Date(input$periodo[1])), min(intervalo[2], as.Date(input$periodo[2])))
      intervalo
    })
    serie <- shiny::reactive(serie_mensal(dados(), cobertura(), isTRUE(input$meses_zero)))
    testes <- shiny::reactive(testes_estatisticos(dados()))
    previsao <- shiny::reactive(prever_vendas(serie(), if (is.null(input$horizonte)) 3 else input$horizonte))
    tabela <- function(x, pagina = 8) DT::datatable(x, rownames = FALSE, escape = TRUE,
      options = list(pageLength = pagina, scrollX = TRUE, language = list(
        search = "Buscar:", lengthMenu = "Mostrar _MENU_ linhas", info = "_START_–_END_ de _TOTAL_",
        emptyTable = "Sem dados disponíveis", paginate = list(previous = "Anterior", "next" = "Próxima"))))
    moeda <- function(x) paste0("R$ ", formatC(x, format = "f", digits = 2, big.mark = ".", decimal.mark = ","))
    output$fonte <- shiny::renderText(fonte())
    output$contexto <- shiny::renderText(if (startsWith(fonte(), "CSV importado:"))
      "Análise do arquivo enviado por você · os filtros se aplicam a todas as abas." else
      "Demonstração com vendas simuladas · não representa resultados reais da empresa.")
    output$filtros_ativos <- shiny::renderUI({
      periodo <- input$periodo
      if (length(periodo) != 2 || anyNA(periodo)) periodo <- range(base()$dados[["Data da Venda"]])
      etiquetas <- paste(format(as.Date(periodo[1]), "%d/%m/%Y"), "—", format(as.Date(periodo[2]), "%d/%m/%Y"))
      for (filtro in list(list("Categorias", input$categorias), list("Canais", input$canais), list("Regiões", input$regioes))) {
        if (length(filtro[[2]])) etiquetas <- c(etiquetas, paste0(filtro[[1]], ": ", paste(filtro[[2]], collapse = ", ")))
      }
      shiny::div(class = "filtros-ativos", `aria-label` = "Filtros aplicados",
        lapply(etiquetas, function(texto) shiny::span(texto)))
    })
    output$kpis <- shiny::renderUI({
      x <- dados()
      valores <- c(moeda(sum(x[["Valor Total"]])), format(nrow(x), big.mark = ".", decimal.mark = ","),
                   moeda(mean(x[["Valor Total"]])), format(sum(x$Quantidade), big.mark = ".", decimal.mark = ","))
      nomes <- c("Total vendido", "Pedidos realizados", "Valor médio por pedido", "Itens vendidos")
      shiny::div(class = "kpis", lapply(seq_along(nomes), function(i)
        shiny::div(class = "kpi", shiny::span(nomes[i]), shiny::strong(valores[i]))))
    })
    output$destaques <- shiny::renderUI({
      x <- dados()
      produto <- agregar_vendas(x, "Produto")
      canal <- agregar_vendas(x, "Canal de Venda")
      total <- sum(x[["Valor Total"]])
      if (total <= 0) return(shiny::p("Os pedidos selecionados não geraram faturamento."))
      cartao <- function(rotulo, titulo, texto) shiny::div(class = "destaque",
        shiny::span(class = "rotulo", rotulo), shiny::strong(titulo), shiny::p(texto))
      participacao <- function(v) paste0(formatC(100 * v / total, digits = 1, format = "f", decimal.mark = ","), "%")
      lider <- function(a) {
        empatados <- a$Grupo[abs(a$Faturamento - a$Faturamento[1]) < .005]
        if (length(empatados) > 1) paste(length(empatados), "empatados na liderança") else a$Grupo[1]
      }
      mensal <- serie()
      mensal <- mensal[mensal$Completo & is.finite(mensal$Faturamento), ]
      melhor <- if (nrow(mensal)) mensal[which.max(mensal$Faturamento), ] else NULL
      shiny::div(class = "destaques",
        cartao("Produto com mais receita", lider(produto),
          paste(moeda(produto$Faturamento[1]), "·", participacao(produto$Faturamento[1]), "do total por produto líder.")),
        cartao("Canal com mais receita", lider(canal),
          paste(moeda(canal$Faturamento[1]), "·", participacao(canal$Faturamento[1]), "do total por canal líder.")),
        if (!is.null(melhor)) cartao("Mês completo com mais vendas",
          paste(meses_pt[as.integer(format(melhor$Data, "%m"))], format(melhor$Data, "%Y")),
          paste(moeda(melhor$Faturamento), "em vendas. Consulte a evolução abaixo.")) else
          cartao("Comparação entre meses", "Período ainda parcial", "Amplie o período para comparar meses completos."))
    })
    output$leituras <- shiny::renderUI({
      t <- testes()
      perguntas <- c("O gasto por pedido muda entre categorias?", "O gasto por pedido muda entre canais?",
        "O gasto por pedido muda entre regiões?", "Desconto e valor do pedido estão relacionados?",
        "A distribuição de categorias muda conforme o canal?")
      shiny::div(class = "leituras", lapply(seq_len(nrow(t)), function(i) {
        p <- t$p_ajustado[i]
        titulo <- if (is.na(p)) "Precisamos de mais variedade ou mais pedidos" else if (p < .05)
          "Os dados indicam uma diferença" else "Não há evidência suficiente de diferença"
        if (i >= 4 && !is.na(p)) titulo <- if (p < .05) "Os dados indicam uma relação" else "Não há evidência suficiente de relação"
        complemento <- if (is.na(p)) "Amplie os filtros para permitir esta comparação." else
          if (i == 4) "O desconto já entra no cálculo do valor. Essa relação não prova aumento de vendas." else
          if (p < .05) "Vale investigar os grupos no gráfico. O resultado não mostra a causa da diferença." else
            "Isso não significa que os grupos sejam iguais; a base pode não mostrar uma diferença clara."
        shiny::div(class = "leitura", shiny::h4(perguntas[i]), shiny::strong(titulo), shiny::p(complemento))
      }))
    })
    output$ranking <- plotly::renderPlotly({
      shiny::req(input$dimensao, input$metrica, input$top)
      interativo_ranking(dados(), input$dimensao, input$metrica, input$top)
    })
    output$evolucao <- plotly::renderPlotly(interativo_serie(serie()))
    output$distribuicao <- plotly::renderPlotly(interativo_distribuicao(dados()))
    output$testes <- DT::renderDT(tabela(testes()))
    output$descritivas <- DT::renderDT(tabela(descrever_vendas(dados())))
    output$qualidade <- DT::renderDT(tabela(base()$auditoria, 10))
    output$pedidos <- DT::renderDT(tabela(dados(), 10))
    output$nota_previsao <- shiny::renderUI({
      p <- previsao()
      if (!p$disponivel) return(shiny::div(class = "aviso", p$motivo))
      primeiro <- p$previsao[1, ]
      shiny::div(class = "resumo-previsao", shiny::span("Estimativa para o próximo mês completo após o histórico usado"),
        shiny::strong(moeda(primeiro$Previsao)),
        shiny::p(paste(format(primeiro$Data, "%m/%Y"), "· Faixa estimada:", moeda(primeiro$Inferior), "a", moeda(primeiro$Superior))),
        shiny::p("Estimativa baseada nas vendas anteriores. Quanto maior a faixa, maior a incerteza."))
    })
    output$metodo_previsao <- shiny::renderText(previsao()$motivo)
    output$previsao_grafico <- plotly::renderPlotly(interativo_previsao(previsao()))
    output$previsao_tabela <- DT::renderDT({
      shiny::validate(shiny::need(previsao()$disponivel, previsao()$motivo))
      p <- previsao()$previsao
      tabela(data.frame(Mês = format(p$Data, "%m/%Y"), "Venda estimada" = moeda(p$Previsao),
        "Faixa inferior" = moeda(p$Inferior), "Faixa superior" = moeda(p$Superior), check.names = FALSE))
    })
    output$validacao <- DT::renderDT({
      shiny::validate(shiny::need(previsao()$disponivel, previsao()$motivo))
      tabela(previsao()$validacao)
    })
    output$baixar_dados <- shiny::downloadHandler(filename = "vendas_tratadas.csv",
      content = function(file) gravar_csv(dados(), file))
    output$baixar_testes <- shiny::downloadHandler(filename = "testes_estatisticos.csv",
      content = function(file) gravar_csv(testes(), file))
    output$baixar_previsao <- shiny::downloadHandler(filename = "previsao.csv", content = function(file) {
      shiny::req(previsao()$disponivel)
      gravar_csv(previsao()$previsao, file)
    })
    shiny::observeEvent(input$salvar, {
      shiny::req(dados())
      tryCatch(shiny::withProgress(message = "Salvando análise", value = .2, {
        resultado <- executar_pipeline(dados(), raiz, if (is.null(input$horizonte)) 3 else input$horizonte,
                                        cobertura(), isTRUE(input$meses_zero))
        shiny::showNotification(paste("Análise salva em", resultado$pasta), type = "message", duration = 12)
      }), error = function(e) shiny::showNotification(conditionMessage(e), type = "error"))
    })
  }
}
