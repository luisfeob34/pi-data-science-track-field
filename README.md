# PI - Data Science - Track & Field

Projeto Integrado de Ciência da Computação - 2º semestre de 2026.

## Empresa

Track & Field

## Projeto

Automação e Escalabilidade de Pipelines de Big Data e Análise de Dados.

## Descrição

Projeto desenvolvido para análise de dados de vendas da Track & Field,
utilizando conceitos de Análise Exploratória de Dados, Big Data,
DevOps e Probabilidade e Estatística.

O projeto busca construir um pipeline de dados organizado, automatizado
e reproduzível, permitindo a geração, tratamento, processamento, análise
e visualização dos dados.

Os dados utilizados atualmente são dados fictícios gerados pelo próprio
projeto para fins acadêmicos.

---

# Pipeline de dados

O fluxo atual do projeto é:

```text
gerar_dados.py
      |
      v
data/raw/vendas_simuladas.csv
      |
      v
tratar_dados.py
      |
      v
data/processed/vendas_processadas.csv
      |
      +--------------------+
      |                    |
      v                    v
analisar_dados.py    processar_spark.py
      |                    |
      v                    v
Análise Exploratória    Apache Spark
      |                 DataFrame API
      |                 Spark SQL
      v
gerar_graficos.py
      |
      v
results/graficos/
```

Cada script possui uma responsabilidade específica:

- `gerar_dados.py` - gera dados fictícios de vendas;
- `tratar_dados.py` - realiza limpeza, validação e transformação dos dados;
- `analisar_dados.py` - realiza a Análise Exploratória de Dados (EDA);
- `gerar_graficos.py` - gera visualizações a partir dos dados processados;
- `processar_spark.py` - realiza processamento utilizando Apache Spark,
  Spark DataFrames e Spark SQL.

---

# Estrutura do projeto

```text
PI-Data-Science-Track-Field/
|
├── data/
│   ├── raw/
│   │   └── vendas_simuladas.csv
│   │
│   └── processed/
│       └── vendas_processadas.csv
│
├── docs/
│
├── infra/
│   ├── ansible/
│   │   ├── inventory.ini
│   │   └── playbook.yml
│   │
│   ├── kubernetes/
│   │   └── namespace.yml
│   │
│   └── monitoring/
│       └── README.md
│
├── notebooks/
│
├── results/
│   ├── graficos/
│   └── spark/
│
├── scripts/
│   ├── gerar_dados.py
│   ├── tratar_dados.py
│   ├── analisar_dados.py
│   ├── gerar_graficos.py
│   └── processar_spark.py
│
├── src/
│
├── .dockerignore
├── .gitignore
├── Dockerfile
├── README.md
└── requirements.txt
```

## Diretórios

- `data/raw/` - dados brutos gerados ou recebidos pelo pipeline;
- `data/processed/` - dados após limpeza e transformação;
- `docs/` - documentação complementar;
- `infra/` - arquivos relacionados à infraestrutura e DevOps;
- `infra/ansible/` - automação da configuração do ambiente Linux;
- `infra/kubernetes/` - manifestos Kubernetes;
- `infra/monitoring/` - documentação relacionada ao monitoramento;
- `notebooks/` - notebooks utilizados nas análises;
- `results/graficos/` - gráficos produzidos pela análise;
- `results/spark/` - resultados produzidos pelo Apache Spark;
- `scripts/` - scripts responsáveis pelo pipeline;
- `src/` - código-fonte adicional relacionado ao processamento.

---

# Tecnologias utilizadas

## Desenvolvimento e dados

- Python 3.14
- Pandas 2.3.3
- NumPy 2.5.3
- Faker 40.39.0
- Matplotlib 3.11.2

## Big Data

- Apache Spark
- PySpark 4.2.0
- Spark DataFrame API
- Spark SQL
- Java OpenJDK 17

## Versionamento

- Git
- GitHub

## Ambiente

- Linux
- Ubuntu
- WSL2 em computadores Windows
- Python Virtual Environment (`venv`)

## DevOps e infraestrutura

- Ansible
- Docker
- Kubernetes
- Minikube
- kubectl
- Helm

