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
e reproduzível, permitindo a geração, processamento, análise e
monitoramento dos dados.

---

# Estrutura do projeto

```text
PI-Data-Science-Track-Field/
│
├── data/
│   ├── raw/
│   └── processed/
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
├── results/
│
├── scripts/
│   └── gerar_dados.py
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

- `data/raw/` - Dados brutos gerados ou recebidos pelo pipeline.
- `data/processed/` - Dados após limpeza e transformação.
- `docs/` - Documentação complementar do projeto.
- `infra/` - Arquivos relacionados à infraestrutura e DevOps.
- `infra/ansible/` - Automação da configuração do ambiente Linux.
- `infra/kubernetes/` - Manifestos do Kubernetes.
- `infra/monitoring/` - Documentação relacionada ao monitoramento.
- `notebooks/` - Notebooks utilizados nas análises.
- `results/` - Resultados, relatórios e visualizações.
- `scripts/` - Scripts de geração e automação.
- `src/` - Código-fonte relacionado ao processamento dos dados.

---

# Tecnologias utilizadas

## Desenvolvimento e dados

- Python 3.14
- Pandas 3.0.6
- NumPy 2.5.3
- Faker 40.39.0

## Versionamento

- Git
- GitHub

## Ambiente

- Linux
- Ubuntu via WSL2 em computadores Windows
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

O Docker é utilizado para criar um ambiente padronizado e reproduzível
para execução da aplicação.

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

Esta seção apresenta o procedimento necessário para executar o projeto
e gerar os dados em outro computador.

Para gerar os dados utilizando Docker são necessários apenas:

- Ambiente Linux;
- Git;
- Docker;
- Acesso à internet.

Não é necessário instalar manualmente Python, Pandas, NumPy ou Faker
para executar através do Docker.

O `Dockerfile` e o `requirements.txt` são responsáveis por configurar
essas dependências dentro da imagem Docker.

---

# 1. Preparar o sistema operacional

Existem dois cenários possíveis.

## Opção A - Computador com Linux

Se o computador já utiliza uma distribuição Linux, como Ubuntu, não é
necessário instalar WSL.

Continue diretamente para a instalação do Git e Docker.

## Opção B - Computador com Windows

Caso o computador utilize Windows, o projeto pode ser executado em Linux
através do WSL2.

Abra o PowerShell como **Administrador** e execute:

```powershell
wsl --install
```

Reinicie o computador caso seja solicitado.

Depois, abra o Ubuntu e finalize a configuração inicial criando um
usuário e uma senha para o ambiente Linux.

Para verificar:

```powershell
wsl --status
```

A partir desse momento, os próximos comandos devem ser executados dentro
do terminal Ubuntu/WSL.

---

# 2. Atualizar os pacotes do Linux

No terminal Linux/Ubuntu:

```bash
sudo apt update
```

Opcionalmente, atualize os pacotes instalados:

```bash
sudo apt upgrade -y
```

---

# 3. Instalar o Git

Execute:

```bash
sudo apt install git -y
```

Verifique a instalação:

```bash
git --version
```

Se uma versão for exibida, o Git está instalado corretamente.

Exemplo:

```text
git version 2.x.x
```

---

# 4. Instalar o Docker

Execute:

```bash
sudo apt install docker.io -y
```

Verifique:

```bash
docker --version
```

Caso o Docker ainda não esteja iniciado:

```bash
sudo service docker start
```

Adicione o usuário atual ao grupo Docker:

```bash
sudo usermod -aG docker $USER
```

Depois desse comando, feche e abra novamente o terminal para que a
alteração seja aplicada.

Caso queira aplicar o novo grupo na sessão atual, execute:

```bash
newgrp docker
```

Caso o comando `newgrp` não esteja disponível:

```bash
sudo apt install util-linux-extra -y
```

Depois execute novamente:

```bash
newgrp docker
```

---

# 5. Testar o Docker

Execute:

```bash
docker run hello-world
```

Se aparecer:

```text
Hello from Docker!
```

o Docker está funcionando corretamente.

Neste momento, o computador possui tudo que é necessário para baixar
e executar o gerador de dados do projeto:

```text
Linux / Ubuntu
      |
      +---- Git
      |
      +---- Docker
```

---

# 6. Clonar o projeto

Execute:

```bash
git clone https://github.com/luisfeob34/pi-data-science-track-field.git
```

Entre na pasta:

```bash
cd pi-data-science-track-field
```

---

# 7. Construir a imagem Docker

Na raiz do projeto, execute:

```bash
docker build -t pi-track-field .
```

O Docker utilizará os arquivos do projeto para preparar automaticamente
o ambiente necessário.

O processo pode ser representado por:

```text
Dockerfile
     |
     v
Python
     |
     v
requirements.txt
     |
     v
Pandas + NumPy + Faker
     |
     v
Código do projeto
     |
     v
Imagem pi-track-field
```

---

# 8. Executar o projeto e gerar os dados

Execute:

```bash
docker run --rm \
  -v "$(pwd)/data/raw:/app/data/raw" \
  pi-track-field
```

O parâmetro:

```text
--rm
```

remove o container após a execução.

O volume:

```text
-v "$(pwd)/data/raw:/app/data/raw"
```

conecta a pasta do computador com a pasta utilizada pelo container:

```text
Computador                    Container

