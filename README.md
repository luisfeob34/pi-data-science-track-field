# PI Data Science · Track & Field — guia único de execução

Este é o passo a passo completo para baixar e executar o projeto em outro computador.
Não é necessário abrir outros READMEs para seguir o roteiro.

O projeto usa **duas VMs Ubuntu**:

- **VM geradora:** o simulador em R grava lotes de vendas em CSV.
- **VM de exibição:** hospeda o **Data Warehouse em PostgreSQL** (modelo estrela) e o painel R/Shiny.

Entre as duas, o host processa os lotes com SparkR sobre HDFS (ETL) e carrega o resultado no Data Warehouse.
O painel consulta o DW e fica em `http://localhost:8080`.
Os dados são sintéticos: não representam a operação real da Track & Field.

```text
VM geradora (CSV) → SCP → host: staging → Spark/HDFS (ETL) → modelo estrela → carga → VM de exibição: PostgreSQL (DW) → painel Shiny
```

## Primeira execução: passo a passo resumido

Para um **computador Ubuntu novo, sem nada instalado**. Copie um bloco por vez no terminal do Ubuntu,
espere terminar e só então passe ao próximo. As seções 1 a 9, depois deste resumo, explicam cada passo em detalhe.

**Antes de começar:** Ubuntu de 64 bits (Intel/AMD), internet, senha de administrador (sudo),
pelo menos **4 GiB de RAM livres** e cerca de **15 GB livres em disco**.
No Windows, abra o **Ubuntu (WSL)**; não use o PowerShell.

### Passo 1 — Baixar o projeto

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/luisfeob34/pi-data-science-track-field.git "$HOME/PI-Data-Science-Track-Field"
cd "$HOME/PI-Data-Science-Track-Field"
```

Todos os passos seguintes rodam **dentro dessa pasta**. Se fechar o terminal, entre nela de novo com o último comando acima.

### Passo 2 — Instalar as dependências (só na primeira vez)

```bash
bash infraestrutura/preparar-host.sh
sudo apt install -y openjdk-17-jdk-headless r-base-core curl r-cran-shiny r-cran-ggplot2 r-cran-plotly r-cran-dt r-cran-testthat
bash infraestrutura/bigdata/instalar.sh
```

Instala as ferramentas das VMs (QEMU, OpenTofu, Ansible), o R, o Java, o Spark e o Hadoop.
O sudo pede sua senha; o terminal não mostra o que você digita. Pode demorar alguns minutos.

### Passo 3 — Criar as duas VMs e gerar os dados

```bash
bash infraestrutura/p1.sh demonstrar
```

Cria a **VM geradora** e a **VM de exibição**, configura as duas e gera dois lotes de vendas.
**É a etapa mais demorada:** na primeira vez, pode levar bastante tempo, principalmente sem aceleração KVM.
Mensagens “Aguardando SSH” são normais. Está pronto quando aparecer:
`Concluido: dados preservados e Ansible idempotente nas duas VMs (changed=0).`

### Passo 4 — Copiar os dados e desligar as VMs

```bash
bash infraestrutura/p1.sh baixar
bash infraestrutura/p1.sh parar todas
```

Copia os lotes da VM geradora para o computador e desliga as VMs para liberar memória para o Spark.

### Passo 5 — Processar os dados com Spark e HDFS

```bash
DADOS="$(ls -d infraestrutura/evidencias/dados-*/ | tail -n 1)dados"
bash scripts/pipeline_bigdata.sh "$DADOS" hdfs
bash infraestrutura/bigdata/hdfs.sh parar
```

A primeira linha encontra sozinha a pasta copiada no passo 4. Espere a mensagem `Pipeline concluido`.
A última linha desliga o HDFS para liberar memória.

### Passo 6 — Carregar o Data Warehouse e abrir o painel

```bash
bash infraestrutura/p1.sh iniciar exibicao
bash infraestrutura/p1.sh publicar
```

Liga a VM de exibição e carrega o resultado no Data Warehouse (PostgreSQL).
Quando aparecer `Painel: http://localhost:8080`, abra **http://localhost:8080** no navegador.