## Monitoramento

- Prometheus

---

# Arquitetura da infraestrutura

O projeto foi estruturado para execução em ambiente Linux.

Durante o desenvolvimento foi utilizado Ubuntu através do WSL2 em um
computador Windows.

Caso o computador já utilize Linux nativamente, o WSL2 não é necessário.

O Git é utilizado para controle de versão e o GitHub para armazenamento
e compartilhamento do repositório.

O Ansible é utilizado para automatizar parte da preparação do ambiente.

O Docker é utilizado para criar ambientes isolados e reproduzíveis.

O Kubernetes é utilizado para orquestração dos containers. No ambiente
local de desenvolvimento, o Kubernetes é executado através do Minikube
utilizando Docker como driver.

O Helm é utilizado para instalação e gerenciamento de aplicações no
Kubernetes.

O Prometheus é utilizado para monitoramento da infraestrutura.

```text
GitHub
   |
   v
Linux / Ubuntu
   |
   +---- Ansible
   |
   v
Docker
   |
   v
Aplicação / Pipeline
   |
   v
Kubernetes / Minikube
   |
   +---- Prometheus
            |
            v
       Monitoramento
```

---

# Executando o projeto em outro computador

Esta seção apresenta o procedimento completo para clonar, configurar
e executar o projeto em outro computador.

Existem duas situações:

- computador com Linux;
- computador com Windows utilizando WSL2.

---

# 1. Preparar o sistema operacional

## Opção A - Linux

Se o computador já utiliza uma distribuição Linux, como Ubuntu, não é
necessário instalar WSL.

Continue para a atualização dos pacotes.

## Opção B - Windows

No Windows, o projeto pode ser executado utilizando Linux através do WSL2.

Abra o PowerShell como **Administrador** e execute:

```powershell
wsl --install
```

Reinicie o computador caso seja solicitado.

Depois abra o Ubuntu e finalize a configuração inicial criando usuário
e senha.

Para verificar o WSL:

```powershell
wsl --status
```

Depois disso, os próximos comandos devem ser executados dentro do
terminal Ubuntu/WSL.

---

# 2. Atualizar os pacotes do Linux

```bash
sudo apt update
```

Opcionalmente:

```bash
sudo apt upgrade -y
```

---

# 3. Instalar o Git

```bash
sudo apt install git -y
```

Verifique:

```bash
git --version
```

---

# 4. Instalar Python e suporte a ambientes virtuais

```bash
sudo apt install python3 python3-pip python3-venv -y
```

Verifique:

```bash
python3 --version
```

---

# 5. Instalar Java 17

O Apache Spark necessita de Java.

Instale o OpenJDK 17:

```bash
sudo apt install openjdk-17-jdk -y
```

Verifique:

```bash
java -version
```

A saída deverá indicar uma versão do OpenJDK 17.

---

# 6. Instalar Docker

```bash
sudo apt install docker.io -y
```

Verifique:

```bash
docker --version
```

Caso o Docker não esteja iniciado:

```bash
sudo service docker start
```

Adicione o usuário atual ao grupo Docker:

```bash
sudo usermod -aG docker $USER
```

Depois feche e abra novamente o terminal.

Também é possível aplicar o novo grupo na sessão atual:

```bash
newgrp docker
```

Caso `newgrp` não esteja disponível:

```bash
sudo apt install util-linux-extra -y
```

Depois:

```bash
newgrp docker
```

Teste:

```bash
docker run hello-world
```

O resultado esperado contém:

```text
Hello from Docker!
```

---

# 7. Clonar o projeto

```bash
git clone https://github.com/luisfeob34/pi-data-science-track-field.git
```

Entre na pasta:

```bash
cd pi-data-science-track-field
```

---

# 8. Criar o ambiente virtual Python

Na raiz do projeto:

```bash
python3 -m venv .venv
```

Ative:

```bash
source .venv/bin/activate
```

Quando estiver ativo, o terminal apresentará algo semelhante a:

```text
(.venv) usuario@computador:~/pi-data-science-track-field$
```

Caso o ambiente virtual tenha sido criado no diretório HOME:

```bash
source ~/.venv/bin/activate
```

