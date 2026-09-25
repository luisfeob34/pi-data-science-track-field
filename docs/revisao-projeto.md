# Revisão do projeto

> Registro histórico da revisão anterior à migração. O fluxo descrito abaixo foi
> substituído por R e Shiny. Consulte o README e `metodologia-r.md` para a implementação atual.
> A migração unificou o tratamento, separou as saídas em `results/r/`, isolou uploads
> por sessão e eliminou o observador Python e os endpoints PHP. As execuções exportadas
> são publicadas em pastas independentes. Os resultados antigos foram preservados.

## Fluxos mantidos

- Painel: PHP → CSVs de `results/spark/` e `data/processed/` → gráficos SVG no navegador.
- Geração pelo painel: `observar_geracao.py` → `gerar_dados.py` → `atualizar_resultados.py`.
- Análise pelo terminal: tratamento com Pandas, análise exploratória, PNGs com Matplotlib e agregação com Spark.
- Infraestrutura opcional: Docker, Ansible, Kubernetes e monitoramento. São ferramentas documentadas, não código morto por não serem chamadas pelo painel.

## Limpeza realizada

- Removidos Faker, sem importação nos scripts, e os marcadores de diretórios vazios.
- Removidos os estados JavaScript `slide`, `atividades` e `notasTimer`, sem consumidores.
- Removidos os textos de apresentação e perguntas calculados na API, mas não utilizados na interface, incluindo suas funções auxiliares exclusivas. Os KPIs foram preservados.
- Removido `api/tabela.php`, sem chamadas ou links no projeto. Consumidores externos que chamassem essa URL diretamente precisarão de adaptação.
- Corrigidos caminho do observador, finais de linha do Bash e encerramento dos processos iniciados pelo script. Adicionada trava para impedir duas instâncias iniciadas pelo novo script.
- Documentados os requisitos específicos do painel e a diferença entre sua atualização e a execução do Spark.

## Melhorias identificadas para a próxima etapa

1. Separar os agregados produzidos pelo painel dos resultados reais do Spark. Hoje ambos escrevem em `results/spark/`, o que dificulta identificar a origem dos resultados.
2. Unificar regras de tratamento: `atualizar_resultados.py` e `scripts/tratar_dados.py` implementam caminhos diferentes para produzir o CSV processado. A geração do painel não passa pela validação completa do script Pandas.
3. Publicar os CSVs de uma geração de forma consistente. Hoje os arquivos são substituídos sequencialmente enquanto a API pode lê-los; `gravar()` também apaga todos os arquivos da pasta de destino.
4. Validar uploads antes de substituir um resultado manual existente. Atualmente um upload inválido com o mesmo nome pode apagar o resultado anterior.
5. Tratar falhas de rede no botão de geração e na consulta de status: uma rejeição de `fetch()` pode deixar o botão desabilitado.
6. Recuperar status de geração interrompida e coordenar o encerramento com subprocessos que já estejam gerando dados. A trava do script não cobre observadores iniciados manualmente.
7. Ajustar a imagem Docker ao fluxo desejado. Atualmente instala dependências de análise e Spark, mas inicia apenas o gerador padrão e não inclui Java nem PHP.

Os dados, gráficos gerados e instaladores locais não foram removidos como parte da limpeza de código.
