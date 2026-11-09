# Dicionário de dados

Base: vendas simuladas de artigos esportivos (`R/dados.R::gerar_vendas`).
Grão: **1 linha = 1 pedido de 1 produto** em um lote (`ID Execucao`).
Formato do CSV: UTF-8, vírgula como separador, ponto decimal, datas `AAAA-MM-DD`.
Dados sintéticos: `Cliente` é um código fictício, sem dado pessoal.

## Campos de origem

| Campo | Tipo | Descrição | Domínio / regra de validação |
|---|---|---|---|
| ID Pedido | inteiro | Número do pedido no lote | ≥ 1; único por `ID Execucao + ID Pedido` |
| Data da Venda | data | Data do pedido | data de calendário válida |
| Cliente | texto | Código sintético do cliente | `Cliente_00001`…; repete entre lotes; não sustenta análise de recompra |
| Produto | categórico | Produto vendido | 10 produtos (tabela abaixo) |
| Categoria | categórico | Grupo do produto | Vestuário, Calçados, Acessórios |
| Canal de Venda | categórico | Canal do pedido | Loja Física, E-commerce, Marketplace |
| Região | categórico | Região do Brasil | Norte, Nordeste, Centro-Oeste, Sudeste, Sul |
| Preço Unitário | decimal (R$) | Preço de tabela | > 0 |
| Quantidade | inteiro | Itens do pedido | inteiro > 0 (simulador: 1 a 5) |
| Desconto | decimal (fração) | Desconto sobre o valor bruto | 0 a 1 (simulador: 0; 0,05; 0,10; 0,15) |
| Valor Total | decimal (R$) | Valor líquido do pedido | ≥ 0; recalculado no tratamento |
| ID Execucao | texto | Lote que gerou o registro | `exec-…`; `avulso` quando ausente |
| Gerado em UTC | data-hora | Momento da geração do lote | só lotes da VM; não segue para a análise |

## Campos derivados no tratamento

Calculados por `tratar_vendas` (R) e pelas mesmas regras em `spark/processar.R`.

| Campo | Regra |
|---|---|
| Valor Bruto | Preço Unitário × Quantidade, em centavos (empate para o par) |
| Valor Desconto | Valor Bruto × Desconto, em centavos |
| Valor Total | Valor Bruto − Valor Desconto (substitui o valor recebido) |
| Possui Desconto | Sim / Não |
| Desconto Percentual | 100 × Desconto |
| Faixa de Desconto | Sem desconto; Até 5%; De 6% a 10%; Acima de 10% |
| Valor por Item | Valor Total ÷ Quantidade |
| Porte do Pedido | Unitário (1 item); Pequeno (2–3); Grande (4 ou mais) |
| Faixa de Valor | Até R$ 249,99; R$ 250 a R$ 499,99; R$ 500 a R$ 999,99; R$ 1.000 ou mais |
| Ano, Número do Mês, Mês, Periodo, Trimestre, Dia da Semana | Atributos de calendário da Data da Venda |

## Regras de rejeição

Duplicatas exatas, campos ausentes, datas inválidas, números não finitos, valores fora do domínio e
IDs conflitantes (mesmo lote e pedido com conteúdos diferentes). No Spark, os rejeitados vão para a
quarentena com o motivo. Valores atípicos válidos não são removidos.

## Produtos

| Produto | Categoria | Preço (R$) |
|---|---|---|
| Camiseta Performance | Vestuário | 149,90 |
| Shorts Running | Vestuário | 129,90 |
| Legging Compressão | Vestuário | 199,90 |
| Top Esportivo | Vestuário | 119,90 |
| Jaqueta Corta-Vento | Vestuário | 299,90 |
| Tênis Running | Calçados | 499,90 |
| Tênis Training | Calçados | 449,90 |
| Meia Esportiva | Acessórios | 49,90 |
| Mochila Esportiva | Acessórios | 249,90 |
| Garrafa Térmica | Acessórios | 99,90 |

## Hipóteses do simulador

Padrões plantados para que EDA, OLAP e ML tenham sinal a encontrar. São plausíveis para varejo
esportivo, mas **não são medições da Track & Field**. Parâmetros exatos em `perfil_simulador` (`R/dados.R`).

| Padrão | Regra |
|---|---|
| Sazonalidade | volume maior em maio (Dia das Mães), novembro (Black Friday) e dezembro (Natal); menor em fevereiro |
| Crescimento | +15% de volume do início ao fim do ano |
| Produtos sazonais | jaqueta no inverno (jun–ago); garrafa e shorts no verão; tênis de corrida na Black Friday |
| Canal × categoria | Vestuário mais na loja física; Calçados no e-commerce; Acessórios no marketplace |
| Região | Sudeste 44%, Nordeste 20%, Sul 19%, Centro-Oeste 10%, Norte 7%; não altera o tipo de pedido |
| Desconto | mais frequente no marketplace e no e-commerce; mais alto em novembro |
| Itens por pedido | 1 + Poisson(base da categoria × e^(5 × desconto)), limitado a 5; Acessórios > Vestuário > Calçados |

Modelos dimensionais, camadas e fluxo ETL: `docs/arquitetura-pi.md`.