### Passo 7 — Conferir e desligar

Para conferir as duas VMs, o banco, o painel e a última carga:

```bash
bash infraestrutura/p1.sh iniciar geradora
bash infraestrutura/p1.sh validar
```

Ao terminar o uso, desligue tudo antes de fechar o terminal:

```bash
bash infraestrutura/p1.sh parar todas
```

**Deu erro?** Veja a seção 13. Para usar de novo em outro dia, sem reinstalar nada, veja a seção 10.

## 1. Preparar o computador

Use **Ubuntu x86_64 (Intel/AMD de 64 bits)** instalado diretamente no computador.
Também é possível usar Ubuntu no WSL, mas WSL não é necessário em um computador Linux.
Execute os comandos abaixo no terminal do Ubuntu, com acesso à internet e permissão de sudo.

Reserve vários GB livres de disco e pelo menos 4 GiB de RAM disponíveis.
As duas VMs juntas usam cerca de 2,8 GiB; a criação e a configuração inicial ligam as duas.
O download inclui uma imagem de VM, Spark e Hadoop. A primeira instalação pode demorar.
As VMs são desligadas antes de iniciar o Spark para liberar memória.
Não é necessário instalar Python manualmente: a preparação instala o Ansible e suas dependências.
A geração e a análise de dados são feitas em R; Java 17 executa Spark e Hadoop.

Se estiver no Windows, entre primeiro no Ubuntu/WSL. Não cole os comandos Bash no PowerShell.

## 2. Instalar Git e baixar o repositório

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/luisfeob34/pi-data-science-track-field.git "$HOME/PI-Data-Science-Track-Field"
cd "$HOME/PI-Data-Science-Track-Field"
pwd
ls
```

O clone acima define **o local e o nome exatos da pasta**, independentemente de onde
o terminal estava aberto. `$HOME` é a pasta pessoal do usuário conectado no Ubuntu;
não substitua essa variável por `lipe`. Por exemplo, para um usuário chamado `maria`,
o projeto ficará em `/home/maria/PI-Data-Science-Track-Field`.

Confira a saída de `pwd`: ela deve terminar em `/PI-Data-Science-Track-Field`.
O comando `ls` deve mostrar `README.md`, `R`, `painel`, `scripts` e `infraestrutura`.
**Se o `cd` apresentar erro, não continue com os scripts: localize a pasta conforme abaixo.**
Todos os comandos seguintes são executados **nessa pasta, no host Ubuntu**, salvo indicação contrária.
As alterações mais recentes precisam ter sido enviadas ao GitHub no computador de origem antes do clone.
Dados gerados, discos da VM e resultados locais não acompanham o clone: você os criará nas próximas etapas.

### Se o projeto já foi baixado em outro local

No Ubuntu, maiúsculas e minúsculas fazem diferença. Se você usou apenas
`git clone https://github.com/luisfeob34/pi-data-science-track-field.git`, sem informar
o destino, a pasta criada se chama **`pi-data-science-track-field`**, em minúsculas,
e fica dentro da pasta em que o terminal estava naquele momento.

Se esse clone foi feito na sua pasta pessoal, entre assim:

```bash
cd "$HOME/pi-data-science-track-field"
pwd
ls
```

Se não souber onde baixou, procure na sua pasta pessoal:

```bash
find "$HOME" -maxdepth 5 -type d -iname 'pi-data-science-track-field*' 2>/dev/null
```

Copie o caminho encontrado e use `cd "caminho completo encontrado"`, substituindo
todo o texto entre aspas pelo caminho real. As aspas permitem nomes com espaços.
Outra opção é abrir a pasta do projeto no gerenciador de arquivos do Ubuntu e
escolher **Abrir no terminal**; nesse caso, confira com `pwd` e `ls`, sem precisar de `cd`.
Uma pasta extraída de ZIP pode terminar em `-main` e não conter o histórico Git;
para seguir o fluxo de atualização com `git pull`, use um clone Git.

