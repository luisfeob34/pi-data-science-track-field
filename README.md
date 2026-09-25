# PI · Data Science · Track & Field

Projeto acadêmico de análise de vendas com **R**, **Shiny**, **Plotly** e **ggplot2**.
A base padrão contém vendas simuladas de 2026; não representa a operação real da empresa.

## Executar no Ubuntu / WSL

No terminal Ubuntu, instale os requisitos uma vez:

```bash
sudo apt update
sudo apt install -y r-base-core r-cran-shiny r-cran-ggplot2 r-cran-plotly r-cran-dt r-cran-testthat
```

Entre na pasta do projeto e inicie:

```bash
cd /mnt/c/Users/lipe/Desktop/PI-Data-Science-Track-Field
bash painel/iniciar.sh
```

Abra **http://localhost:8080**. Mantenha o terminal aberto. Ctrl+C encerra o painel.
Outra porta: `bash painel/iniciar.sh 8081`.

Também é possível executar com R instalado nativamente no Windows, pelo terminal na raiz:

```text
Rscript scripts/instalar.R
Rscript scripts/iniciar_painel.R
```

No RStudio, abra o projeto e execute `shiny::runApp("painel", port = 8080)`.
RStudio é opcional. O fluxo de dados não depende mais de Python, PHP, Java ou Spark.
O processamento atual ocorre em memória, em uma máquina, adequado à base deste projeto.
A migração não inclui execução distribuída em cluster.

## Painel interativo

- Filtros por período, categoria, canal e região; seleção vazia inclui todos os grupos.
- Faturamento, pedidos, ticket médio e itens vendidos calculados para o recorte.
- Ranking por indicador, série mensal e boxplots com zoom e consulta de valores.
- Testes estatísticos com tamanho de efeito e correção de múltiplas comparações.
- Previsões de 1 a 6 meses, intervalo nominal de 95% e avaliação temporal.
- Importação de CSV de vendas, auditoria de tratamento e downloads.
- Geração reproduzível de vendas em R, com semente configurável.
- Salvamento de cada análise em uma pasta independente, sem apagar resultados anteriores.

O painel lê `data/raw/vendas_simuladas.csv` quando disponível. Sem esse arquivo,
abre uma simulação de demonstração. Importações e novas simulações ficam isoladas
na sessão e não sobrescrevem a base local. Para persistir o recorte, use **Salvar esta análise**.
Os destaques de produto, canal e mês acompanham os filtros. A aba **O que chama atenção**
explica os testes em linguagem simples; métodos e tabelas técnicas ficam em seções expansíveis.
Não se importam os antigos CSVs agregados: o novo painel calcula as análises a partir dos pedidos.

## Executar o pipeline sem abrir o painel

Analisar o CSV local:

```bash
Rscript scripts/executar.R
```

Analisar outro arquivo ou gerar uma simulação em memória:

```bash
Rscript scripts/executar.R --entrada data/raw/minhas_vendas.csv --horizonte 3
Rscript scripts/executar.R --gerar --quantidade 1000 --semente 42 --horizonte 6
```

Cada execução cria `results/r/exec-.../` com vendas tratadas, auditoria, agregados,
estatísticas descritivas, testes, PNGs, relatório e versões do ambiente (`sessionInfo.txt`).
Quando existe histórico suficiente, inclui previsão, métricas dos modelos e erros por origem temporal.
Um histórico insuficiente gera uma explicação no relatório, sem inventar previsões.

As saídas são construídas em uma pasta temporária e publicadas juntas ao terminar.
Os antigos arquivos de `results/spark/`, `results/graficos/` e `data/processed/`
foram preservados como histórico, mas não são lidos pelo novo fluxo.

## Formato do CSV

UTF-8, separado por vírgulas, com ponto decimal e as colunas:

```text
ID Pedido,Data da Venda,Cliente,Produto,Categoria,Canal de Venda,Região,Preço Unitário,Quantidade,Desconto,Valor Total
```

Datas devem estar em `AAAA-MM-DD`. Desconto é uma fração entre 0 e 1.
O tratamento remove duplicados exatos, campos obrigatórios vazios, datas inválidas,
números não finitos, preços não positivos, quantidades não inteiras/positivas e descontos fora dos limites.
Pedidos com o mesmo ID e conteúdos divergentes são descartados como ambíguos.
O total é recalculado com arredondamento monetário a duas casas; diferenças são auditadas.
Valores atípicos válidos são preservados, não removidos automaticamente.

## Estatística e previsão

Consulte [a metodologia](docs/metodologia-r.md) para hipóteses, limitações e referências.

- **Kruskal-Wallis:** distribuição do valor dos pedidos por categoria, canal e região; efeito epsilon².
- **Spearman:** associação entre desconto e valor; efeito rho. O desconto já participa do cálculo do total.
- **Qui-quadrado:** independência entre categoria e canal, com p-valor por Monte Carlo; efeito V de Cramér.
- **Holm:** ajuste dos cinco testes, considerando os disponíveis, com nível de 5%.
- **Previsão:** média histórica, último mês e tendência linear comparados por MAE em origens móveis.

Meses são identificados por ano e mês. Os meses parciais das extremidades ficam
fora do ajuste. Exige-se um mínimo de 8 meses completos. Meses sem registros são
tratados como ausentes; a interpretação como zero requer a opção explícita no painel
ou `--meses-zero` no terminal. A cobertura é estimada conservadoramente pela primeira
e última data da base, limitada pelo filtro de período.

## Estrutura

```text
R/                       Regras de dados, testes, previsão, gráficos, exportação e servidor Shiny
painel/app.R             Entrada do aplicativo
painel/www/              Estilo visual
scripts/executar.R       Pipeline por linha de comando
scripts/iniciar_painel.R Inicialização do servidor
scripts/instalar.R       Instalação das dependências via CRAN
tests/                   Testes automatizados
data/raw/                CSV de entrada local
results/r/               Execuções do pipeline R
docs/                    Metodologia e registro da migração
infra/                   Configuração opcional de infraestrutura
```

## Testes

```bash
Rscript tests/executar.R
```

Cobrem limpeza e auditoria, casos vazios, conservação dos totais, filtros, reprodução
da simulação, ajuste de p-valores, isolamento temporal do backtest, séries curtas e constantes,
exportação dos resultados e reatividade/gráficos do Shiny.

Ambiente validado: Shiny 1.10.0, ggplot2 4.0.2, Plotly 4.10.4, DT 0.34.0 e testthat 3.3.2.
As versões completas do R e das dependências ficam no `sessionInfo.txt` de cada execução.
No Windows com Edge instalado, `powershell -File tests/validar_navegador.ps1` confere
o painel já iniciado e captura as telas em `results/r/`. A suíte R é independente desse teste visual.
O Dockerfile e o playbook foram adaptados, mas não foram executados nesta validação.

## Docker (opcional)

```bash
docker build -t pi-track-field-r .
docker run --rm -p 127.0.0.1:8080:8080 pi-track-field-r
```

A imagem abre uma simulação em memória. Para usar seus dados e persistir análises:

```bash
docker run --rm -p 127.0.0.1:8080:8080 \
  -v "$PWD/data/raw:/app/data/raw:ro" \
  -v "$PWD/results/r:/app/results/r" pi-track-field-r
```

Prepare a pasta de resultados com permissão de escrita para o usuário do contêiner.
Ansible pode instalar as dependências do Ubuntu. Os arquivos de Kubernetes e monitoramento
são opcionais e não fazem parte da inicialização do painel.