data/raw/       <-------->     /app/data/raw/
```

Isso permite que o CSV gerado permaneça salvo no computador mesmo após
o encerramento do container.

---

# 9. Resultado esperado

O terminal deverá apresentar:

```text
Dados gerados com sucesso!
Quantidade de vendas: 1000
Arquivo: data/raw/vendas_simuladas.csv
```

O arquivo estará disponível em:

```text
data/raw/vendas_simuladas.csv
```

Portanto, todo o processo em outro computador é:

```text
              NOVO COMPUTADOR
                     |
          +----------+----------+
          |                     |
       Windows                Linux
          |                     |
       WSL2                  direto
          |                     |
       Ubuntu                   |
          +----------+----------+
                     |
                     v
                    Git
                     |
                     v
                   Docker
                     |
                     v
                 git clone
                     |
                     v
                docker build
                     |
                     v
                 docker run
                     |
                     v
             gerar_dados.py
                     |
                     v
        vendas_simuladas.csv
```

---

# Execução local com Python

Também é possível executar o projeto diretamente com Python, sem utilizar
o Docker.

Nesse caso, Python e suas dependências precisam estar instalados no
computador.

## Criar o ambiente virtual

```bash
python3 -m venv .venv
```

## Ativar o ambiente

```bash
source .venv/bin/activate
```

## Instalar as dependências

```bash
python -m pip install -r requirements.txt
```

## Gerar os dados

```bash
python scripts/gerar_dados.py
```

Também é possível definir outra quantidade de registros:

```bash
python scripts/gerar_dados.py --quantidade 10000
```

---

# Dependências Python

As dependências utilizadas pelo projeto estão registradas no arquivo:

```text
requirements.txt
```

Atualmente:

```text
pandas==3.0.6
numpy==2.5.3
Faker==40.39.0
```

Ao executar através do Docker, essas dependências são instaladas
automaticamente durante a construção da imagem.

---

# Docker

O projeto possui um `Dockerfile` responsável por criar um ambiente
isolado contendo Python, dependências e o código necessário para
execução.

Construir a imagem:

```bash
docker build -t pi-track-field .
```

Executar:

```bash
docker run --rm \
  -v "$(pwd)/data/raw:/app/data/raw" \
  pi-track-field
```

---

# Ansible

Os arquivos de automação estão disponíveis em:

```text
infra/ansible/
```

Estrutura:

```text
infra/ansible/
├── inventory.ini
└── playbook.yml
```

O inventário utiliza a máquina Linux local:

```text
localhost
```

O Ansible é utilizado para automatizar tarefas de preparação do ambiente.

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

O Kubernetes é utilizado para orquestração dos containers e serviços
da infraestrutura.

No ambiente local, utilizamos Minikube com Docker como driver.

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

## Verificar o cluster

```bash
minikube status
```

## Aplicar os recursos do projeto

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

O Prometheus foi instalado utilizando Helm.

## Adicionar o repositório

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## Atualizar

```bash
helm repo update
```

## Instalar

Em um ambiente no qual o Prometheus ainda não esteja instalado:

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoramento
```

## Verificar

```bash
kubectl get pods -n monitoramento
```

Os componentes deverão apresentar o estado `Running` após a
inicialização.

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

Durante a configuração do ambiente foram realizados os seguintes testes:

- [x] Ambiente Linux Ubuntu através do WSL2
- [x] Git
- [x] GitHub
- [x] Python 3.14
- [x] Ambiente virtual Python
- [x] Instalação das dependências através do `requirements.txt`
- [x] Execução do gerador de dados
- [x] Geração do arquivo `vendas_simuladas.csv`
- [x] Comunicação do Ansible com o ambiente Linux
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

O objetivo da infraestrutura DevOps é permitir que o projeto possa ser
executado em diferentes computadores reduzindo diferenças entre os
ambientes.

Para executar apenas o gerador de dados em outro computador, são
necessários:

```text
Linux
  |
  +---- Git
  |
  +---- Docker
```

Caso o computador utilize Windows, o Linux pode ser disponibilizado
através do WSL2 com Ubuntu.

O Docker utiliza o `Dockerfile` e o `requirements.txt` para criar o
ambiente necessário automaticamente.

A infraestrutura completa do projeto utiliza:

```text
Git / GitHub
     |
     +---- Versionamento
     |
Ansible
     |
     +---- Automação
     |
Docker
     |
     +---- Ambiente reproduzível
     |
Kubernetes / Minikube
     |
     +---- Orquestração
     |
Helm
     |
     +---- Gerenciamento
     |
Prometheus
     |
     +---- Monitoramento
```

Dessa forma, o projeto possui código versionado, dependências
documentadas, ambiente reproduzível e infraestrutura organizada.

---

# Status atual

Atualmente estão configurados e testados:

- [x] Linux / Ubuntu / WSL2
- [x] Git e GitHub
- [x] Python
- [x] Ambiente virtual
- [x] Dependências Python
- [x] Gerador de dados
- [x] Ansible
- [x] Docker
- [x] Dockerfile
- [x] Kubernetes
- [x] Minikube
- [x] kubectl
- [x] Helm
- [x] Prometheus
- [x] Monitoramento
- [x] Documentação
- [x] Procedimento para execução em outro computador

A infraestrutura poderá ser expandida conforme novos componentes forem
adicionados ao pipeline durante o desenvolvimento do projeto.