**Ubuntu instalado diretamente:** não use `C:/Users/...` nem `/mnt/c/Users/...`.
Esses caminhos não correspondem à pasta pessoal do Ubuntu.

**Ubuntu no WSL:** o clone recomendado acima também funciona. Se o projeto estiver
no disco do Windows, use o caminho real em `/mnt/c/...`. Somente no computador original
do projeto, cuja pasta está na área de trabalho de `lipe`, o comando é:

```bash
cd "/mnt/c/Users/lipe/Desktop/PI-Data-Science-Track-Field"
```

Não copie esse caminho para outro computador sem conferir o usuário e o local da pasta.

### Atualizar um clone existente

Primeiro entre na pasta correta usando uma das opções acima. Depois execute:

```bash
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

| VM | Papel | Recursos | Portas no host |
|---|---|---|---|
| geradora | simulador R e lotes CSV | 2 CPUs, 1,5 GiB, disco de 12 GiB | SSH 127.0.0.1:2222 |
| exibicao | PostgreSQL (Data Warehouse) e painel Shiny | 2 CPUs, 1,25 GiB, disco de 12 GiB | SSH 127.0.0.1:2223, painel 127.0.0.1:8080 |

As duas usam Ubuntu 24.04 e a mesma imagem base verificada; os discos crescem sob demanda.
Com KVM disponível, o QEMU usa aceleração; caso contrário, usa emulação TCG, mais lenta.
As portas 2222, 2223 e 8080 precisam estar livres.

## 4. Instalar R, Java, Spark e Hadoop — uma vez

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk-headless r-base-core curl r-cran-shiny r-cran-ggplot2 r-cran-plotly r-cran-dt r-cran-testthat
bash infraestrutura/bigdata/instalar.sh
```

O instalador baixa Spark 3.5.8 e Hadoop 3.4.2, verifica SHA-512 e instala em
`~/.local/share/pi-track-field-bigdata/`. SparkR vem dentro da distribuição Spark.
RStudio, Docker e Kubernetes não são necessários para este roteiro.

## 5. Criar as VMs e gerar os primeiros dados

```bash
bash infraestrutura/p1.sh demonstrar
```

Esse comando realiza a demonstração completa da infraestrutura:

1. Cria e inicia as duas VMs com OpenTofu e QEMU.
2. Aguarda a inicialização do Ubuntu e a conexão SSH de cada uma.
3. Configura as VMs com Ansible: R e pastas na geradora; PostgreSQL, esquema do DW e painel na exibição.
4. Transfere o simulador para a VM geradora por SCP.
5. Gera dois lotes de 1.000 vendas e valida os arquivos.
6. Repete a configuração para mostrar que não há mudanças desnecessárias.

Os dois lotes demonstram que uma nova execução preserva os dados anteriores.
A última execução do Ansible deve mostrar `changed=0`, `unreachable=0` e `failed=0` **nas duas VMs**.
A primeira configuração da VM de exibição instala PostgreSQL e os pacotes R do painel: pode levar vários minutos em TCG.
“Aguardando SSH” significa que o script está esperando a conexão remota ficar disponível.
SSH é a conexão entre o terminal do host e a VM, não o nome da resposta da VM.

O primeiro boot pode levar vários minutos, principalmente em TCG. Para acompanhar em outro terminal:

```bash
tail -f ~/.local/share/pi-track-field-p1/console.log
tail -f ~/.local/share/pi-track-field-p1/exibicao/console.log
```

O primeiro comando acompanha a VM geradora; o segundo, a de exibição. Ctrl+C encerra apenas o acompanhamento.

Quem já tinha criado a VM única da versão anterior: o próximo `criar` transforma essa VM na geradora
(o OpenTofu a recria, porque o controlador mudou, e guarda o disco antigo em `arquivo-*`) e cria a VM de exibição.

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

