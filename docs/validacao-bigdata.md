# Validação do pipeline Big Data — 29/09/2026

Ambiente utilizado: Ubuntu 26.04.1 em WSL, R 4.5.2, Java 17, Spark 3.5.8 e
Hadoop 3.4.2. Spark executado com `local[2]`; HDFS com um NameNode, um DataNode
e replicação 1. Esta validação não é um benchmark de cluster distribuído.

## Testes concluídos

| Verificação | Resultado observado |
|---|---|
| Suíte `Rscript tests/executar.R` | passou: dados, estatística/previsão, lotes, painel/pipeline e simulador |
| Fixture Spark local | 42 recebidos, 1 duplicata, 4 rejeitados, 37 aceitos |
| Fixture Spark + HDFS | mesmas contagens e mesmas vendas do modo local |
| Comparação independente com R | todas as colunas exportadas conferidas linha a linha |
| Faturamento das 37 vendas | R$ 19.474,46 nos dois modos |
| Segunda ingestão da mesma origem | zero lotes novos; contagens e valores preservados |
| DataFrame versus Spark SQL | agrupamento por categoria equivalente |
| Modelo estrela | leitura dos Parquets e junção da fato com quatro dimensões preservou os 37 pedidos |
| Origem inexistente | erro registrado; publicação anterior preservada nos modos local e HDFS |
| Shiny | carregamento automático de execução completa, manutenção da base diante de execução incompleta e filtros sem registros |
| ShellCheck | scripts Big Data e roteiro de integração sem apontamentos |

A fixture contém dois lotes com números de pedido repetidos entre lotes,
uma linha duplicada, quantidade zero, data impossível e duas linhas divergentes
para a mesma chave. Os quatro rejeitados incluem as duas versões conflitantes.

## Evidências locais

### Demonstração com os lotes da VM

Origem: `infraestrutura/evidencias/dados-20260928T163541-1991/dados/`, com oito
lotes de 1.000 vendas. Execução publicada: **exec-20260929T150148-717**.

| Medida | Resultado |
|---|---:|
| Recebidos e aceitos | 8.000 |
| Duplicados e rejeitados | 0 |
| Faturamento simulado consolidado | R$ 5.003.880,21 |
| Pedidos após junção das dimensões | 8.000 |
| Duração do processamento Spark | aproximadamente 61 segundos |
| Duração do pipeline completo nesta repetição | 171 segundos |

Todas as 8.000 vendas exportadas foram comparadas linha a linha com o tratamento
R independente dos oito CSVs originais. Um teste do servidor Shiny confirmou o
carregamento automático das 8.000 vendas e a indicação de origem Spark.
Essas durações são observações deste computador, não garantias de desempenho.

Saídas: `results/bigdata/exec-20260929T150148-717/`; relatório, estatísticas e
gráficos em `results/r/exec-20260929-120439-97938862e76/`. O relatório do HDFS foi
salvo em `results/bigdata/hdfs-validado.txt`. O serviço foi parado após a
validação; o painel pode continuar utilizando o CSV completo publicado localmente.

### Ensaios com defeitos controlados

As saídas grandes e os dados gerados são ignorados pelo Git. Após clonar, reproduza
os testes; os nomes de execução e horários serão diferentes.

- Local: `results/bigdata/testes/local/ensaio-20260929T145006-607/`.
  Publicação validada: `exec-20260929T145202-2481`.
- HDFS: `results/bigdata/testes/hdfs/ensaio-20260929T145053-1136/`.
  Publicação validada após a correção do bloqueio: `exec-20260929T145817-3098`.
- Dentro de cada raiz: `results/bigdata/` contém CSVs/SQL, `results/r/` contém
  relatórios e gráficos e `results/monitoramento/` contém logs e estados.

Os logs de falha provocada são esperados nos ensaios. A última execução do monitor
pode indicar falha enquanto `ultima.txt` continua apontando para o resultado válido.

## Correções verificadas

- Seleção variádica de colunas no SparkR.
- Identidade composta por lote e pedido, preservando vendas de lotes distintos.
- Arredondamento monetário uniforme entre R e Spark, inclusive descontos com empate.
- Detecção de serviços Hadoop: o status textual é verificado porque o comando
  pode retornar código zero mesmo com o serviço parado.
- Fechamento do descritor de bloqueio antes de iniciar daemons: o HDFS não retém
  o bloqueio do pipeline e uma segunda execução pode começar normalmente.
- Dados de teste separados da publicação principal e da área HDFS da demonstração.

Uma sessão de testes encerrada enviou SIGHUP ao NameNode durante uma execução
paralela. O erro de conexão foi registrado e essa execução não foi publicada.
O ensaio de demonstração foi retomado em uma sessão única com encerramento
explícito do HDFS ao final. Não há recuperação automática de um servidor interrompido.

## Reproduzir

Após instalar os requisitos de `infraestrutura/bigdata/README.md`:

```bash
Rscript tests/executar.R
bash tests/bigdata.sh local
bash tests/bigdata.sh hdfs
bash infraestrutura/bigdata/hdfs.sh parar
```

Execute os comandos sequencialmente no terminal Ubuntu. Os scripts geram uma
pasta nova por ensaio e preservam as evidências anteriores. Não some snapshots
diferentes como se fossem novas vendas.

## Limites

Dados sintéticos não comprovam resultados comerciais. A demonstração não mede
escala em múltiplos servidores nem alta disponibilidade. A ingestão lê um CSV por
vez em memória; a exportação completa para o painel é limitada a 200 mil registros.
Acima disso, permanecem os Parquets e indicadores Spark, sem amostragem silenciosa.
Os requisitos humanos e acadêmicos pendentes estão em `checklist-pi.md`.
