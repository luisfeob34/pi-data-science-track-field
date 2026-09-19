# Monitoramento

O monitoramento da infraestrutura do projeto é realizado com Prometheus,
executado dentro do cluster Kubernetes local criado com Minikube.

## Ferramentas utilizadas

- Kubernetes
- Minikube
- Helm
- Prometheus

## Criar o namespace

```bash
kubectl apply -f infra/kubernetes/namespace.yml