## 6. Copiar os dados para o computador e desligar as VMs

```bash
bash infraestrutura/p1.sh baixar
bash infraestrutura/p1.sh parar todas
```

O terminal mostrará `Dados copiados para .../infraestrutura/evidencias/dados-DATA-ID`.
Dentro dessa pasta existe a subpasta `dados`, com os lotes `exec-*` e seus CSVs.
Anote o caminho informado: ele será a entrada do processamento.

Dentro da VM geradora, os originais ficam em `/opt/pi-track-field/dados/exec-*/vendas.csv`.
No host, ficam em `infraestrutura/evidencias/dados-DATA-ID/dados/exec-*/vendas.csv`.
Desligar as VMs preserva seus arquivos e o conteúdo do Data Warehouse.

## 7. Processar os lotes com Spark e HDFS

Substitua `dados-DATA-ID` pelo nome exato mostrado na etapa anterior:

```bash
bash scripts/pipeline_bigdata.sh infraestrutura/evidencias/dados-DATA-ID/dados hdfs
```

Não digite literalmente `DATA-ID`. Por exemplo, se o download criou
`dados-20260929T120000-1234`, use `infraestrutura/evidencias/dados-20260929T120000-1234/dados`.

O pipeline inicia o HDFS, ingere os CSVs, trata os dados no Spark e gera a análise R.
Espere a mensagem **Pipeline concluido** antes de seguir.

O fluxo é um **ETL de Data Warehouse**. Os nomes das pastas no disco e no HDFS ficam entre parênteses:

- **Staging** (`bronze`): CSVs originais, entrada normalizada e manifesto da origem.
- **Integração** (`silver`): vendas validadas e tipadas, em Parquet.
- **Modelo dimensional do DW** (`gold`): `fato_vendas` e as dimensões produto, canal, região e data,
  exportadas em `results/bigdata/exec-*/dw/*.csv` para a carga no PostgreSQL.
- **Quarentena:** registros rejeitados e seus motivos.

A chave de cada venda combina o lote e o número do pedido. Lotes novos podem reutilizar os números.
Repetir o mesmo arquivo não cria outro lote em staging. Cada processamento gera um novo retrato
completo dos lotes conhecidos; não some resultados de execuções diferentes.

Spark usa DataFrames e SQL. HDFS usa um NameNode e um DataNode, com replicação 1.
Tudo roda no mesmo host Ubuntu: é uma demonstração, sem alta disponibilidade ou comprovação de escala em vários servidores.

Para executar Spark sem HDFS, use `local` no lugar de `hdfs`. Nesse caso, os Parquets ficam no disco local.

## 8. Carregar o Data Warehouse e abrir o painel na VM de exibição

```bash
bash infraestrutura/p1.sh iniciar exibicao
bash infraestrutura/p1.sh publicar
```

`publicar` copia o modelo estrela da última execução Spark para a VM de exibição, carrega-o no
PostgreSQL em uma única transação e reinicia o painel. Se a carga falhar, o DW mantém a carga anterior.
Para carregar outra execução, informe o identificador: `bash infraestrutura/p1.sh publicar exec-...`.

Abra **http://localhost:8080** no navegador do mesmo computador. O painel roda **dentro da VM de exibição**
como serviço (`pi-painel`) e lê os dados do Data Warehouse; o terminal pode ser fechado.
O rodapé de dados mostra a execução carregada. Depois de uma nova publicação, a página recarregada já usa o DW atualizado;
o botão **Recarregar do Data Warehouse** faz o mesmo sem recarregar a página.

Na primeira demonstração, os dois lotes devem resultar em 2.000 vendas válidas.
Execuções posteriores podem conter mais vendas, porque preservam os lotes anteriores.
Para conferir as VMs, o PostgreSQL, o serviço do painel e a última carga: `bash infraestrutura/p1.sh validar`.
Para consultar o DW diretamente:

