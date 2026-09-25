# Metodologia estatística e migração para R

## Unidade de análise e tratamento

Cada linha é um pedido; a base simulada contém um cliente diferente por pedido.
Dados reais com clientes repetidos ou dependência temporal exigem avaliação de agrupamento
antes de interpretar os p-valores como evidência confirmatória.

Duplicados exatos são removidos após aparar espaços. Ausentes, datas inválidas,
números não finitos, quantidades fracionárias e valores fora do domínio são auditados.
IDs com conteúdos conflitantes são descartados integralmente. O total válido é recalculado
como preço × quantidade menos desconto, arredondando os componentes a duas casas.
R usa arredondamento para o par em empates; diferenças de centavos em relação ao gerador
anterior são possíveis. Outliers não são automaticamente excluídos.

## Testes exploratórios

| Questão | Método | Efeito | Condições verificadas |
| --- | --- | --- | --- |
| O valor do pedido difere entre categorias, canais ou regiões? | Kruskal-Wallis, um teste por dimensão | Epsilon² aproximado, limitado inferiormente a zero | ≥2 grupos, ≥5 pedidos por grupo e variação no valor |
| Desconto e valor têm associação monotônica? | Spearman, aproximação assintótica com empates | Rho | ≥10 pedidos e variação nas duas variáveis |
| Categoria e canal são independentes? | Qui-quadrado com Monte Carlo, 4.999 simulações e semente 42 | V de Cramér | ≥2 linhas e colunas, ≥10 pedidos |

Kruskal-Wallis compara distribuições; a interpretação como comparação de medianas requer
formas comparáveis. Um resultado significativo não identifica quais pares diferem.
O desconto faz parte da fórmula do valor, portanto sua correlação não demonstra efeito
causal sobre demanda. O p-valor Monte Carlo tem resolução finita de aproximadamente 1/5.000.

Os valores-p recebem ajuste de Holm, com alfa de 5%, para a família de testes da execução.
A decisão é baseada no p-valor ajustado. A correção não abrange sucessivas tentativas de filtros.
Sem evidência contra H0 não significa comprovar H0. Amostras insuficientes produzem
status explícito, nunca p-valores artificiais.

## Série temporal e previsões

Faturamento é agregado por **ano e mês**, sem juntar janeiros de anos diferentes.
A cobertura disponível é estimada conservadoramente da primeira à última data da base.
No painel, ela também é limitada pelo filtro de período e é mantida ao filtrar categorias/canais.
Isso não certifica que os dados de origem estejam completos; o usuário deve verificar sua cobertura.

Meses das extremidades sem cobertura integral são exibidos, mas excluídos do ajuste.
Meses internos sem registros ficam ausentes e bloqueiam a previsão, a menos que o usuário
confirme explicitamente que representam zero vendas. São necessários oito meses completos.

São comparados três modelos: média histórica, último mês (passeio aleatório) e tendência linear.
A validação usa de três a cinco origens móveis no final da série, com no mínimo cinco meses
de treino e previsão de um passo em cada origem. Cada previsão vê somente o passado.
Escolhe-se o menor MAE; RMSE e os erros individuais são exportados. Empates favorecem
a ordem média histórica, último mês e tendência. Essa amostra pequena deixa a seleção incerta.
Não há uma segunda amostra independente para estimar o erro após selecionar o modelo.

Depois da seleção, o modelo é reajustado com todos os meses completos. O horizonte é de um
a seis meses. As métricas de um passo não validam diretamente horizontes de vários meses.
Não se ajusta sazonalidade anual com aproximadamente um ciclo de dados.

Os intervalos de previsão são nominais de 95%:

- Média: distribuição t, com erro de uma nova observação e incerteza da média; pressupõe observações aproximadamente independentes e variância estável.
- Último mês: aproximação normal do passeio aleatório; variância estimada pela média dos incrementos ao quadrado e ampliada com o horizonte.
- Tendência: intervalo de previsão da regressão linear; pressupõe tendência linear e resíduos aproximadamente independentes, normais e homocedásticos.

Previsões e limites negativos são truncados em zero. Essa restrição e a seleção do modelo
alteram a cobertura efetiva; a faixa não é uma garantia nem inclui toda a incerteza do processo.
Na simulação, relações e previsibilidade podem ser fracas por construção.

## Referências oficiais

- [R: Kruskal-Wallis](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/kruskal.test.html)
- [R: testes de correlação](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/cor.test.html)
- [R: qui-quadrado](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/chisq.test.html)
- [R: correção de múltiplas comparações](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/p.adjust.html)
- [R: previsão de regressão linear](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/predict.lm.html)
- [Shiny: execução de aplicativos](https://shiny.posit.co/r/reference/shiny/latest/runapp.html)
- [Plotly: gráficos interativos em R](https://plotly.com/r/)
