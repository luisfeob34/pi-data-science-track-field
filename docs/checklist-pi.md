# Checklist da entrega final do PI

Base: **Orientação PI 2026-2 – DATA SCIENCE.pdf**, recebido em 28/09/2026.
As páginas abaixo são as páginas do PDF, contando a capa. Este checklist não
substitui a validação dos professores nem os prazos divulgados no Classroom.

| Requisito | Situação no projeto | Evidência ou próximo passo |
|---|---|---|
| Problema organizacional e justificativa Big Data (7–9) | proposta documentada | validar com o beneficiário, docs/arquitetura-pi.md |
| Coleta ou geração (8) | implementado | simulador/gerar_dados.R e VM da P1 |
| Qualidade e tratamento (8) | implementado | R/dados.R, spark/processar.R, quarentena e testes |
| Visualizações e interpretações (8–10) | implementado com dados sintéticos | Shiny e relatório R; confirmar utilidade no problema real |
| Data Lake/Warehouse e ETL (9) | implementado e validado | docs/arquitetura-pi.md e docs/validacao-bigdata.md |
| Modelo dimensional quando aplicável (9) | validado por leitura e junção | fato e quatro dimensões Parquet na gold |
| Conceitos Hadoop (9) | HDFS executado e validado | NameNode/DataNode locais, sem promessa de redundância |
| DataFrames e Spark SQL (9–10) | execução real validada | spark/processar.R e docs/validacao-bigdata.md |
| Estatística descritiva e probabilidade (10) | ampliado | moda, variância, frequências, probabilidades e testes em R |
| Automação e identificação de falhas (10–11) | ampliado | pipeline com logs e status no painel |
| Dependências e instruções (6,10–11) | documentado | README e infraestrutura/bigdata/README.md |
| GitHub e histórico colaborativo (5–6) | confirmar com o grupo | publicar alterações e contribuições reais, sem fabricar histórico |
| Líder, papéis e cronograma (5) | pendente de informações do grupo | docs/gestao-pi.md |
| Sprint reports e reuniões (6) | pendente de registros reais | preencher modelos de docs/gestao-pi.md |
| Beneficiário e consentimento escrito (4–5) | não comprovado no repositório | obter identificação e anuência, guardar em local apropriado |
| ODS 8 (13) | relação proposta | validar benefício para trabalho e crescimento econômico |
| Vídeo de carreiras (7,11) | depende dos integrantes | 3–5 minutos, baseado em Gerenciando sua Carreira, todos aparecem |
| Relatório individual de extensão (11–12) | depende de cada estudante | preencher e acompanhar aprovação na Intranet |
| Entrega e apresentação final (5–6) | pendente | demonstração completa, decisões, resultados e impacto no Classroom |

Não confundir previsões com requisito obrigatório: são um recurso adicional.
O documento não exige usar Docker, Kubernetes, Prometheus, Hive e YARN todos
juntos. Monitoramento e reprodutibilidade precisam de evidências funcionais.
A orientação proíbe vídeo de carreiras feito por IA ou somente com voz.

## Ordem de trabalho

1. Confirmar problema e beneficiário, com anuência e vínculo ao ODS 8.
2. Validar a ingestão de múltiplos lotes, Spark e armazenamento.
3. Conferir indicadores no painel e documentar interpretações.
4. Registrar testes, falhas tratadas e limitações de escala.
5. Completar documentos do grupo, vídeo e relatórios individuais.
6. Publicar o código e preparar a demonstração final conforme o calendário.
