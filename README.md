# PI Data Science · Track & Field — guia único de execução

Este é o passo a passo completo para baixar e executar o projeto em outro computador.
Não é necessário abrir outros READMEs para seguir o roteiro.

O projeto gera vendas simuladas em uma VM Ubuntu, trata os lotes com SparkR,
armazena os resultados no HDFS e apresenta estatísticas e previsões em um painel R/Shiny.
Os dados são sintéticos: não representam a operação real da Track & Field.

## 1. Preparar o computador

Use **Ubuntu x86_64 (Intel/AMD de 64 bits)** instalado diretamente no computador.
Também é possível usar Ubuntu no WSL, mas WSL não é necessário em um computador Linux.
Execute os comandos abaixo no terminal do Ubuntu, com acesso à internet e permissão de sudo.

Reserve vários GB livres de disco e pelo menos 3 GiB de RAM disponíveis para cada etapa.
O download inclui uma imagem de VM, Spark e Hadoop. A primeira instalação pode demorar.
A VM será desligada antes de iniciar o Spark para liberar memória.
Não é necessário instalar Python manualmente: a preparação instala o Ansible e suas dependências.
A geração e a análise de dados são feitas em R; Java 17 executa Spark e Hadoop.

Se estiver no Windows, entre primeiro no Ubuntu/WSL. Não cole os comandos Bash no PowerShell.

## 2. Instalar Git e baixar o repositório

```bash
sudo apt update
sudo apt install -y git
cd ~
git clone https://github.com/luisfeob34/pi-data-science-track-field.git PI-Data-Science-Track-Field
cd ~/PI-Data-Science-Track-Field
```

O nome da pasta foi definido explicitamente para que os próximos comandos funcionem.
Todos os comandos seguintes são executados **nessa pasta, no host Ubuntu**, salvo indicação contrária.
As alterações mais recentes precisam ter sido enviadas ao GitHub no computador de origem antes do clone.
Dados gerados, discos da VM e resultados locais não acompanham o clone: você os criará nas próximas etapas.

Se já clonou anteriormente, entre na pasta e atualize:

```bash
cd ~/PI-Data-Science-Track-Field
git status
git pull --ff-only
```

Se o Git informar conflito com alterações locais, preserve essas alterações antes de atualizar.
Não é necessário clonar novamente a cada uso.

## 3. Instalar as ferramentas da VM — uma vez

```bash
bash infraestrutura/preparar-host.sh
```

Digite sua senha quando o sudo solicitar; o terminal não mostra os caracteres da senha.
O script instala QEMU, ferramentas de imagem, SSH, Ansible e OpenTofu 1.12.6.
Ele confere o checksum do OpenTofu antes da instalação.

A VM usa Ubuntu 24.04, 2 CPUs, 1,5 GiB de RAM e disco virtual de 12 GiB com alocação sob demanda.
Com KVM disponível, o QEMU usa aceleração; caso contrário, usa emulação TCG, mais lenta.
A porta local 2222 precisa estar livre.

