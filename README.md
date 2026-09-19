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

## Estrutura do projeto

```text
PI-Data-Science-Track-Field/
├── data/
│   ├── raw/
│   └── processed/
├── docs/
├── infra/
│   ├── ansible/
│   │   ├── inventory.ini
│   │   └── playbook.yml
│   ├── kubernetes/
│   │   └── namespace.yml
│   └── monitoring/
│       └── README.md
├── notebooks/
├── results/
├── scripts/
│   └── gerar_dados.py
├── src/
├── .dockerignore
├── .gitignore
├── Dockerfile
├── README.md
└── requirements.txt
```

### Diretórios

- `data/raw/` - Dados brutos gerados ou recebidos pelo pipeline.
- `data/processed/` - Dados após limpeza e transformação.
- `docs/` - Documentação complementar do projeto.
- `infra/` - Arquivos relacionados à infraestrutura e DevOps.
- `infra/ansible/` - Automação da configuração do ambiente Linux.
- `infra/kubernetes/` - Manifestos do Kubernetes.
- `infra/monitoring/` - Documentação e configuração de monitoramento.
- `notebooks/` - Notebooks utilizados nas análises.
- `results/` - Resultados, relatórios e visualizações.
- `scripts/` - Scripts de geração e automação.
- `src/` - Código-fonte relacionado ao processamento dos dados.

## Tecnologias

### Desenvolvimento e dados

- Python 3.14
- Pandas 3.0.6
- NumPy 2.5.3
- Faker 40.39.0

### Versionamento

- Git
- GitHub

### Ambiente

- Linux
- Ubuntu via WSL2
- Python Virtual Environment (`venv`)

### DevOps e infraestrutura

- Ansible
- Docker
- Kubernetes
- Minikube
- kubectl
- Helm

### Monitoramento

- Prometheus

## Arquitetura de infraestrutura

A infraestrutura de desenvolvimento utiliza Linux através do Ubuntu
executado no WSL2.

O Git é utilizado para controle de versão e o GitHub para armazenamento
e compartilhamento do repositório.

O Ansible é utilizado para automatizar a preparação do ambiente Linux.

O Docker é utilizado para criar um ambiente padronizado e reproduzível
para execução da aplicação.

O Kubernetes é utilizado para a orquestração dos containers. Para o
ambiente local de desenvolvimento, o cluster Kubernetes é executado
através do Minikube utilizando o Docker como driver.

O Helm é utilizado para instalação e gerenciamento de aplicações no
Kubernetes.

O Prometheus é utilizado para monitoramento da infraestrutura e coleta
de métricas dos serviços executados no cluster.

Fluxo simplificado da infraestrutura:

```text
GitHub
   |
   v
Linux / Ubuntu / WSL2
   |
   +---- Ansible
   |
   v
Docker
   |
   v
Kubernetes / Minikube
   |
   +---- Pipeline de dados
   |
   +---- Prometheus
            |
            v
       Monitoramento
```

## Dependências Python

As dependências Python do projeto estão registradas no arquivo
`requirements.txt`.

Atualmente são utilizadas:

```text
pandas==3.0.6
numpy==2.5.3
Faker==40.39.0
```

## Preparação do ambiente Python

Criar um ambiente virtual:

```bash
python3 -m venv .venv
```

Ativar o ambiente:

```bash
source .venv/bin/activate
```

Instalar as dependências:

```bash
python -m pip install -r requirements.txt
```

## Execução do gerador de dados

O projeto possui um simulador de vendas desenvolvido em Python.

Para gerar 1.000 registros:

```bash
python scripts/gerar_dados.py
```

O arquivo será criado em:

```text
data/raw/vendas_simuladas.csv
```

Também é possível definir a quantidade de registros:

```bash
python scripts/gerar_dados.py --quantidade 10000
```

## Docker

O projeto possui um `Dockerfile` responsável por criar um ambiente
isolado contendo Python, dependências e o código da aplicação.

### Construir a imagem

```bash
docker build -t pi-track-field .
```

### Executar o container

```bash
docker run --rm pi-track-field
```

