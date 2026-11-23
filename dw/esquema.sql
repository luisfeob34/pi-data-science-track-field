-- Data Warehouse de vendas: modelo estrela no PostgreSQL da VM de exibição.
-- Idempotente: pode ser reaplicado pelo Ansible sem perder dados.
-- Grão da fato: um pedido simulado por execução (chave execucao + pedido).

CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.dim_produto (
  id_produto  text PRIMARY KEY,           -- SHA-256 de produto + categoria, gerado no Spark
  produto     text NOT NULL,
  categoria   text NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_canal (
  id_canal    text PRIMARY KEY,
  canal       text NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_regiao (
  id_regiao   text PRIMARY KEY,
  regiao      text NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_data (
  id_data     integer PRIMARY KEY,         -- AAAAMMDD
  data_venda  date NOT NULL UNIQUE,
  ano         smallint NOT NULL,
  mes         smallint NOT NULL CHECK (mes BETWEEN 1 AND 12),
  trimestre   smallint NOT NULL CHECK (trimestre BETWEEN 1 AND 4)
);

CREATE TABLE IF NOT EXISTS dw.fato_vendas (
  execucao        text NOT NULL,           -- lote de origem
  pedido          text NOT NULL,           -- número do pedido no lote
  id_data         integer NOT NULL REFERENCES dw.dim_data (id_data),
  id_produto      text NOT NULL REFERENCES dw.dim_produto (id_produto),
  id_canal        text NOT NULL REFERENCES dw.dim_canal (id_canal),
  id_regiao       text NOT NULL REFERENCES dw.dim_regiao (id_regiao),
  cliente         text NOT NULL,           -- código sintético (dimensão degenerada)
  quantidade      integer NOT NULL CHECK (quantidade > 0),
  preco           numeric(12, 2) NOT NULL CHECK (preco > 0),
  desconto        numeric(6, 4) NOT NULL CHECK (desconto BETWEEN 0 AND 1),
  valor_bruto     numeric(14, 2) NOT NULL,
  valor_desconto  numeric(14, 2) NOT NULL,
  valor_total     numeric(14, 2) NOT NULL CHECK (valor_total >= 0),
  PRIMARY KEY (execucao, pedido)
);

CREATE INDEX IF NOT EXISTS fato_vendas_data_idx    ON dw.fato_vendas (id_data);
CREATE INDEX IF NOT EXISTS fato_vendas_produto_idx ON dw.fato_vendas (id_produto);
CREATE INDEX IF NOT EXISTS fato_vendas_canal_idx   ON dw.fato_vendas (id_canal);
CREATE INDEX IF NOT EXISTS fato_vendas_regiao_idx  ON dw.fato_vendas (id_regiao);

-- Histórico das cargas: qual execução Spark alimentou o DW e quando.
CREATE TABLE IF NOT EXISTS dw.cargas (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  execucao_spark  text NOT NULL,
  carregado_em    timestamptz NOT NULL DEFAULT now(),
  vendas          integer NOT NULL,
  faturamento     numeric(16, 2) NOT NULL
);

-- Visão analítica usada pelo painel: a fato com os atributos das dimensões.
CREATE OR REPLACE VIEW dw.vw_vendas AS
SELECT f.pedido, d.data_venda, f.cliente, p.produto, p.categoria, c.canal, r.regiao,
       f.preco, f.quantidade, f.desconto, f.valor_total, f.execucao
FROM dw.fato_vendas f
JOIN dw.dim_data d    ON d.id_data = f.id_data
JOIN dw.dim_produto p ON p.id_produto = f.id_produto
JOIN dw.dim_canal c   ON c.id_canal = f.id_canal
JOIN dw.dim_regiao r  ON r.id_regiao = f.id_regiao;