## 4. Instalar R, Java, Spark e Hadoop — uma vez

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk-headless r-base-core curl r-cran-shiny r-cran-ggplot2 r-cran-plotly r-cran-dt r-cran-testthat
bash infraestrutura/bigdata/instalar.sh
```

O instalador baixa Spark 3.5.8 e Hadoop 3.4.2, verifica SHA-512 e instala em
`~/.local/share/pi-track-field-bigdata/`. SparkR vem dentro da distribuição Spark.
RStudio, Docker e Kubernetes não são necessários para este roteiro.

## 5. Criar a VM e gerar os primeiros dados

```bash
bash infraestrutura/p1.sh demonstrar
```

Esse comando realiza a demonstração completa da P1:

1. Cria e inicia a VM com OpenTofu e QEMU.
2. Aguarda a inicialização do Ubuntu e a conexão SSH.
3. Configura o R e as pastas usando Ansible.
4. Transfere o código para a VM por SCP.
5. Gera dois lotes de 1.000 vendas e valida os arquivos.
6. Repete a configuração para mostrar que não há mudanças desnecessárias.

Os dois lotes demonstram que uma nova execução preserva os dados anteriores.
A última execução do Ansible deve mostrar `changed=0`, `unreachable=0` e `failed=0`.
“Aguardando SSH” significa que o script está esperando a conexão remota ficar disponível.
SSH é a conexão entre o terminal do host e a VM, não o nome da resposta da VM.

O primeiro boot pode levar vários minutos, principalmente em TCG. Para acompanhar em outro terminal:

```bash
tail -f ~/.local/share/pi-track-field-p1/console.log
```

Ctrl+C encerra apenas esse acompanhamento do log.

### Alternativa: mostrar cada etapa separadamente

Use esta sequência **no lugar de `demonstrar`**, se quiser explicar cada etapa:

```bash
bash infraestrutura/p1.sh criar
bash infraestrutura/p1.sh configurar
bash infraestrutura/p1.sh transferir
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh validar
bash infraestrutura/p1.sh configurar
```

## 6. Copiar os dados para o computador e desligar a VM

```bash
bash infraestrutura/p1.sh baixar
bash infraestrutura/p1.sh parar
```

O terminal mostrará `Dados copiados para .../infraestrutura/evidencias/dados-DATA-ID`.
Dentro dessa pasta existe a subpasta `dados`, com os lotes `exec-*` e seus CSVs.
Anote o caminho informado: ele será a entrada do processamento.

Dentro da VM, os originais ficam em `/opt/pi-track-field/dados/exec-*/vendas.csv`.
No host, ficam em `infraestrutura/evidencias/dados-DATA-ID/dados/exec-*/vendas.csv`.
Desligar a VM preserva seus arquivos.

## 7. Processar os lotes com Spark e HDFS

Substitua `dados-DATA-ID` pelo nome exato mostrado na etapa anterior:

```bash
bash scripts/pipeline_bigdata.sh infraestrutura/evidencias/dados-DATA-ID/dados hdfs
```

Não digite literalmente `DATA-ID`. Por exemplo, se o download criou
`dados-20260929T120000-1234`, use `infraestrutura/evidencias/dados-20260929T120000-1234/dados`.

O pipeline inicia o HDFS, ingere os CSVs, trata os dados no Spark e gera a análise R.
Espere a mensagem **Pipeline concluido** antes de seguir.

- **Bronze:** originais, entrada normalizada e manifesto da origem.
- **Silver:** vendas válidas em Parquet.
- **Gold:** indicadores, tabela de vendas e dimensões de produto, canal, região e data.
- **Quarentena:** registros rejeitados e seus motivos.

A chave de cada venda combina o lote e o número do pedido. Lotes novos podem reutilizar os números.
Repetir o mesmo arquivo não cria outro lote bronze. Cada processamento gera um novo resultado
completo dos lotes conhecidos; não some resultados de execuções diferentes.

Spark usa DataFrames e SQL. HDFS usa um NameNode e um DataNode, com replicação 1.
Tudo roda no mesmo host Ubuntu: é uma demonstração, sem alta disponibilidade ou comprovação de escala em vários servidores.

Para executar Spark sem HDFS, use `local` no lugar de `hdfs`. Nesse caso, os Parquets ficam no disco local.

## 8. Abrir o painel

```bash
bash painel/iniciar.sh
```

Abra **http://localhost:8080** no navegador do mesmo computador.
Mantenha o terminal aberto. O painel carrega automaticamente a última execução Spark publicada.
Se o painel já estava aberto durante outro processamento, clique em **Carregar última execução Spark**.

Na primeira demonstração, os dois lotes devem resultar em 2.000 vendas válidas.
Execuções posteriores podem conter mais vendas, porque preservam os lotes anteriores.
Sem uma publicação Spark, o painel usa `data/raw/vendas_simuladas.csv`, se existir,
ou uma simulação de demonstração. Confira a origem indicada na tela.

Use os filtros por período, categoria, canal e região. Seleção vazia inclui todos os grupos.
As abas apresentam visão geral, destaques, previsões e pedidos. “Salvar esta análise” grava uma pasta
com os dados filtrados, estatísticas, gráficos, relatório e previsão quando houver histórico suficiente.

### Por que a previsão pode repetir o mesmo valor?

Na aba **Próximos meses**, o modo **Automático** escolhe o modelo que teve menor erro nos testes:

- Média histórica: repete a média nos meses futuros.
- Último mês: repete o último valor, com incerteza crescente.
- Tendência linear: projeta crescimento ou queda conforme o histórico.

Uma linha constante é válida quando um modelo constante vence a comparação. Ela não afirma que
as vendas reais serão iguais. Os dados simulados não garantem tendência ou sazonalidade.

Para comparar uma projeção que acompanha a direção do histórico, clique em
**Comparar tendência de crescimento ou queda**. O gráfico, a tabela e o download usam essa escolha.
O painel continua informando qual modelo teve o menor erro. Se a tendência tiver erro maior,
a escolha manual é uma comparação exploratória, não uma melhoria comprovada da previsão.
Uma tendência praticamente nula também pode produzir valores muito próximos.

São necessários pelo menos oito meses completos. Meses parciais das extremidades ficam fora do ajuste.
Meses sem registros só são tratados como zero quando você confirma essa interpretação.
Os testes avaliam um mês à frente; não validam automaticamente todo o horizonte de seis meses.
As faixas nominais de 95% dependem das hipóteses dos modelos. Não se estima sazonalidade anual com esse histórico curto.

Após uma atualização do código, encerre o painel com Ctrl+C e inicie novamente para carregar as alterações.

## 9. Encerrar corretamente

No terminal do painel, pressione **Ctrl+C**. Depois execute:

```bash
bash infraestrutura/bigdata/hdfs.sh parar
bash infraestrutura/p1.sh status
```

Se a VM ainda estiver ligada:

```bash
bash infraestrutura/p1.sh parar
```

Encerre os serviços antes de fechar o terminal Ubuntu ou desligar o computador.
O painel pode consultar a exportação CSV já publicada mesmo com VM e HDFS desligados.

## 10. Usar novamente em outro dia

Para apenas consultar o painel com os dados já processados:

```bash
cd ~/PI-Data-Science-Track-Field
bash painel/iniciar.sh
```

Para gerar mais dados e atualizar a análise:

```bash
cd ~/PI-Data-Science-Track-Field
bash infraestrutura/p1.sh iniciar
bash infraestrutura/p1.sh transferir
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh baixar
bash infraestrutura/p1.sh parar
```

A transferência atualiza o código na VM. Depois processe a nova pasta indicada por `baixar`:

```bash
bash scripts/pipeline_bigdata.sh infraestrutura/evidencias/dados-NOVA-DATA-ID/dados hdfs
bash painel/iniciar.sh
```

Ao terminar, siga a etapa 9. Não é necessário repetir as instalações a cada uso.

## 11. Onde fica cada coisa?

| Caminho | Responsabilidade |
|---|---|
| `infraestrutura/preparar-host.sh` | instala ferramentas da VM no host |
| `infraestrutura/p1.sh` | cria, configura, acessa e controla a VM; gera e copia dados |
| `infraestrutura/main.tf` | infraestrutura como código com OpenTofu |
| `infraestrutura/cloud-init.yaml.tftpl` | usuário e configuração inicial da VM |
| `infraestrutura/ansible/playbook.yml` | instala R e configura pastas na VM |
| `simulador/gerar_dados.R` | gera vendas simuladas dentro da VM |
| `infraestrutura/bigdata/instalar.sh` | instala Spark e Hadoop no host |
| `infraestrutura/bigdata/hdfs.sh` | inicia, consulta e encerra o HDFS |
| `scripts/pipeline_bigdata.sh` | coordena ingestão, Spark, análise R e logs |
| `R/lotes.R` | ingestão de lotes e localização da publicação Spark |
| `spark/processar.R` | tratamento, DataFrames, SQL e Parquets |
| `R/dados.R` | regras de tratamento e geração em R |
| `R/estatistica.R` | estatísticas, testes, frequências e probabilidades |
| `R/previsao.R` | modelos e avaliação temporal |
| `R/visualizacao.R` | gráficos |
| `R/pipeline.R` | exportação da análise e do relatório |
| `R/painel.R` e `painel/app.R` | painel interativo |
| `tests/` | testes automatizados |

| Resultado | Local |
|---|---|
| CSVs copiados da VM | `infraestrutura/evidencias/dados-*/dados/exec-*/vendas.csv` |
| Originais bronze locais | `data/lake/bronze/<hash>/original.csv` |
| Lake no HDFS | `hdfs://127.0.0.1:19000/pi-track-field/` |
| Lake no modo local | `data/lake/` |
| Resultados Spark e CSV do painel | `results/bigdata/exec-*/` |
| Identificador da publicação atual | `results/bigdata/ultima.txt` |
| Relatório, gráficos e estatísticas R | caminho indicado em `analise_r.txt` na pasta Spark |
| Logs e estado de sucesso/falha | `results/monitoramento/` |
| Logs da P1 | `infraestrutura/evidencias/demonstracao-*.txt` |

