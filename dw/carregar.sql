-- Carga do Data Warehouse a partir dos CSVs do modelo estrela exportados pelo Spark.
-- Uso, na pasta da carga: psql -X -v ON_ERROR_STOP=1 -v execucao=exec-... -d dw_vendas -f carregar.sql
-- Cada execução Spark é um retrato completo dos lotes conhecidos: a carga substitui o conteúdo.
-- Tudo roda em uma transação; em caso de erro, o DW mantém a carga anterior.
\set ON_ERROR_STOP on
BEGIN;

-- Área de staging: tudo como texto, exatamente como veio do Spark.
CREATE TEMP TABLE stg_dim_produto (id_produto text, produto text, categoria text) ON COMMIT DROP;
CREATE TEMP TABLE stg_dim_canal (id_canal text, canal text) ON COMMIT DROP;
CREATE TEMP TABLE stg_dim_regiao (id_regiao text, regiao text) ON COMMIT DROP;
CREATE TEMP TABLE stg_dim_data (id_data text, data_venda text, ano text, mes text, trimestre text) ON COMMIT DROP;
CREATE TEMP TABLE stg_fato_vendas (execucao text, pedido text, id_data text, id_produto text, id_canal text,
  id_regiao text, cliente text, quantidade text, preco text, desconto text, valor_bruto text,
  valor_desconto text, valor_total text) ON COMMIT DROP;

-- \copy lê os arquivos da pasta atual (o p1.sh entra na pasta da carga antes de chamar o psql).
\copy stg_dim_produto FROM 'dim_produto.csv' WITH (FORMAT csv, HEADER true)
\copy stg_dim_canal FROM 'dim_canal.csv' WITH (FORMAT csv, HEADER true)
\copy stg_dim_regiao FROM 'dim_regiao.csv' WITH (FORMAT csv, HEADER true)
\copy stg_dim_data FROM 'dim_data.csv' WITH (FORMAT csv, HEADER true)
\copy stg_fato_vendas FROM 'fato_vendas.csv' WITH (FORMAT csv, HEADER true)

-- Substitui o retrato anterior. As restrições de tipo, chave e domínio validam a carga.
TRUNCATE dw.fato_vendas, dw.dim_produto, dw.dim_canal, dw.dim_regiao, dw.dim_data;

INSERT INTO dw.dim_produto (id_produto, produto, categoria)
SELECT id_produto, produto, categoria FROM stg_dim_produto;

INSERT INTO dw.dim_canal (id_canal, canal)
SELECT id_canal, canal FROM stg_dim_canal;

INSERT INTO dw.dim_regiao (id_regiao, regiao)
SELECT id_regiao, regiao FROM stg_dim_regiao;

INSERT INTO dw.dim_data (id_data, data_venda, ano, mes, trimestre)
SELECT id_data::integer, data_venda::date, ano::smallint, mes::smallint, trimestre::smallint FROM stg_dim_data;

INSERT INTO dw.fato_vendas (execucao, pedido, id_data, id_produto, id_canal, id_regiao, cliente,
  quantidade, preco, desconto, valor_bruto, valor_desconto, valor_total)
SELECT execucao, pedido, id_data::integer, id_produto, id_canal, id_regiao, cliente,
  quantidade::integer, preco::numeric, desconto::numeric, valor_bruto::numeric,
  valor_desconto::numeric, valor_total::numeric
FROM stg_fato_vendas;

-- Confere que nenhuma venda se perdeu nas junções com as dimensões.
DO $$
BEGIN
  IF (SELECT count(*) FROM dw.vw_vendas) <> (SELECT count(*) FROM dw.fato_vendas) THEN
    RAISE EXCEPTION 'Integridade do modelo estrela violada: a visao perdeu vendas.';
  END IF;
END $$;

INSERT INTO dw.cargas (execucao_spark, vendas, faturamento)
SELECT :'execucao', count(*), coalesce(sum(valor_total), 0) FROM dw.fato_vendas;

COMMIT;

SELECT 'Carga concluida: ' || vendas || ' vendas, R$ ' || faturamento || ' (' || execucao_spark || ')'
FROM dw.cargas ORDER BY id DESC LIMIT 1;