```bash
bash infraestrutura/p1.sh ssh exibicao
psql -d dw_vendas -c "SELECT categoria, count(*), sum(valor_total) FROM dw.vw_vendas GROUP BY categoria"
```

Use os filtros por período, categoria, canal e região. Seleção vazia inclui todos os grupos.
As abas apresentam visão geral, destaques, previsões e pedidos. “Salvar esta análise” grava uma pasta
com os dados filtrados, estatísticas, gráficos, relatório e previsão quando houver histórico suficiente.

### Por que a previsão pode repetir o mesmo valor?

Na aba **Próximos meses**, o modo **Automático** escolhe o modelo que teve menor erro nos testes:

- Média histórica: repete a média nos meses futuros.
- Último mês: repete o último valor, com incerteza crescente.
- Tendência linear: projeta crescimento ou queda conforme o histórico.

Uma linha constante é válida quando um modelo constante vence a comparação. Ela não afirma que
as vendas reais serão iguais. O simulador gera sazonalidade e crescimento leve, mas um ano de histórico
não permite estimar a sazonalidade anual: os picos de novembro e dezembro aparecem como erro dos modelos.

Para comparar uma projeção que acompanha a direção do histórico, clique em
**Comparar tendência de crescimento ou queda**. O gráfico, a tabela e o download usam essa escolha.
O painel continua informando qual modelo teve o menor erro. Se a tendência tiver erro maior,
a escolha manual é uma comparação exploratória, não uma melhoria comprovada da previsão.
Uma tendência praticamente nula também pode produzir valores muito próximos.

São necessários pelo menos oito meses completos. Meses parciais das extremidades ficam fora do ajuste.
Meses sem registros só são tratados como zero quando você confirma essa interpretação.
Os testes avaliam um mês à frente; não validam automaticamente todo o horizonte de seis meses.
As faixas nominais de 95% dependem das hipóteses dos modelos. Não se estima sazonalidade anual com esse histórico curto.

Após uma atualização do código do painel, execute `bash infraestrutura/p1.sh configurar`:
o Ansible copia o código novo para a VM de exibição e reinicia o serviço.

## 9. Encerrar corretamente

```bash
bash infraestrutura/bigdata/hdfs.sh parar
bash infraestrutura/p1.sh parar todas
bash infraestrutura/p1.sh status
```

Encerre os serviços antes de fechar o terminal Ubuntu ou desligar o computador.
O Data Warehouse fica no disco da VM de exibição: ao ligá-la de novo, o painel volta com a última carga.

## 10. Usar novamente em outro dia

Os comandos `cd` desta seção usam o destino definido no clone da etapa 2.
Se seu projeto já estava em outro local, use o caminho real que você conferiu nessa etapa.

Para apenas consultar o painel com os dados já carregados no Data Warehouse:

```bash
cd "$HOME/PI-Data-Science-Track-Field"
bash infraestrutura/p1.sh iniciar exibicao
```

Para gerar mais dados e atualizar a análise:

```bash
cd "$HOME/PI-Data-Science-Track-Field"
bash infraestrutura/p1.sh iniciar geradora
bash infraestrutura/p1.sh transferir
bash infraestrutura/p1.sh simular
bash infraestrutura/p1.sh baixar
bash infraestrutura/p1.sh parar geradora
```

A transferência atualiza o código na VM geradora. Depois processe a nova pasta indicada por `baixar`
e carregue o resultado no Data Warehouse:

```bash
bash scripts/pipeline_bigdata.sh infraestrutura/evidencias/dados-NOVA-DATA-ID/dados hdfs
bash infraestrutura/bigdata/hdfs.sh parar
bash infraestrutura/p1.sh iniciar exibicao
bash infraestrutura/p1.sh publicar
```

Ao terminar, siga a etapa 9. Não é necessário repetir as instalações a cada uso.

## 11. Onde fica cada coisa?

