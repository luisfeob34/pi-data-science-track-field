import csv
import random
import argparse
from datetime import date, timedelta
from pathlib import Path


produtos = {
    "Camiseta Performance": "Vestuário",
    "Shorts Running": "Vestuário",
    "Legging Compressão": "Vestuário",
    "Tênis Running": "Calçados",
    "Tênis Training": "Calçados",
    "Top Esportivo": "Vestuário",
    "Jaqueta Corta-Vento": "Vestuário",
    "Meia Esportiva": "Acessórios",
    "Mochila Esportiva": "Acessórios",
    "Garrafa Térmica": "Acessórios",
}

precos = {
    "Camiseta Performance": 149.90,
    "Shorts Running": 129.90,
    "Legging Compressão": 199.90,
    "Tênis Running": 499.90,
    "Tênis Training": 449.90,
    "Top Esportivo": 119.90,
    "Jaqueta Corta-Vento": 299.90,
    "Meia Esportiva": 49.90,
    "Mochila Esportiva": 249.90,
    "Garrafa Térmica": 89.90,
}

canais = [
    "Loja Física",
    "E-commerce",
    "Aplicativo",
]

regioes = [
    "Sudeste",
    "Sul",
    "Centro-Oeste",
    "Nordeste",
    "Norte",
]

descontos = [
    0.00,
    0.00,
    0.00,
    0.05,
    0.10,
    0.15,
]


def gerar_data_aleatoria(data_inicial, data_final):
    """
    Gera uma data aleatória dentro do intervalo informado.
    """
    intervalo_dias = (data_final - data_inicial).days

    dias_aleatorios = random.randint(
        0,
        intervalo_dias,
    )

    return data_inicial + timedelta(days=dias_aleatorios)


def gerar_vendas(quantidade):
    vendas = []

    # Período utilizado para simular as vendas
    data_inicial = date(2026, 1, 1)
    data_final = date(2026, 12, 31)

    for numero in range(1, quantidade + 1):
        produto = random.choice(
            list(produtos.keys())
        )

        categoria = produtos[produto]

        preco_unitario = precos[produto]

        quantidade_produto = random.randint(
            1,
            5,
        )

        desconto = random.choice(
            descontos
        )

        data_venda = gerar_data_aleatoria(
            data_inicial,
            data_final,
        )

        valor_sem_desconto = (
            preco_unitario
            * quantidade_produto
        )

        valor_total = (
            valor_sem_desconto
            * (1 - desconto)
        )

        venda = {
            "ID Pedido": numero,
            "Data da Venda": data_venda.isoformat(),
            "Cliente": f"Cliente_{numero:05d}",
            "Produto": produto,
            "Categoria": categoria,
            "Canal de Venda": random.choice(canais),
            "Região": random.choice(regioes),
            "Preço Unitário": round(
                preco_unitario,
                2,
            ),
            "Quantidade": quantidade_produto,
            "Desconto": desconto,
            "Valor Total": round(
                valor_total,
                2,
            ),
        }

        vendas.append(venda)

    return vendas


def salvar_csv(vendas, caminho):
    caminho = Path(caminho)

    caminho.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    colunas = [
        "ID Pedido",
        "Data da Venda",
        "Cliente",
        "Produto",
        "Categoria",
        "Canal de Venda",
        "Região",
        "Preço Unitário",
        "Quantidade",
        "Desconto",
        "Valor Total",
    ]

    with open(
        caminho,
        "w",
        newline="",
        encoding="utf-8-sig",
    ) as arquivo:

        escritor = csv.DictWriter(
            arquivo,
            fieldnames=colunas,
        )

        escritor.writeheader()
        escritor.writerows(vendas)


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Gerador de dados fictícios de vendas "
            "da Track & Field"
        )
    )

    parser.add_argument(
        "-n",
        "--quantidade",
        type=int,
        default=1000,
        help="Quantidade de vendas a serem geradas",
    )

    parser.add_argument(
        "-o",
        "--saida",
        default="data/raw/vendas_simuladas.csv",
        help="Caminho do arquivo CSV de saída",
    )

    args = parser.parse_args()

    if args.quantidade <= 0:
        print(
            "A quantidade deve ser maior que zero."
        )
        return

    vendas = gerar_vendas(
        args.quantidade
    )

    salvar_csv(
        vendas,
        args.saida,
    )

    print("Dados gerados com sucesso!")
    print(
        f"Quantidade de vendas: "
        f"{args.quantidade}"
    )
    print(
        "Período das vendas: "
        "01/01/2026 a 31/12/2026"
    )
    print(
        f"Arquivo: {args.saida}"
    )


if __name__ == "__main__":
    main()