Ao executar o container, o gerador de dados Python é iniciado
automaticamente.

## Ansible

Os arquivos de automação estão disponíveis em:

```text
infra/ansible/
```

O inventário utiliza a máquina Linux local:

```text
localhost
```

### Testar comunicação

```bash
ansible all -i infra/ansible/inventory.ini -m ping
```

O resultado esperado contém:

```text
"ping": "pong"
```

### Validar o playbook

```bash
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml --syntax-check
```

### Executar o playbook

```bash
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml --ask-become-pass
```

O playbook prepara componentes básicos do ambiente, incluindo Git,
Python, pip, suporte a ambientes virtuais e Docker.

## Kubernetes

O ambiente Kubernetes local utiliza Minikube com o Docker como driver.

### Iniciar o cluster

```bash
minikube start --driver=docker
```

### Verificar o cluster

```bash
minikube status
```

### Criar recursos do projeto

```bash
kubectl apply -f infra/kubernetes/namespace.yml
```

### Verificar namespaces

```bash
kubectl get namespaces
```

O projeto utiliza o namespace:

```text
monitoramento
```

## Monitoramento com Prometheus

O Prometheus é executado dentro do Kubernetes.

Adicionar o repositório Helm:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Atualizar os repositórios:

```bash
helm repo update
```

Instalar o Prometheus em um ambiente novo:

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoramento
```

Verificar os componentes:

```bash
kubectl get pods -n monitoramento
```

Os pods devem apresentar o estado `Running`.

### Acessar o Prometheus

```bash
kubectl port-forward -n monitoramento svc/prometheus-server 9090:80
```

Com o redirecionamento ativo, a interface do Prometheus pode ser
acessada localmente pela porta `9090`.

Mais informações sobre o monitoramento estão disponíveis em:

```text
infra/monitoring/README.md
```

## Procedimento para reprodução do ambiente

Para reproduzir o projeto em outra máquina, o fluxo geral é:

1. Disponibilizar um ambiente Linux.
2. Instalar Git.
3. Clonar o repositório.
4. Entrar no diretório do projeto.
5. Criar e ativar o ambiente virtual Python.
6. Instalar as dependências através do `requirements.txt`.
7. Instalar e configurar Docker.
8. Instalar Ansible.
9. Instalar Minikube e kubectl.
10. Iniciar o cluster Kubernetes.
11. Instalar Helm.
12. Aplicar os manifestos Kubernetes presentes em `infra/kubernetes/`.
13. Instalar o Prometheus utilizando Helm.
14. Construir a imagem Docker do projeto.
15. Executar o pipeline.

Exemplo para obter o projeto:

```bash
git clone <https://github.com/luisfeob34/pi-data-science-track-field.git>
cd pi-data-science-track-field
```

Após a preparação das ferramentas:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Validar o Ansible:

```bash
ansible all -i infra/ansible/inventory.ini -m ping
```

Construir a imagem:

```bash
docker build -t pi-track-field .
```

Executar:

```bash
docker run --rm pi-track-field
```

## Validações realizadas

Durante a configuração do ambiente foram realizados os seguintes testes:

- Execução do Python dentro do ambiente virtual.
- Instalação das dependências pelo `requirements.txt`.
- Comunicação do Ansible com o ambiente Linux (`ping: pong`).
- Validação de sintaxe do playbook Ansible.
- Execução de containers Docker.
- Construção da imagem `pi-track-field`.
- Execução do gerador de dados dentro do container.
- Inicialização do Kubernetes através do Minikube.
- Comunicação com o cluster através do kubectl.
- Validação do manifesto Kubernetes.
- Instalação do Prometheus através do Helm.
- Verificação dos pods do Prometheus em estado `Running`.
- Acesso à interface do Prometheus.

## Objetivo de reprodutibilidade

A combinação de Git, `requirements.txt`, Ansible, Docker, Kubernetes e
documentação permite que o ambiente utilizado no desenvolvimento possa
ser reconstruído em outra máquina com as ferramentas necessárias,
reduzindo diferenças de configuração entre ambientes.