| Caminho | Responsabilidade |
|---|---|
| `infraestrutura/preparar-host.sh` | instala ferramentas das VMs no host |
| `infraestrutura/p1.sh` | cria, configura, acessa e controla as VMs; gera dados e publica no DW |
| `infraestrutura/vm.sh` | recursos, portas e ciclo de vida de cada VM no QEMU |
| `infraestrutura/main.tf` | infraestrutura como código com OpenTofu (as duas VMs) |
| `infraestrutura/cloud-init.yaml.tftpl` | usuário e configuração inicial das VMs |
| `infraestrutura/ansible/playbook.yml` | geradora: R e pastas · exibição: PostgreSQL, DW e serviço do painel |
| `dw/esquema.sql` | tabelas do Data Warehouse (modelo estrela) e visão `dw.vw_vendas` |
| `dw/carregar.sql` | carga transacional do DW a partir dos CSVs do Spark |
| `R/dw.R` | leitura do Data Warehouse pelo painel |
| `simulador/gerar_dados.R` | gera vendas simuladas dentro da VM geradora |
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
| `notebooks/analise_track_field.ipynb` | análise completa: dicionário, EDA, OLAP, ML e insights |
| `docs/dicionario-dados.md` | dicionário de dados e hipóteses do simulador |
| `tests/` | testes automatizados |

| Resultado | Local |
|---|---|
| CSVs copiados da VM geradora | `infraestrutura/evidencias/dados-*/dados/exec-*/vendas.csv` |
| Staging local (originais) | `data/lake/bronze/<hash>/original.csv` |
| Camadas do ETL no HDFS | `hdfs://127.0.0.1:19000/pi-track-field/` |
| Camadas do ETL no modo local | `data/lake/` |
| Resultados Spark | `results/bigdata/exec-*/` |
| Modelo estrela para a carga do DW | `results/bigdata/exec-*/dw/*.csv` |
| Data Warehouse | banco `dw_vendas`, esquema `dw`, na VM de exibição |
| Cargas recebidas pela VM de exibição | `/opt/pi-track-field/carga/exec-*/` |
| Identificador da publicação atual | `results/bigdata/ultima.txt` |
| Relatório, gráficos e estatísticas R | caminho indicado em `analise_r.txt` na pasta Spark |
| Logs e estado de sucesso/falha | `results/monitoramento/` |
| Logs da P1 | `infraestrutura/evidencias/demonstracao-*.txt` |

`resumo.csv` mostra recebidos, duplicados, rejeitados, aceitos e faturamento.
`consultas.sql` registra as consultas executadas; `integridade_modelo.csv` confere as relações das tabelas.
As estatísticas incluem média, mediana, moda, variância, desvio, quartis e frequências.
Os testes usam Kruskal-Wallis, Spearman e qui-quadrado, com ajuste de Holm.
Associação estatística não comprova causa; a base sintética demonstra o método.

Discos e chaves da VM geradora ficam em `~/.local/share/pi-track-field-p1/`; os da VM de exibição,
na subpasta `exibicao/`. As duas VMs usam a mesma chave SSH dedicada.
O PostgreSQL só aceita conexões locais da própria VM, autenticadas pelo usuário do sistema: não há senha no projeto.
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
Também confere a exportação do modelo estrela para o DW: 37 vendas na fato e todas as chaves presentes nas dimensões.
O teste deve terminar com as mensagens de verificação bem-sucedida.

Na VM de exibição, a leitura real do Data Warehouse pode ser testada após uma carga:
`PI_DW_TESTE=dw_vendas Rscript tests/executar.R` (exige o código de testes copiado para a VM).

Em 29/09/2026 também foram validados oito lotes da VM: 8.000 vendas, faturamento simulado
de R$ 5.003.880,21 e carregamento automático no Shiny. Esses valores são da versão anterior do
simulador, com sorteio uniforme; a versão atual gera padrões e produz outros totais.
Seus valores também variam porque o comando `simular` gera novas sementes. O ambiente usado foi Ubuntu 26.04.1 em WSL e R 4.5.2;
a VM convidada usa Ubuntu 24.04. Os testes não representam uma instalação validada em toda versão de Ubuntu.