`resumo.csv` mostra recebidos, duplicados, rejeitados, aceitos e faturamento.
`consultas.sql` registra as consultas executadas; `integridade_modelo.csv` confere as relações das tabelas.
As estatísticas incluem média, mediana, moda, variância, desvio, quartis e frequências.
Os testes usam Kruskal-Wallis, Spearman e qui-quadrado, com ajuste de Holm.
Associação estatística não comprova causa; a base sintética demonstra o método.

Discos e chaves da VM ficam em `~/.local/share/pi-track-field-p1/`.
A instalação e os dados internos do Hadoop ficam em `~/.local/share/pi-track-field-bigdata/`.
Não compartilhe chaves privadas nem mova a imagem base de uma VM existente.
Resultados, evidências locais e discos são ignorados pelo Git: um clone novo precisa gerar os próprios dados.

## 12. Conferir se está funcionando

Execute os testes na raiz, sequencialmente:

```bash
Rscript tests/executar.R
bash tests/bigdata.sh local
bash tests/bigdata.sh hdfs
bash infraestrutura/bigdata/hdfs.sh parar
```

Os testes Big Data criam dados separados em `results/bigdata/testes/` e no diretório
`/pi-track-field-testes` do HDFS, sem substituir a base principal do painel.
A fixture tem 42 registros, com resultado esperado de 37 vendas válidas.
Ela verifica duplicatas, dados inválidos, conflitos, equivalência Spark/R, Parquets e repetição da ingestão.
Uma falha de origem é provocada intencionalmente para confirmar que a publicação anterior permanece válida.
O teste deve terminar com a mensagem de verificação bem-sucedida.

