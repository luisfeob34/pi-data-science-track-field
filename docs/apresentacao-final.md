# Roteiro simples para demonstrar o PI

## 1. Explique o problema

“O projeto mostra como reunir e tratar lotes de vendas para comparar produtos,
canais, regiões e períodos. A base é simulada; os resultados demonstram o
funcionamento da solução.” Apresente também o problema e o beneficiário que o
grupo tiver efetivamente validado. Consulte `gestao-pi.md` para as informações pendentes.

## 2. Mostre de onde vêm os dados

O simulador `simulador/gerar_dados.R` roda na VM da P1 e gera um CSV por execução.
`infraestrutura/p1.sh baixar` copia os arquivos para o computador. A VM pode ser
desligada após a cópia; o processamento seguinte roda no host Ubuntu.

## 3. Execute o processamento

Com as dependências instaladas conforme `infraestrutura/bigdata/README.md`, execute
na raiz do projeto, substituindo a pasta pelo caminho mostrado ao baixar:

```bash
bash scripts/pipeline_bigdata.sh infraestrutura/evidencias/dados-DATA-ID/dados hdfs
```

Explique as três camadas:

- **Bronze:** guarda o CSV original e registra sua origem.
- **Silver:** mantém as vendas válidas, depois de tratar erros e duplicidades.
- **Gold:** reúne indicadores e tabelas para análise.

`spark/processar.R` usa DataFrames e SQL no Spark. HDFS armazena os arquivos;
R calcula estatísticas e previsões. Os pedidos são identificados pelo lote e pelo
número do pedido, para não perder vendas de execuções diferentes.

## 4. Mostre o resultado

```bash
bash painel/iniciar.sh
```

Abra `http://localhost:8080`. O painel carrega a última execução publicada.
Mostre o faturamento, o produto de maior receita e a comparação entre canais.
Altere um filtro e explique como a leitura muda. Abra os detalhes estatísticos
somente depois de apresentar os indicadores principais.

Mostre uma previsão como estimativa, com sua faixa de incerteza e avaliação
histórica. Uma diferença estatística não comprova causa, e uma projeção feita
com dados sintéticos não é uma previsão comercial real.

## 5. Comprove a qualidade

Na pasta indicada ao terminar o pipeline, mostre:

- `resumo.csv`: recebidos, duplicados, rejeitados, aceitos e faturamento.
- `consultas.sql`: consultas realmente executadas.
- `integridade_modelo.csv`: conferência da fato com as quatro dimensões.
- `analise_r.txt`: caminho do relatório, gráficos e tabelas em R.

Os logs de cada execução ficam em `results/monitoramento/`. Os testes reproduzíveis
estão em `tests/bigdata.sh`: repetem lotes e simulam uma falha, preservando a
última publicação válida. As fixtures ficam separadas da base do painel.

## 6. Explique o limite e encerre

A demonstração usa um computador, um DataNode e Spark com dois threads locais.
Isso comprova a integração dos componentes; não comprova desempenho em um
cluster, alta disponibilidade ou benefício comercial real.

Encerre o painel com Ctrl+C e pare o HDFS:

```bash
bash infraestrutura/bigdata/hdfs.sh parar
```

Complete ainda as evidências humanas exigidas: beneficiário e consentimento,
papéis e registros do grupo, vídeo de carreiras e relatório individual de extensão.
O controle completo está em `checklist-pi.md`.