## 13. Resolver problemas comuns

| Situação | O que fazer |
|---|---|
| `No such file or directory` no `cd` ou ao chamar um script | siga a localização da pasta na etapa 2; confira maiúsculas/minúsculas e confirme com `pwd` e `ls` |
| Nenhum `vendas.csv` encontrado | confira o caminho informado por `baixar` e inclua a subpasta `dados` |
| Aguardando SSH por vários minutos | acompanhe o console da VM; TCG pode demorar no primeiro boot |
| Quer entrar em uma VM | `bash infraestrutura/p1.sh ssh geradora` ou `ssh exibicao`; use `exit` para voltar ao host |
| Porta 8080 ocupada | encerre o processo que usa a porta no host antes de iniciar a VM de exibição |
| Painel não abre em `localhost:8080` | `bash infraestrutura/p1.sh validar`; na VM: `journalctl -u pi-painel -n 50` |
| Painel mostra “Data Warehouse sem carga” | rode o pipeline e depois `bash infraestrutura/p1.sh publicar` |
| Carga do DW falhou | leia a mensagem do `psql`; a transação foi desfeita e a carga anterior continua ativa |
| Mudança no código do painel não aparece | `bash infraestrutura/p1.sh configurar` copia o código e reinicia o serviço |
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

Para desenvolver o painel no próprio host, sem as VMs, bastam Git, R e os pacotes R da etapa 4:
execute `bash painel/iniciar.sh` (porta 8080 do host; use `bash painel/iniciar.sh 8081` se a VM de exibição estiver ligada).
Esse modo lê a última execução Spark local ou usa uma simulação de demonstração, sem o Data Warehouse.
Ele não é o modo de apresentação: no projeto, o painel roda na VM de exibição.

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

## 15. Notebook de análise

`notebooks/analise_track_field.ipynb` reúne a análise da entrega final em R: identificação da base,
dicionário de dados, limpeza, estatística descritiva, gráficos com interpretação, testes, operações OLAP,
Machine Learning (itens por pedido: médias, GLM Poisson e Random Forest com validação cruzada),
previsão mensal e insights para a situação-problema.

Ele executa do início ao fim sem arquivos locais: gera a base com `gerar_vendas(5000, 42)`.

- **Google Colab:** abra o arquivo pelo GitHub, mude o tipo de ambiente para **R** e use *Executar tudo*.
  Os módulos de `R/` são baixados do branch `main`; envie as alterações ao GitHub antes.
- **Jupyter local:** instale o kernel R e abra o notebook a partir da pasta `notebooks/`:

```bash
sudo apt install -y jupyter-notebook r-cran-irkernel r-cran-randomforest
jupyter notebook notebooks/analise_track_field.ipynb
```

Pacotes R usados: `ggplot2` e `randomForest`; o notebook instala o que faltar.
Para analisar a última publicação Spark do mesmo clone, altere `USAR_SPARK <- TRUE` na primeira célula.

O simulador planta padrões didáticos (sazonalidade, canal por categoria, efeito do desconto na quantidade),
documentados em `docs/dicionario-dados.md`. As conclusões demonstram o método; não descrevem a Track & Field real.

## 16. Entrega acadêmica

O código e os testes não substituem as atividades do grupo. Ainda é necessário registrar
problema e beneficiário, consentimento, integrantes e responsabilidades, cronograma, reuniões,
sprint reports, vídeo de carreiras e relatório individual de extensão, conforme a orientação do PI.
O vídeo exige participação real dos integrantes e não deve ser produzido por IA.
Não alegue parceria ou benefício comercial real sem evidência.

Os documentos em `docs/` preservam arquitetura, metodologia e evidências de validação.
São material complementar; todas as instruções para executar o projeto estão neste README.
Antes de testar em outra máquina, faça commit e envie as alterações revisadas ao repositório.
Não é necessário enviar discos da VM ou resultados gerados para que o projeto possa ser reproduzido.