Para sair do ambiente virtual:

```bash
deactivate
```

---

# 9. Instalar as dependências Python

Com a `.venv` ativada:

```bash
python -m pip install --upgrade pip
```

Depois:

```bash
python -m pip install -r requirements.txt
```

## Possível problema ao instalar PySpark

O pacote PySpark pode utilizar bastante espaço temporário durante a
instalação.

Caso apareça:

```text
No space left on device
```

mesmo existindo espaço livre no disco, crie uma pasta temporária no
diretório HOME:

```bash
mkdir -p ~/tmp
```

Depois execute:

```bash
TMPDIR=~/tmp python -m pip install -r requirements.txt
```

---

# 10. Dependências Python

O arquivo `requirements.txt` contém:

```text
pandas==2.3.3
numpy==2.5.3
Faker==40.39.0
matplotlib==3.11.2
pyspark==4.2.0
```

Não é necessário instalar essas bibliotecas individualmente.

---

# 11. Testar o Apache Spark

Com a `.venv` ativa:

```bash
python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.master('local[*]').appName('TesteSpark').getOrCreate(); print('Spark funcionando! Versão:', spark.version); spark.stop()"
```

O resultado deverá conter:

```text
Spark funcionando! Versão: 4.2.0
```

Alguns avisos (`WARN`) podem aparecer durante a inicialização local do
Spark sem impedir seu funcionamento.

---

# 12. Gerar os dados

Execute:

```bash
python scripts/gerar_dados.py
```

Por padrão são geradas 1000 vendas fictícias.

O resultado será:

```text
data/raw/vendas_simuladas.csv
```

É possível gerar outra quantidade:

```bash
python scripts/gerar_dados.py --quantidade 10000
```

---

# 13. Tratar os dados

Execute:

```bash
python scripts/tratar_dados.py
```

O script realiza:

- remoção de registros duplicados;
- tratamento de valores ausentes;
- validação de dados numéricos;
- validação das datas;
- padronização de textos;
- cálculo de valor bruto;
- cálculo do valor de desconto;
- recálculo do valor total;
- classificação dos descontos;
- classificação do porte dos pedidos;
- classificação das faixas de valor;
- criação de variáveis temporais.

Entre as variáveis derivadas estão:

```text
Valor Bruto
Valor Desconto
Possui Desconto
Desconto Percentual
Faixa de Desconto
Valor por Item
Porte do Pedido
Faixa de Valor
Ano
Número do Mês
Mês
Trimestre
Dia da Semana
```

O resultado será:

```text
data/processed/vendas_processadas.csv
```

---

# 14. Executar a Análise Exploratória de Dados

Execute:

```bash
python scripts/analisar_dados.py
```

A análise apresenta:

- dimensões da base;
- tipos das variáveis;
- qualidade dos dados;
- estatísticas descritivas;
- faturamento;
- descontos;
- quantidade de itens;
- ticket médio;
- análise por produto;
- análise por categoria;
- análise por canal;
- análise por região;
- análise mensal;
- análise trimestral;
- análise por dia da semana;
- correlações;
- identificação de possíveis valores atípicos.

---

# 15. Gerar os gráficos

Execute:

```bash
python scripts/gerar_graficos.py
```

São produzidos 10 gráficos:

```text
01_faturamento_produto.png
02_faturamento_categoria.png
03_faturamento_canal.png
04_faturamento_regiao.png
05_faturamento_mensal.png
06_distribuicao_valor_pedidos.png
07_pedidos_faixa_desconto.png
08_quantidade_valor_total.png
09_boxplot_valor_total.png
10_matriz_correlacao.png
```

Eles são armazenados em:

```text
results/graficos/
```

---

# 16. Executar o processamento com Apache Spark

Execute:

```bash
python scripts/processar_spark.py
```

O script carrega:

```text
data/processed/vendas_processadas.csv
```

como um Spark DataFrame.

O processamento utiliza:

- Spark DataFrame API;
- agregações;
- `groupBy`;
- `SUM`;
- `AVG`;
- `COUNT`;
- ordenações;
- views temporárias;
- Spark SQL.

São realizadas análises de:

- indicadores gerais;
- faturamento por produto;
- faturamento por categoria;
- faturamento por região;
- faturamento por canal;
- faturamento mensal;
- consultas utilizando Spark SQL.

Os resultados são armazenados em:

```text
results/spark/
```

O Spark normalmente grava resultados CSV como diretórios contendo
arquivos `part-*.csv` e `_SUCCESS`.

Esse comportamento é normal.

---

# 17. Execução completa do pipeline

Depois de configurar o ambiente, o pipeline pode ser executado nesta ordem:

```bash
python scripts/gerar_dados.py
python scripts/tratar_dados.py
python scripts/analisar_dados.py
python scripts/gerar_graficos.py
python scripts/processar_spark.py
```

Fluxo:

```text
Dados fictícios
      |
      v
gerar_dados.py
      |
      v
data/raw/vendas_simuladas.csv
      |
      v
tratar_dados.py
      |
      v
data/processed/vendas_processadas.csv
      |
      +-------------------------+
      |            |            |
      v            v            v
    EDA         Gráficos       Spark
      |            |            |
      v            v            v
analisar_     results/      results/
dados.py      graficos/      spark/
```

---

# Docker

O projeto possui um `Dockerfile` utilizado para criar um ambiente
isolado para execução do gerador de dados.

Construir a imagem:

```bash
docker build -t pi-track-field .
```

Executar o gerador:

```bash
docker run --rm \
  -v "$(pwd)/data/raw:/app/data/raw" \
  pi-track-field
```

O volume:

```text
-v "$(pwd)/data/raw:/app/data/raw"
```

faz a ligação:

```text
Computador                    Container

data/raw/       <-------->     /app/data/raw/
```

Assim o CSV permanece no computador após o encerramento do container.

> Observação: a execução completa do pipeline com Apache Spark está
> documentada atualmente através do ambiente Python/venv + Java 17.
> O uso do Docker nesta configuração está destinado ao gerador de dados.

---

# Ansible

Os arquivos estão disponíveis em:

```text
infra/ansible/
```

Estrutura:

```text
infra/ansible/
├── inventory.ini
└── playbook.yml
```

O inventário utiliza a máquina Linux local.

## Testar comunicação

```bash
ansible all -i infra/ansible/inventory.ini -m ping
```

Resultado esperado:

```text
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Validar o playbook

```bash
ansible-playbook \
  -i infra/ansible/inventory.ini \
  infra/ansible/playbook.yml \
  --syntax-check
```

## Executar o playbook

```bash
ansible-playbook \
  -i infra/ansible/inventory.ini \
  infra/ansible/playbook.yml \
  --ask-become-pass
```

---

# Kubernetes

O Kubernetes é utilizado para orquestração dos containers e serviços.

No ambiente local é utilizado Minikube com Docker como driver.

```text
Docker
   |
   v
Minikube
   |
   v
Kubernetes
```

## Iniciar o cluster

```bash
minikube start --driver=docker
```

## Verificar

```bash
minikube status
```

## Aplicar os recursos

```bash
kubectl apply -f infra/kubernetes/namespace.yml
```

## Verificar namespaces

```bash
kubectl get namespaces
```

O namespace utilizado pelo monitoramento é:

```text
monitoramento
```

---

# Monitoramento com Prometheus

O Prometheus é utilizado para monitorar a infraestrutura e coletar
métricas dos serviços executados no Kubernetes.

A instalação é realizada através do Helm.

## Adicionar o repositório

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## Atualizar

```bash
helm repo update
```

## Instalar

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoramento
```

## Verificar

```bash
kubectl get pods -n monitoramento
```

Os componentes deverão apresentar estado `Running` após a inicialização.

## Acessar a interface

```bash
kubectl port-forward \
  -n monitoramento \
  svc/prometheus-server \
  9090:80
```

Com o redirecionamento ativo, o Prometheus pode ser acessado localmente
através da porta `9090`.

---

# Validações realizadas

Durante o desenvolvimento foram realizados os seguintes testes:

- [x] Ambiente Linux Ubuntu através do WSL2
- [x] Git
- [x] GitHub
- [x] Python 3.14
- [x] Ambiente virtual Python
- [x] Pandas 2.3.3
- [x] NumPy 2.5.3
- [x] Faker 40.39.0
- [x] Matplotlib 3.11.2
- [x] Java OpenJDK 17
- [x] PySpark 4.2.0
- [x] Inicialização do Apache Spark
- [x] Instalação das dependências pelo `requirements.txt`
- [x] Execução do gerador de dados
- [x] Geração do `vendas_simuladas.csv`
- [x] Tratamento dos dados
- [x] Geração do `vendas_processadas.csv`
- [x] Análise Exploratória de Dados
- [x] Geração de 10 gráficos
- [x] Processamento utilizando Spark DataFrames
- [x] Consultas utilizando Spark SQL
- [x] Persistência dos resultados do Spark
- [x] Comunicação do Ansible com Linux
- [x] Ansible retornando `ping: pong`
- [x] Validação do playbook Ansible
- [x] Docker
- [x] Execução do `hello-world`
- [x] Construção da imagem `pi-track-field`
- [x] Execução do gerador dentro do Docker
- [x] Minikube
- [x] Kubernetes
- [x] kubectl
- [x] Namespace Kubernetes
- [x] Helm
- [x] Prometheus
- [x] Pods do Prometheus em estado `Running`
- [x] Acesso à interface do Prometheus
- [x] Versionamento com Git
- [x] Repositório armazenado no GitHub

---

# Reprodutibilidade

O objetivo da infraestrutura DevOps é permitir que o projeto seja
executado em diferentes computadores reduzindo diferenças entre os
ambientes.

Para a execução completa do pipeline são utilizados:

```text
Linux / Ubuntu
      |
      +---- Git
      |
      +---- Python / venv
      |
      +---- requirements.txt
      |
      +---- Java 17
      |
      +---- Apache Spark / PySpark
      |
      +---- Pipeline de dados
```

Para computadores Windows:

```text
Windows
   |
   v
WSL2
   |
   v
Ubuntu
   |
   v
Ambiente do projeto
```

O `requirements.txt` mantém as versões das bibliotecas Python utilizadas.

O schema dos dados utilizados pelo Spark é definido explicitamente pelo
projeto, evitando depender exclusivamente da inferência automática de
tipos.

---

# Resultados produzidos

Após executar o pipeline completo, os principais arquivos estarão em:

```text
data/
├── raw/
│   └── vendas_simuladas.csv
│
└── processed/
    └── vendas_processadas.csv

results/
├── graficos/
│   ├── 01_faturamento_produto.png
│   ├── 02_faturamento_categoria.png
│   ├── 03_faturamento_canal.png
│   ├── 04_faturamento_regiao.png
│   ├── 05_faturamento_mensal.png
│   ├── 06_distribuicao_valor_pedidos.png
│   ├── 07_pedidos_faixa_desconto.png
│   ├── 08_quantidade_valor_total.png
│   ├── 09_boxplot_valor_total.png
│   └── 10_matriz_correlacao.png
│
└── spark/
    ├── faturamento_produto/
    ├── faturamento_categoria/
    ├── faturamento_regiao/
    ├── faturamento_canal/
    ├── faturamento_mensal/
    └── spark_sql_categoria/
```

---

# Status atual

Atualmente estão configurados e testados:

- [x] Linux / Ubuntu / WSL2
- [x] Git e GitHub
- [x] Python
- [x] Ambiente virtual
- [x] Dependências Python
- [x] Gerador de dados
- [x] Tratamento dos dados
- [x] Análise Exploratória de Dados
- [x] Visualizações com Matplotlib
- [x] Apache Spark
- [x] PySpark
- [x] Spark DataFrame API
- [x] Spark SQL
- [x] Java 17
- [x] Ansible
- [x] Docker
- [x] Dockerfile
- [x] Kubernetes
- [x] Minikube
- [x] kubectl
- [x] Helm
- [x] Prometheus
- [x] Monitoramento
- [x] Documentação de execução
- [x] Ambiente reproduzível

A infraestrutura e o pipeline poderão ser expandidos conforme novos
componentes forem adicionados durante o desenvolvimento do projeto.