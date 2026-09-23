const SVG = "http://www.w3.org/2000/svg";
const app = document.getElementById("app");
const statusEl = document.getElementById("status");
const dicaEl = document.getElementById("dica");
const pagina = document.body.dataset.pagina;
const IDS_PEDIDO = ["distribuicao_valor", "faixa_desconto", "quantidade_valor", "boxplot_valor", "correlacao"];

const estado = {
  dados: null,
  versao: "",
  slide: Number(sessionStorage.getItem("slide") || 0),
  graficoId: document.body.dataset.grafico || "faturamento_produto",
  metrica: "Faturamento",
  porValor: false,
  top: 0,
  participacao: false,
  busca: "",
  selecionado: null,
  compararCom: "",
  gerando: false,
  formularioAberto: false,
  fonte: "faturamento_produto",
  itemA: "",
  itemB: "",
  atividades: null,
  notasTimer: 0,
};

function el(tag, attrs, texto) {
  const node = document.createElement(tag);
  Object.entries(attrs || {}).forEach(([chave, valor]) => {
    if (chave === "class") node.className = valor;
    else if (chave.startsWith("on") && typeof valor === "function") node.addEventListener(chave.slice(2).toLowerCase(), valor);
    else node.setAttribute(chave, valor);
  });
  if (texto != null) node.textContent = texto;
  return node;
}

function dinheiro(nome) {
  return /faturamento|ticket|valor|preço|desconto/i.test(nome);
}