Em 29/09/2026 também foram validados oito lotes da VM: 8.000 vendas, faturamento simulado
de R$ 5.003.880,21 e carregamento automático no Shiny. Seus valores podem ser diferentes:
o comando `simular` gera novas sementes. O ambiente usado foi Ubuntu 26.04.1 em WSL e R 4.5.2;
a VM convidada usa Ubuntu 24.04. Os testes não representam uma instalação validada em toda versão de Ubuntu.

## 13. Resolver problemas comuns

| Situação | O que fazer |
|---|---|
| `No such file or directory` ao chamar um script | execute `pwd` e entre em `~/PI-Data-Science-Track-Field` |
| Nenhum `vendas.csv` encontrado | confira o caminho informado por `baixar` e inclua a subpasta `dados` |
| Aguardando SSH por vários minutos | acompanhe o console da VM; TCG pode demorar no primeiro boot |
| Quer entrar na VM | execute `bash infraestrutura/p1.sh ssh`; use `exit` para voltar ao host |
| Porta 8080 ocupada | execute `bash painel/iniciar.sh 8081` e abra `http://localhost:8081` |
| Mudança no código não aparece | Ctrl+C no painel e execute `bash painel/iniciar.sh` novamente |
| Previsão constante | consulte a explicação da etapa 8 e compare os modelos pelo seletor |
| Histórico insuficiente para previsão | amplie o período ou gere/importe uma base com ao menos oito meses completos |
| Falha de conexão com HDFS | mantenha o terminal aberto, confira o log e repita o pipeline após corrigir a causa |
| Pipeline informa falha | consulte o log correspondente em `results/monitoramento/`; a última publicação válida é preservada |
| Dependência R ausente | repita a instalação da etapa 4; para instalação via CRAN use `Rscript scripts/instalar.R` |

