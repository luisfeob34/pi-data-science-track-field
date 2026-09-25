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
```

Este diretório documenta a infraestrutura opcional do projeto anterior.
O painel R/Shiny não exige Kubernetes ou Prometheus para execução local.
O manifesto cria apenas o namespace; não instala nem monitora o aplicativo R.