function formato(nome, valor) {
  if (nome === "coef") {
    return Number(valor).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  if (dinheiro(nome)) {
    return Number(valor).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }
  return Number(valor).toLocaleString("pt-BR", { maximumFractionDigits: 2 });
}

function graficoPorId(id) {
  return estado.dados.graficos.find((item) => item.id === id) || null;
}

function mostrarDica(evento, texto) {
  dicaEl.hidden = false;
  dicaEl.textContent = texto;
  dicaEl.style.left = `${evento.clientX + 12}px`;
  dicaEl.style.top = `${evento.clientY + 12}px`;
}

function esconderDica() {
  dicaEl.hidden = true;
}

function svgEl(nome, atributos) {
  const node = document.createElementNS(SVG, nome);
  Object.entries(atributos).forEach(([chave, valor]) => node.setAttribute(chave, String(valor)));
  return node;
}

function textoSvg(x, y, conteudo, classe, ancora) {
  const node = svgEl("text", { x, y, class: classe });
  if (ancora) node.setAttribute("text-anchor", ancora);
  node.textContent = conteudo;
  return node;
}

function linhasVisiveis(grafico) {
  let linhas = grafico.linhas.slice();
  if (estado.busca && grafico.tipo !== "matriz" && grafico.tipo !== "caixa" && grafico.tipo !== "dispersao") {
    const termo = estado.busca.toLocaleLowerCase("pt-BR");
    linhas = linhas.filter((linha) => String(linha[grafico.eixo]).toLocaleLowerCase("pt-BR").includes(termo));
  }
  if (estado.porValor && grafico.tipo === "barra") {
    linhas.sort((a, b) => b[estado.metrica] - a[estado.metrica]);
  } else if (linhas.some((linha) => linha._ordem != null)) {
    linhas.sort((a, b) => a._ordem - b._ordem);
  }
  if (estado.top > 0 && grafico.tipo === "barra") {
    linhas = linhas.slice(0, estado.top);
  }
  return linhas;
}

function rotuloValor(metrica, valor, total) {
  const base = formato(metrica, valor);
  if (!estado.participacao || !total) return base;
  const parte = `${((valor / total) * 100).toFixed(1).replace(".", ",")}%`;
  return `${base} · ${parte}`;
}

function desenharBarras(destino, grafico, linhas) {
  const horizontal = linhas.length > 5;
  const largura = Math.max(destino.clientWidth - 24, 640);
  const valores = linhas.map((linha) => linha[estado.metrica]);
  const maximo = Math.max(...valores, 1);
  const total = valores.reduce((soma, valor) => soma + valor, 0);
  const svg = svgEl("svg", { role: "img" });
  svg.appendChild(svgEl("title", {})).textContent = `${grafico.titulo}: ${estado.metrica}`;

  if (horizontal) {
    const margem = { topo: 8, direita: 168, baixo: 8, esquerda: 168 };
    const alturaLinha = 32;
    const altura = margem.topo + margem.baixo + Math.max(linhas.length, 1) * alturaLinha;
    const interno = largura - margem.esquerda - margem.direita;
    svg.setAttribute("viewBox", `0 0 ${largura} ${altura}`);
    linhas.forEach((linha, indice) => {
      const valor = linha[estado.metrica];
      const y = margem.topo + indice * alturaLinha + 6;
      const alturaBarra = alturaLinha - 12;
      const larguraBarra = (valor / maximo) * interno;
      const rotulo = linha[grafico.eixo];
      const barra = svgEl("rect", {
        x: margem.esquerda,
        y,
        width: Math.max(larguraBarra, 0),
        height: alturaBarra,
        rx: 3,
        class: estado.selecionado && estado.selecionado !== rotulo ? "barra apagada" : "barra",
      });
      barra.addEventListener("mousemove", (evento) => mostrarDica(evento, `${rotulo}: ${rotuloValor(estado.metrica, valor, total)}`));
      barra.addEventListener("mouseleave", esconderDica);
      barra.addEventListener("click", () => {
        estado.selecionado = rotulo;
        desenharPagina();
      });
      svg.appendChild(barra);
      svg.appendChild(textoSvg(margem.esquerda - 8, y + alturaBarra / 2 + 4, rotulo, "rotulo", "end"));
      svg.appendChild(textoSvg(margem.esquerda + larguraBarra + 6, y + alturaBarra / 2 + 4, rotuloValor(estado.metrica, valor, total), "eixo"));
    });
  } else {
    const margem = { topo: 16, direita: 12, baixo: 78, esquerda: 72 };
    const altura = 340;
    const internoL = largura - margem.esquerda - margem.direita;
    const internoA = altura - margem.topo - margem.baixo;
    svg.setAttribute("viewBox", `0 0 ${largura} ${altura}`);
    for (let marca = 0; marca <= 4; marca += 1) {
      const valorMarca = (maximo / 4) * marca;
      const y = margem.topo + internoA - (valorMarca / maximo) * internoA;
      svg.appendChild(svgEl("line", { x1: margem.esquerda, x2: largura - margem.direita, y1: y, y2: y, class: "guia" }));
      svg.appendChild(textoSvg(margem.esquerda - 8, y + 4, formato(estado.metrica, valorMarca), "eixo", "end"));
    }
    const passo = internoL / Math.max(linhas.length, 1);
    linhas.forEach((linha, indice) => {
      const valor = linha[estado.metrica];
      const alturaBarra = (valor / maximo) * internoA;
      const x = margem.esquerda + indice * passo + passo * 0.2;
      const y = margem.topo + internoA - alturaBarra;
      const rotulo = linha[grafico.eixo];
      const barra = svgEl("rect", {
        x,
        y,
        width: passo * 0.6,
        height: Math.max(alturaBarra, 0),
        rx: 3,
        class: estado.selecionado && estado.selecionado !== rotulo ? "barra apagada" : "barra",
      });
      barra.addEventListener("mousemove", (evento) => mostrarDica(evento, `${rotulo}: ${rotuloValor(estado.metrica, valor, total)}`));
      barra.addEventListener("mouseleave", esconderDica);
      barra.addEventListener("click", () => {
        estado.selecionado = rotulo;
        desenharPagina();
      });
      svg.appendChild(barra);
      const rotuloEl = textoSvg(x + passo * 0.3, margem.topo + internoA + 16, rotulo, "rotulo", "end");
      rotuloEl.setAttribute("transform", `rotate(-35 ${x + passo * 0.3} ${margem.topo + internoA + 16})`);
      svg.appendChild(rotuloEl);
    });
  }
  destino.replaceChildren(svg);
}

function desenharLinha(destino, grafico, linhas) {
  const largura = Math.max(destino.clientWidth - 24, 640);
  const altura = 340;
  const margem = { topo: 20, direita: 16, baixo: 48, esquerda: 72 };
  const valores = linhas.map((linha) => linha[estado.metrica]);
  const maximo = Math.max(...valores, 1);
  const internoL = largura - margem.esquerda - margem.direita;
  const internoA = altura - margem.topo - margem.baixo;
  const svg = svgEl("svg", { viewBox: `0 0 ${largura} ${altura}`, role: "img" });
  for (let marca = 0; marca <= 4; marca += 1) {
    const valorMarca = (maximo / 4) * marca;
    const y = margem.topo + internoA - (valorMarca / maximo) * internoA;
    svg.appendChild(svgEl("line", { x1: margem.esquerda, x2: largura - margem.direita, y1: y, y2: y, class: "guia" }));
    svg.appendChild(textoSvg(margem.esquerda - 8, y + 4, formato(estado.metrica, valorMarca), "eixo", "end"));
  }
  const coords = linhas.map((linha, indice) => ({
    x: margem.esquerda + (linhas.length === 1 ? internoL / 2 : (indice / (linhas.length - 1)) * internoL),
    y: margem.topo + internoA - (linha[estado.metrica] / maximo) * internoA,
    linha,
  }));
  svg.appendChild(svgEl("polyline", {
    points: coords.map((ponto) => `${ponto.x},${ponto.y}`).join(" "),
    fill: "none",
    stroke: "#1f4e45",
    "stroke-width": 2,
  }));
  coords.forEach((ponto) => {
    const rotulo = ponto.linha[grafico.eixo];
    const valor = ponto.linha[estado.metrica];
    const circulo = svgEl("circle", { cx: ponto.x, cy: ponto.y, r: estado.selecionado === rotulo ? 7 : 5, class: "ponto" });
    circulo.addEventListener("mousemove", (evento) => mostrarDica(evento, `${rotulo}: ${formato(estado.metrica, valor)}`));
    circulo.addEventListener("mouseleave", esconderDica);
    circulo.addEventListener("click", () => {
      estado.selecionado = rotulo;
      desenharPagina();
    });
    svg.appendChild(circulo);
    svg.appendChild(textoSvg(ponto.x, margem.topo + internoA + 22, rotulo, "eixo", "middle"));
  });
  destino.replaceChildren(svg);
}

function desenharDispersao(destino, grafico, linhas) {
  const largura = Math.max(destino.clientWidth - 24, 640);
  const altura = 380;
  const margem = { topo: 16, direita: 16, baixo: 42, esquerda: 72 };
  const maxX = Math.max(...linhas.map((linha) => linha[grafico.eixo]), 1);
  const maxY = Math.max(...linhas.map((linha) => linha[estado.metrica]), 1);
  const internoL = largura - margem.esquerda - margem.direita;
  const internoA = altura - margem.topo - margem.baixo;
  const svg = svgEl("svg", { viewBox: `0 0 ${largura} ${altura}`, role: "img" });
  svg.appendChild(svgEl("line", { x1: margem.esquerda, x2: largura - margem.direita, y1: margem.topo + internoA, y2: margem.topo + internoA, class: "guia" }));
  linhas.forEach((linha) => {
    const circulo = svgEl("circle", {
      cx: margem.esquerda + (linha[grafico.eixo] / maxX) * internoL,
      cy: margem.topo + internoA - (linha[estado.metrica] / maxY) * internoA,
      r: 4,
      class: "ponto",
      opacity: 0.55,
    });
    circulo.addEventListener("mousemove", (evento) => {
      mostrarDica(evento, `${grafico.eixo} ${formato(grafico.eixo, linha[grafico.eixo])} · ${estado.metrica} ${formato(estado.metrica, linha[estado.metrica])}`);
    });
    circulo.addEventListener("mouseleave", esconderDica);
    svg.appendChild(circulo);
  });
  svg.appendChild(textoSvg(margem.esquerda + internoL / 2, altura - 8, `${grafico.eixo} no eixo horizontal, ${estado.metrica} no vertical`, "eixo", "middle"));
  destino.replaceChildren(svg);
}

function desenharCaixa(destino, grafico) {
  const resumo = grafico.linhas[0];
  const largura = Math.max(destino.clientWidth - 24, 640);
  const altura = 160;
  const margem = { esquerda: 48, direita: 24 };
  const amplitude = resumo.max - resumo.min || 1;
  const interno = largura - margem.esquerda - margem.direita;
  const y = 70;
  const px = (valor) => margem.esquerda + ((valor - resumo.min) / amplitude) * interno;
  const svg = svgEl("svg", { viewBox: `0 0 ${largura} ${altura}`, role: "img" });
  svg.appendChild(svgEl("line", { x1: px(resumo.min), x2: px(resumo.max), y1: y, y2: y, stroke: "#1f4e45", "stroke-width": 2 }));
  svg.appendChild(svgEl("rect", { x: px(resumo.q1), y: y - 22, width: Math.max(px(resumo.q3) - px(resumo.q1), 2), height: 44, fill: "#1f4e45", rx: 4 }));
  svg.appendChild(svgEl("line", { x1: px(resumo.mediana), x2: px(resumo.mediana), y1: y - 22, y2: y + 22, stroke: "#fffcf7", "stroke-width": 2 }));
  [["Mínimo", resumo.min], ["Q1", resumo.q1], ["Mediana", resumo.mediana], ["Q3", resumo.q3], ["Máximo", resumo.max]].forEach(([nome, valor], indice) => {
    svg.appendChild(textoSvg(px(valor), indice % 2 === 0 ? y + 48 : y - 32, `${nome} ${formato("Valor Total", valor)}`, "eixo", "middle"));
  });
  destino.replaceChildren(svg);
}

function desenharMatriz(destino, grafico) {
  const tabela = document.createElement("table");
  const cabeca = document.createElement("tr");
  cabeca.appendChild(document.createElement("th"));
  grafico.metricas.forEach((coluna) => cabeca.appendChild(el("th", {}, coluna)));
  const thead = document.createElement("thead");
  thead.appendChild(cabeca);
  tabela.appendChild(thead);
  const corpo = document.createElement("tbody");
  grafico.linhas.forEach((linha) => {
    const tr = document.createElement("tr");
    tr.appendChild(el("th", {}, linha[grafico.eixo]));
    grafico.metricas.forEach((coluna) => {
      const td = el("td", { class: "num" }, formato("coef", linha[coluna]));
      const intensidade = Math.min(1, Math.abs(linha[coluna]));
      td.style.background = linha[coluna] >= 0
        ? `rgba(31, 78, 69, ${0.12 + intensidade * 0.75})`
        : `rgba(140, 74, 43, ${0.12 + intensidade * 0.75})`;
      if (intensidade > 0.55) td.style.color = "#fff";
      td.addEventListener("click", () => {
        estado.selecionado = `${linha[grafico.eixo]} × ${coluna}: correlação ${formato("coef", linha[coluna])}`;
        const detalhe = document.getElementById("detalhe");
        if (detalhe) detalhe.textContent = estado.selecionado;
      });
      tr.appendChild(td);
    });
    corpo.appendChild(tr);
  });
  tabela.appendChild(corpo);
  destino.replaceChildren(tabela);
}

function desenharGrafico(destino, grafico) {
  if (!grafico.metricas.includes(estado.metrica)) {
    estado.metrica = grafico.metricas.includes("Faturamento") ? "Faturamento" : grafico.metricas[0];
  }
  const linhas = linhasVisiveis(grafico);
  if (!linhas.length && grafico.tipo !== "caixa" && grafico.tipo !== "matriz") {
    destino.textContent = "Nenhuma linha com esse filtro.";
    return;
  }
  if (grafico.tipo === "linha") desenharLinha(destino, grafico, linhas);
  else if (grafico.tipo === "dispersao") desenharDispersao(destino, grafico, linhas);
  else if (grafico.tipo === "caixa") desenharCaixa(destino, grafico);
  else if (grafico.tipo === "matriz") desenharMatriz(destino, grafico);
  else desenharBarras(destino, grafico, linhas);
}

function tabelaDados(grafico, linhas) {
  if (["matriz", "dispersao", "caixa"].includes(grafico.tipo)) return null;
  const tabela = document.createElement("table");
  const cabeca = document.createElement("tr");
  [grafico.eixo, ...grafico.metricas].forEach((coluna, indice) => {
    cabeca.appendChild(el("th", indice ? { class: "num" } : {}, coluna));
  });
  const thead = document.createElement("thead");
  thead.appendChild(cabeca);
  tabela.appendChild(thead);
  const corpo = document.createElement("tbody");
  linhas.forEach((linha) => {
    const rotulo = linha[grafico.eixo];
    const tr = el("tr", { "data-rotulo": rotulo });
    if (rotulo === estado.selecionado) tr.className = "marcada";
    tr.addEventListener("click", () => {
      estado.selecionado = rotulo;
      desenharPagina();
    });
    tr.appendChild(el("td", {}, rotulo));
    grafico.metricas.forEach((metrica) => tr.appendChild(el("td", { class: "num" }, formato(metrica, linha[metrica]))));
    corpo.appendChild(tr);
  });
  tabela.appendChild(corpo);
  return tabela;
}

async function enviarResultado(evento) {
  evento.preventDefault();
  const dados = new FormData(evento.currentTarget);
  dados.append("acao", "adicionar");
  const resposta = await fetch("api/adicionar.php", { method: "POST", body: dados });
  const corpo = await resposta.json();
  if (!resposta.ok) {
    statusEl.textContent = corpo.erro || "Não foi possível adicionar o resultado.";
    statusEl.classList.add("erro");
    return;
  }
  statusEl.classList.remove("erro");
  estado.graficoId = corpo.id;
  estado.versao = "";
  evento.currentTarget.reset();
  await carregar(true);
}

async function removerResultado(id) {
  const dados = new FormData();
  dados.append("acao", "remover");
  dados.append("id", id);
  const resposta = await fetch("api/adicionar.php", { method: "POST", body: dados });
  if (!resposta.ok) {
    statusEl.textContent = "Não foi possível remover o resultado.";
    statusEl.classList.add("erro");
    return;
  }
  estado.graficoId = "";
  estado.selecionado = null;
  estado.versao = "";
  await carregar(true);
}

function formularioAdicionar() {
  const bloco = el("div", { class: "adicionar" });
  bloco.appendChild(el("button", {
    type: "button",
    onclick: () => {
      estado.formularioAberto = !estado.formularioAberto;
      desenharExplorar();
    },
  }, estado.formularioAberto ? "Fechar inclusão" : "Incluir CSV"));
  if (!estado.formularioAberto) return bloco;
  const form = el("form", { onsubmit: enviarResultado });
  form.appendChild(el("input", { name: "nome", type: "text", placeholder: "Nome do resultado", required: "required" }));
  form.appendChild(el("input", { name: "arquivo", type: "file", accept: ".csv,text/csv", required: "required" }));
  form.appendChild(el("button", { type: "submit", class: "primario" }, "Adicionar"));
  bloco.appendChild(form);
  return bloco;
}

function desenharExplorar() {
  const grafico = graficoPorId(estado.graficoId) || estado.dados.graficos[0];
  app.replaceChildren();
  const grade = el("div", { class: "grade" });
  const menu = el("div", { class: "menu" });
  [["Resultados", (item) => !item.manual && !IDS_PEDIDO.includes(item.id)], ["Pedido a pedido", (item) => IDS_PEDIDO.includes(item.id)], ["Adicionados", (item) => item.manual]].forEach(([nome, filtro]) => {
    const itens = estado.dados.graficos.filter(filtro);
    if (!itens.length) return;
    menu.appendChild(el("p", { class: "mudo" }, nome));
    itens.forEach((item) => {
      menu.appendChild(el("button", {
        type: "button",
        class: item.id === grafico.id ? "ativa" : "",
        onclick: () => {
          estado.graficoId = item.id;
          estado.selecionado = null;
          estado.metrica = item.metricas.includes("Faturamento") ? "Faturamento" : item.metricas[0];
          desenharExplorar();
        },
      }, item.titulo));
    });
  });
  menu.appendChild(formularioAdicionar());
  const coluna = el("div");
  if (!grafico) {
    coluna.appendChild(el("h1", {}, "Nenhum resultado ainda"));
    coluna.appendChild(el("p", {}, "Quando o pipeline gravar um CSV, ou quando você adicionar um arquivo, ele aparece aqui."));
    grade.appendChild(menu);
    grade.appendChild(coluna);
    app.appendChild(grade);
    return;
  }
  estado.graficoId = grafico.id;
  const resumo = estado.dados.resumo;
  if (resumo && resumo.faturamento > 0) {
    const kpis = el("div", { class: "kpis" });
    [["Faturamento", resumo.faturamento_texto], ["Pedidos", resumo.pedidos_texto], ["Ticket médio", resumo.ticket_texto]].forEach(([rotulo, valor]) => {
      const cartao = el("div", { class: "kpi" });
      cartao.appendChild(el("strong", {}, valor));
      cartao.appendChild(el("span", {}, rotulo));
      kpis.appendChild(cartao);
    });
    coluna.appendChild(kpis);
  }
  coluna.appendChild(el("h1", {}, grafico.titulo));
  const metricas = el("div", { class: "metricas" });
  grafico.metricas.forEach((metrica) => {
    metricas.appendChild(el("button", {
      type: "button",
      class: metrica === estado.metrica ? "ativa" : "",
      onclick: () => { estado.metrica = metrica; desenharExplorar(); },
    }, metrica));
  });
  coluna.appendChild(metricas);
  const acoes = el("div", { class: "acoes" });
  acoes.appendChild(el("button", { type: "button", class: estado.porValor ? "ativa" : "", onclick: () => { estado.porValor = !estado.porValor; desenharExplorar(); } }, estado.porValor ? "Ordem original" : "Ordenar por valor"));
  acoes.appendChild(el("button", { type: "button", class: estado.top === 5 ? "ativa" : "", onclick: () => { estado.top = estado.top === 5 ? 0 : 5; desenharExplorar(); } }, estado.top === 5 ? "Mostrar todos" : "Top 5"));
  acoes.appendChild(el("button", { type: "button", class: estado.participacao ? "ativa" : "", onclick: () => { estado.participacao = !estado.participacao; desenharExplorar(); } }, "Mostrar participação"));
  acoes.appendChild(el("input", { type: "search", placeholder: "Filtrar nome", value: estado.busca, oninput: (evento) => { estado.busca = evento.target.value; desenharExplorar(); } }));
  if (grafico.manual) {
    acoes.appendChild(el("button", { type: "button", onclick: () => removerResultado(grafico.id) }, "Remover este resultado"));
  }
  coluna.appendChild(acoes);
  const palco = el("div", { class: "painel" });
  coluna.appendChild(palco);
  const detalhe = el("p", { id: "detalhe" });
  const linhas = linhasVisiveis(grafico);
  const escolhida = linhas.find((linha) => linha[grafico.eixo] === estado.selecionado);
  detalhe.textContent = escolhida
    ? `${estado.selecionado}: ${formato(estado.metrica, escolhida[estado.metrica])}`
    : "Clique em uma barra ou em uma linha para ver o valor e comparar.";
  coluna.appendChild(detalhe);
  if (escolhida && linhas.length > 1 && grafico.tipo !== "dispersao" && grafico.tipo !== "matriz" && grafico.tipo !== "caixa") {
    const outros = linhas.filter((linha) => linha[grafico.eixo] !== estado.selecionado);
    if (!outros.some((linha) => linha[grafico.eixo] === estado.compararCom)) {
      estado.compararCom = outros[0][grafico.eixo];
    }
    const outro = outros.find((linha) => linha[grafico.eixo] === estado.compararCom);
    const faixa = el("div", { class: "comparacao" });
    faixa.appendChild(el("span", {}, "Comparar com"));
    const select = el("select", { onchange: (evento) => { estado.compararCom = evento.target.value; desenharExplorar(); } });
    outros.forEach((linha) => {
      const opcao = el("option", { value: linha[grafico.eixo] }, linha[grafico.eixo]);
      if (linha[grafico.eixo] === estado.compararCom) opcao.selected = true;
      select.appendChild(opcao);
    });
    faixa.appendChild(select);
    const diferenca = escolhida[estado.metrica] - outro[estado.metrica];
    faixa.appendChild(el("strong", {}, `${diferenca >= 0 ? "à frente" : "atrás"} em ${formato(estado.metrica, Math.abs(diferenca))}`));
    coluna.appendChild(faixa);
  }
  const eixos = el("p", { class: "mudo" });
  eixos.textContent = grafico.tipo === "linha"
    ? `Eixo horizontal: ${grafico.eixo}. Eixo vertical: ${estado.metrica}.`
    : `Métrica em destaque: ${estado.metrica}.`;
  coluna.appendChild(eixos);
  const tabela = tabelaDados(grafico, linhas);
  if (tabela) coluna.appendChild(tabela);
  grade.appendChild(menu);
  grade.appendChild(coluna);
  app.appendChild(grade);
  desenharGrafico(palco, grafico);
  if (!estado.gerando) statusEl.textContent = "";
  const campo = acoes.querySelector("input");
  if (campo && document.activeElement !== campo && estado.busca) campo.focus();
}

function fontesComparacao() {
  return estado.dados.graficos.filter((grafico) => grafico.tipo === "barra" && grafico.metricas.length > 0 && grafico.linhas.length >= 2);
}

function metricaBase(grafico) {
  return grafico.metricas.includes("Faturamento") ? "Faturamento" : grafico.metricas[0];
}

function desenharComparar() {
  const fontes = fontesComparacao();
  app.replaceChildren();
  app.appendChild(el("h1", {}, "Comparar dois recortes"));
  app.appendChild(el("p", { class: "mudo" }, "Escolha dois itens do mesmo resultado e veja a diferença."));
  if (!fontes.length) {
    app.appendChild(el("p", {}, "Ainda não há dois itens comparáveis."));
    return;
  }
  if (!fontes.some((grafico) => grafico.id === estado.fonte)) {
    estado.fonte = document.body.dataset.grafico && fontes.some((grafico) => grafico.id === document.body.dataset.grafico)
      ? document.body.dataset.grafico
      : fontes[0].id;
  }
  const grafico = graficoPorId(estado.fonte);
  const acoes = el("div", { class: "acoes" });
  const selectFonte = el("select", { onchange: (evento) => { estado.fonte = evento.target.value; estado.itemA = ""; estado.itemB = ""; desenharComparar(); } });
  fontes.forEach((item) => {
    const opcao = el("option", { value: item.id }, item.titulo);
    if (item.id === estado.fonte) opcao.selected = true;
    selectFonte.appendChild(opcao);
  });
  acoes.appendChild(selectFonte);
  const nomes = grafico.linhas.map((linha) => linha[grafico.eixo]);
  if (!nomes.includes(estado.itemA)) estado.itemA = nomes[0];
  if (!nomes.includes(estado.itemB) || estado.itemB === estado.itemA) estado.itemB = nomes[1] || nomes[0];
  [ ["itemA", "A"], ["itemB", "B"] ].forEach(([chave]) => {
    const select = el("select", { onchange: (evento) => { estado[chave] = evento.target.value; desenharComparar(); } });
    nomes.forEach((nome) => {
      const opcao = el("option", { value: nome }, nome);
      if (nome === estado[chave]) opcao.selected = true;
      select.appendChild(opcao);
    });
    acoes.appendChild(select);
  });
  app.appendChild(acoes);
  const a = grafico.linhas.find((linha) => linha[grafico.eixo] === estado.itemA);
  const b = grafico.linhas.find((linha) => linha[grafico.eixo] === estado.itemB);
  const metrica = metricaBase(grafico);
  const total = grafico.linhas.reduce((soma, linha) => soma + (linha[metrica] || 0), 0);
  const temTicket = grafico.metricas.includes("Faturamento") && grafico.metricas.includes("Pedidos");
  const ticket = (linha) => linha.Pedidos ? linha.Faturamento / linha.Pedidos : 0;
  const grade = el("div", { class: "cartoes" });
  [a, b].forEach((linha) => {
    const cartao = el("div", { class: "cartao" });
    cartao.appendChild(el("h2", {}, linha[grafico.eixo]));
    cartao.appendChild(el("p", {}, `${metrica}: ${formato(metrica, linha[metrica] || 0)}`));
    if (temTicket) {
      cartao.appendChild(el("p", {}, `Pedidos: ${formato("Pedidos", linha.Pedidos || 0)}`));
      cartao.appendChild(el("p", {}, `Ticket: ${formato("Ticket", ticket(linha))}`));
    }
    cartao.appendChild(el("p", {}, `Parte do total: ${total ? ((linha[metrica] / total) * 100).toFixed(1).replace(".", ",") : "0"}%`));
    grade.appendChild(cartao);
  });
  app.appendChild(grade);
  const diferenca = (a[metrica] || 0) - (b[metrica] || 0);
  const frase = `${a[grafico.eixo]} ${diferenca >= 0 ? "fica à frente de" : "fica atrás de"} ${b[grafico.eixo]} em ${formato(metrica, Math.abs(diferenca))}.`;
  app.appendChild(el("p", { class: "fala", id: "fala-comparacao" }, frase));
  const palco = el("div", { class: "painel" });
  app.appendChild(palco);
  const acoes2 = el("div", { class: "acoes" });
  acoes2.appendChild(el("a", { class: "botao", href: `index.php?pagina=resultados&grafico=${grafico.id}` }, "Ver o gráfico completo"));
  app.appendChild(acoes2);
  statusEl.textContent = "";
  const anterior = { metrica: estado.metrica, selecionado: estado.selecionado, top: estado.top, busca: estado.busca, participacao: estado.participacao };
  estado.metrica = metrica;
  estado.top = 0;
  estado.busca = "";
  estado.participacao = true;
  estado.selecionado = estado.itemA;
  desenharBarras(palco, grafico, [a, b].sort((x, y) => (y[metrica] || 0) - (x[metrica] || 0)));
  Object.assign(estado, anterior);
}

function desenharPagina() {
  esconderDica();
  if (!estado.dados) return;
  if (pagina === "comparar") desenharComparar();
  else desenharExplorar();
}

async function carregar(forcar) {
  const versaoResp = await fetch("api/dados.php?somente=versao", { cache: "no-store" });
  if (!versaoResp.ok) throw new Error("Falha ao ler a versão dos arquivos");
  const { versao } = await versaoResp.json();
  if (!forcar && versao === estado.versao && estado.dados) return;
  const dadosResp = await fetch("api/dados.php", { cache: "no-store" });
  if (!dadosResp.ok) throw new Error("Falha ao ler os dados");
  estado.dados = await dadosResp.json();
  const mudou = estado.versao && versao !== estado.versao;
  estado.versao = estado.dados.versao;
  desenharPagina();
  if (mudou && !statusEl.classList.contains("erro")) statusEl.textContent = "";
}

carregar(true).catch((erro) => {
  statusEl.textContent = erro.message;
  statusEl.classList.add("erro");
});
setInterval(() => {
  carregar(false).catch(() => {});
}, 2000);

const botaoGerar = document.getElementById("gerar");
if (botaoGerar) {
  botaoGerar.addEventListener("click", async () => {
    estado.gerando = true;
    botaoGerar.disabled = true;
    botaoGerar.textContent = "Gerando…";
    statusEl.classList.remove("erro");
    statusEl.textContent = "Gerando novas vendas…";
    const resposta = await fetch("api/gerar.php", { method: "POST" });
    if (!resposta.ok) {
      estado.gerando = false;
      botaoGerar.disabled = false;
      botaoGerar.textContent = "Gerar dados novamente";
      statusEl.textContent = "Não foi possível iniciar a geração.";
      statusEl.classList.add("erro");
      return;
    }
    acompanharGeracao();
  });
}

async function acompanharGeracao() {
  const resposta = await fetch("api/gerar.php", { cache: "no-store" });
  const corpo = await resposta.json();
  if (corpo.estado === "rodando" || corpo.estado === "aguardando") {
    statusEl.textContent = corpo.mensagem || "Gerando novas vendas…";
    setTimeout(acompanharGeracao, 700);
    return;
  }
  estado.gerando = false;
  if (botaoGerar) {
    botaoGerar.disabled = false;
    botaoGerar.textContent = "Gerar dados novamente";
  }
  if (corpo.estado === "erro") {
    statusEl.textContent = corpo.mensagem || "Não foi possível gerar os dados.";
    statusEl.classList.add("erro");
    return;
  }
  statusEl.classList.remove("erro");
  estado.versao = "";
  await carregar(true);
  statusEl.textContent = corpo.mensagem || "Dados gerados.";
}