Comandos de diagnóstico:

```bash
bash infraestrutura/p1.sh status
bash infraestrutura/bigdata/hdfs.sh status
```

Com HDFS ativo, a interface local do NameNode fica em `http://127.0.0.1:19870`.
Não exponha essa configuração acadêmica à rede pública. Execute demonstrações sequencialmente;
encerrar uma sessão que iniciou o Hadoop pode interromper os serviços.

## 14. Alternativas de uso e formato dos dados

Para usar apenas o painel R, bastam Git, R e os pacotes R da etapa 4; execute `bash painel/iniciar.sh`.
Esse modo usa uma simulação de demonstração se não houver arquivos, sem VM, Java, Spark ou Hadoop.
Ele não demonstra sozinho a parte Big Data do PI.

Para gerar um relatório R sem abrir o navegador:

```bash
Rscript scripts/executar.R --gerar --quantidade 1000 --semente 42 --horizonte 3
Rscript scripts/executar.R --entrada data/raw/minhas_vendas.csv --horizonte 3
```

O segundo comando exige um CSV existente. Formato: UTF-8, vírgula como separador e ponto decimal:

```text
ID Pedido,Data da Venda,Cliente,Produto,Categoria,Canal de Venda,Região,Preço Unitário,Quantidade,Desconto,Valor Total
```

Datas usam `AAAA-MM-DD`; desconto é uma fração entre 0 e 1. Lotes da VM incluem `ID Execucao` e data de geração.
O tratamento rejeita campos ausentes, datas/números inválidos, limites inválidos e chaves conflitantes;
remove duplicatas exatas e recalcula valores em centavos com empate para o par.
Os originais são preservados. Valores atípicos válidos não são removidos automaticamente.
A ingestão lê um CSV por vez em memória; o painel recebe até 200 mil vendas completas.
Acima desse limite, os Parquets e indicadores Spark permanecem disponíveis sem amostra silenciosa.

No Windows nativo, apenas o painel R pode ser iniciado com R instalado:

```text
Rscript scripts/instalar.R
Rscript scripts/iniciar_painel.R
```

No RStudio, abra o projeto e execute `shiny::runApp("painel", port = 8080)`.

Docker é opcional e executa somente o painel, não o roteiro completo VM/Spark/HDFS:

```bash
docker build -t pi-track-field-r .
docker run --rm -p 127.0.0.1:8080:8080 pi-track-field-r
```

Esse caminho Docker não foi executado na validação registrada. Os antigos resultados em
`results/spark/`, `results/graficos/` e `data/processed/` são históricos e não alimentam o painel atual.

## 15. Entrega acadêmica

O código e os testes não substituem as atividades do grupo. Ainda é necessário registrar
problema e beneficiário, consentimento, integrantes e responsabilidades, cronograma, reuniões,
sprint reports, vídeo de carreiras e relatório individual de extensão, conforme a orientação do PI.
O vídeo exige participação real dos integrantes e não deve ser produzido por IA.
Não alegue parceria ou benefício comercial real sem evidência.

Os documentos em `docs/` preservam arquitetura, metodologia e evidências de validação.
São material complementar; todas as instruções para executar o projeto estão neste README.
Antes de testar em outra máquina, faça commit e envie as alterações revisadas ao repositório.
Não é necessário enviar discos da VM ou resultados gerados para que o projeto possa ser reproduzido.
