<?php

declare(strict_types=1);

function raiz_projeto(): string
{
    return dirname(__DIR__, 2);
}

function caminho_spark(): string
{
    return raiz_projeto() . '/results/spark';
}

function caminho_processado(): string
{
    return raiz_projeto() . '/data/processed/vendas_processadas.csv';
}

function titulos_graficos(): array
{
    return [
        'faturamento_produto' => 'Por produto',
        'faturamento_categoria' => 'Por categoria',
        'faturamento_canal' => 'Por canal de venda',
        'faturamento_regiao' => 'Por região',
        'faturamento_mensal' => 'Ao longo do ano',
        'spark_sql_categoria' => 'Ticket por categoria',
    ];
}

function ordem_pastas(): array
{
    return [
        'faturamento_produto',
        'faturamento_categoria',
        'spark_sql_categoria',
        'faturamento_canal',
        'faturamento_regiao',
        'faturamento_mensal',
    ];
}

function colunas_correlacao(): array
{
    return [
        'Preço Unitário',
        'Quantidade',
        'Desconto Percentual',
        'Valor Bruto',
        'Valor Desconto',
        'Valor Total',
        'Valor por Item',
    ];
}

function faixas_desconto(): array
{
    return ['Sem desconto', 'Até 5%', 'De 6% a 10%', 'Acima de 10%'];
}

function eh_numero(string $texto): bool
{
    if ($texto === '') {
        return false;
    }
    return is_numeric(str_replace(',', '.', $texto));
}

function numero(string $texto): float
{
    return (float) str_replace(',', '.', $texto);
}

function brl(float $valor): string
{
    return 'R$ ' . number_format($valor, 2, ',', '.');
}

function pct(float $parte, float $total): string
{
    if ($total == 0.0) {
        return '0%';
    }
    return number_format($parte / $total * 100, 1, ',', '.') . '%';
}

function ler_csv(string $caminho): array
{
    $fonte = fopen($caminho, 'r');
    if ($fonte === false) {
        return [[], []];
    }
    $cabecalho = fgetcsv($fonte, 100000, ',', '"', '\\');
    if (!is_array($cabecalho)) {
        fclose($fonte);
        return [[], []];
    }
    $cabecalho[0] = preg_replace('/^\xEF\xBB\xBF/', '', (string) $cabecalho[0]);
    $linhas = [];
    while (($row = fgetcsv($fonte, 100000, ',', '"', '\\')) !== false) {
        if ($row === [null]) {
            continue;
        }
        $item = [];
        foreach ($cabecalho as $indice => $coluna) {
            $item[(string) $coluna] = trim((string) ($row[$indice] ?? ''));
        }
        $linhas[] = $item;
    }
    fclose($fonte);
    return [$cabecalho, $linhas];
}

function arquivos_spark(string $pasta): array
{
    $lista = glob($pasta . '/part-*.csv') ?: [];
    $lista = array_values(array_filter(
        $lista,
        static fn (string $caminho): bool => is_file($caminho) && !str_starts_with(basename($caminho), '.')
    ));
    sort($lista);
    return $lista;
}

function ler_partes(string $pasta): array
{
    $arquivos = arquivos_spark($pasta);
    $cabecalho = [];
    $linhas = [];
    foreach ($arquivos as $arquivo) {
        [$colunas, $registros] = ler_csv($arquivo);
        if ($colunas && !$cabecalho) {
            $cabecalho = $colunas;
        }
        foreach ($registros as $registro) {
            $linhas[] = $registro;
        }
    }
    return [$cabecalho, $linhas, $arquivos];
}

function grafico_spark(string $pasta): ?array
{
    [$cabecalho, $linhas, $arquivos] = ler_partes($pasta);
    if (!$cabecalho || !$linhas || !$arquivos) {
        return null;
    }

    $numericas = [];
    foreach ($cabecalho as $coluna) {
        if ($coluna === 'Número do Mês') {
            continue;
        }
        $todas = true;
        foreach ($linhas as $linha) {
            if (!eh_numero($linha[$coluna] ?? '')) {
                $todas = false;
                break;
            }
        }
        if ($todas) {
            $numericas[] = $coluna;
        }
    }

    $textos = [];
    foreach ($cabecalho as $coluna) {
        if (!in_array($coluna, $numericas, true) && $coluna !== 'Número do Mês') {
            $textos[] = $coluna;
        }
    }
    if (!$textos || !$numericas) {
        return null;
    }

    $eixo = in_array('Mês', $textos, true) ? 'Mês' : $textos[0];
    $temOrdem = in_array('Número do Mês', $cabecalho, true);
    $registros = [];
    foreach ($linhas as $linha) {
        $registro = [$eixo => $linha[$eixo]];
        if ($temOrdem) {
            $registro['_ordem'] = numero($linha['Número do Mês']);
        }
        foreach ($numericas as $coluna) {
            $registro[$coluna] = numero($linha[$coluna]);
        }
        $registros[] = $registro;
    }

    $modificado = 0;
    foreach ($arquivos as $arquivo) {
        $modificado = max($modificado, filemtime($arquivo) ?: 0);
    }
    $nome = basename($pasta);
    $titulos = titulos_graficos();

    return [
        'id' => $nome,
        'titulo' => $titulos[$nome] ?? ucfirst(str_replace('_', ' ', $nome)),
        'tipo' => $temOrdem ? 'linha' : 'barra',
        'eixo' => $eixo,
        'metricas' => $numericas,
        'linhas' => $registros,
        'origem' => ltrim(str_replace(raiz_projeto(), '', $arquivos[0]), '/'),
        'modificado' => date('d/m/Y H:i:s', $modificado),
        'manual' => false,
    ];
}

function caminho_manuais(): string
{
    return raiz_projeto() . '/results/manuais';
}

function slug_resultado(string $nome): string
{
    $nome = strtr($nome, [
        'Á' => 'a', 'À' => 'a', 'Ã' => 'a', 'Â' => 'a', 'á' => 'a', 'à' => 'a', 'ã' => 'a', 'â' => 'a',
        'É' => 'e', 'Ê' => 'e', 'é' => 'e', 'ê' => 'e',
        'Í' => 'i', 'í' => 'i',
        'Ó' => 'o', 'Ô' => 'o', 'Õ' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o',
        'Ú' => 'u', 'ú' => 'u',
        'Ç' => 'c', 'ç' => 'c',
    ]);
    $nome = strtolower($nome);
    $nome = preg_replace('/[^a-z0-9]+/', '-', $nome) ?? '';
    return trim($nome, '-');
}

function graficos_manuais(): array
{
    $pasta = caminho_manuais();
    if (!is_dir($pasta)) {
        return [];
    }
    $saida = [];
    foreach (glob($pasta . '/*.csv') ?: [] as $arquivo) {
        if (!is_file($arquivo) || str_starts_with(basename($arquivo), '.')) {
            continue;
        }
        [$cabecalho, $linhas] = ler_csv($arquivo);
        if (!$cabecalho || !$linhas) {
            continue;
        }
        $id = basename($arquivo, '.csv');
        $tituloArquivo = $pasta . '/' . $id . '.titulo';
        $titulo = is_file($tituloArquivo) ? trim((string) file_get_contents($tituloArquivo)) : $id;
        $temporario = sys_get_temp_dir() . '/pi-' . $id;
        if (!is_dir($temporario)) {
            mkdir($temporario, 0775, true);
        }
        copy($arquivo, $temporario . '/part-00000.csv');
        $grafico = grafico_spark($temporario);
        if (!$grafico) {
            continue;
        }
        $grafico['id'] = 'manual-' . $id;
        $grafico['titulo'] = $titulo !== '' ? $titulo : $id;
        $grafico['origem'] = 'results/manuais/' . basename($arquivo);
        $grafico['modificado'] = date('d/m/Y H:i:s', filemtime($arquivo) ?: time());
        $grafico['manual'] = true;
        $saida[] = $grafico;
    }
    usort($saida, static fn (array $a, array $b): int => strcmp($a['titulo'], $b['titulo']));
    return $saida;
}

function quartis(array $valores): array
{
    sort($valores);
    $em = static function (float $fracao) use ($valores): float {
        $indice = (count($valores) - 1) * $fracao;
        $baixo = (int) $indice;
        $alto = min($baixo + 1, count($valores) - 1);
        $peso = $indice - $baixo;
        return $valores[$baixo] * (1 - $peso) + $valores[$alto] * $peso;
    };
    return [
        'min' => $valores[0],
        'q1' => $em(0.25),
        'mediana' => $em(0.5),
        'q3' => $em(0.75),
        'max' => $valores[count($valores) - 1],
    ];
}

function pearson(array $xs, array $ys): float
{
    $quantidade = count($xs);
    if ($quantidade < 2) {
        return 0.0;
    }
    $mediaX = array_sum($xs) / $quantidade;
    $mediaY = array_sum($ys) / $quantidade;
    $numerador = 0.0;
    $desvioX = 0.0;
    $desvioY = 0.0;
    foreach ($xs as $indice => $x) {
        $y = $ys[$indice];
        $numerador += ($x - $mediaX) * ($y - $mediaY);
        $desvioX += ($x - $mediaX) ** 2;
        $desvioY += ($y - $mediaY) ** 2;
    }
    $desvioX = $desvioX ** 0.5;
    $desvioY = $desvioY ** 0.5;
    if ($desvioX == 0.0 || $desvioY == 0.0) {
        return 0.0;
    }
    return $numerador / ($desvioX * $desvioY);
}

function graficos_processados(): array
{
    [$cabecalho, $linhas] = ler_csv(caminho_processado());
    if (!$linhas) {
        return [];
    }
    $modificado = date('d/m/Y H:i:s', filemtime(caminho_processado()) ?: time());
    $origem = 'data/processed/vendas_processadas.csv';
    $saida = [];

    if (in_array('Valor Total', $cabecalho, true)) {
        $valores = [];
        foreach ($linhas as $linha) {
            if (eh_numero($linha['Valor Total'])) {
                $valores[] = numero($linha['Valor Total']);
            }
        }
        if ($valores) {
            $menor = min($valores);
            $maior = max($valores);
            $faixas = 12;
            $largura = ($maior - $menor) / $faixas ?: 1;
            $contagem = array_fill(0, $faixas, 0);
            foreach ($valores as $valor) {
                $indice = min($faixas - 1, (int) (($valor - $menor) / $largura));
                $contagem[$indice]++;
            }
            $registros = [];
            foreach ($contagem as $indice => $quantidade) {
                $inicio = $menor + $indice * $largura;
                $fim = $inicio + $largura;
                $registros[] = [
                    'Faixa' => sprintf('%.0f–%.0f', $inicio, $fim),
                    'Pedidos' => $quantidade,
                ];
            }
            $saida[] = [
                'id' => 'distribuicao_valor',
                'titulo' => 'Distribuição do valor',
                'tipo' => 'barra',
                'eixo' => 'Faixa',
                'metricas' => ['Pedidos'],
                'linhas' => $registros,
                'origem' => $origem,
                'modificado' => $modificado,
            ];
            $caixa = quartis($valores);
            $saida[] = [
                'id' => 'boxplot_valor',
                'titulo' => 'Valores atípicos',
                'tipo' => 'caixa',
                'eixo' => 'Resumo',
                'metricas' => ['Valor Total'],
                'linhas' => [array_merge(['Resumo' => 'Pedidos'], $caixa)],
                'origem' => $origem,
                'modificado' => $modificado,
            ];
        }
    }

    if (in_array('Faixa de Desconto', $cabecalho, true)) {
        $contagemFaixa = array_fill_keys(faixas_desconto(), 0);
        foreach ($linhas as $linha) {
            $faixa = $linha['Faixa de Desconto'];
            $contagemFaixa[$faixa] = ($contagemFaixa[$faixa] ?? 0) + 1;
        }
        $registros = [];
        foreach ($contagemFaixa as $faixa => $quantidade) {
            $registros[] = ['Faixa' => $faixa, 'Pedidos' => $quantidade];
        }
        $saida[] = [
            'id' => 'faixa_desconto',
            'titulo' => 'Faixa de desconto',
            'tipo' => 'barra',
            'eixo' => 'Faixa',
            'metricas' => ['Pedidos'],
            'linhas' => $registros,
            'origem' => $origem,
            'modificado' => $modificado,
        ];
    }

    if (in_array('Quantidade', $cabecalho, true) && in_array('Valor Total', $cabecalho, true)) {
        $pontos = [];
        foreach ($linhas as $linha) {
            if (eh_numero($linha['Quantidade']) && eh_numero($linha['Valor Total'])) {
                $pontos[] = [
                    'Quantidade' => numero($linha['Quantidade']),
                    'Valor Total' => numero($linha['Valor Total']),
                ];
            }
        }
        if ($pontos) {
            $saida[] = [
                'id' => 'quantidade_valor',
                'titulo' => 'Quantidade e valor',
                'tipo' => 'dispersao',
                'eixo' => 'Quantidade',
                'metricas' => ['Valor Total'],
                'linhas' => $pontos,
                'origem' => $origem,
                'modificado' => $modificado,
            ];
        }
    }

    $presentes = array_values(array_filter(
        colunas_correlacao(),
        static fn (string $coluna): bool => in_array($coluna, $cabecalho, true)
    ));
    $series = [];
    foreach ($presentes as $coluna) {
        $serie = [];
        foreach ($linhas as $linha) {
            if (eh_numero($linha[$coluna])) {
                $serie[] = numero($linha[$coluna]);
            }
        }
        $series[$coluna] = $serie;
    }
    $completas = $presentes && array_reduce(
        $presentes,
        static fn (bool $ok, string $coluna): bool => $ok && count($series[$coluna]) === count($linhas),
        true
    );
    if ($completas && count($presentes) >= 2) {
        $matriz = [];
        foreach ($presentes as $linhaNome) {
            $registro = ['Variável' => $linhaNome];
            foreach ($presentes as $colunaNome) {
                $registro[$colunaNome] = round(pearson($series[$linhaNome], $series[$colunaNome]), 2);
            }
            $matriz[] = $registro;
        }
        $saida[] = [
            'id' => 'correlacao',
            'titulo' => 'Correlação',
            'tipo' => 'matriz',
            'eixo' => 'Variável',
            'metricas' => $presentes,
            'linhas' => $matriz,
            'origem' => $origem,
            'modificado' => $modificado,
        ];
    }

    return $saida;
}

function arquivos_acompanhados(): array
{
    $arquivos = [];
    $spark = caminho_spark();
    if (is_dir($spark)) {
        foreach (scandir($spark) ?: [] as $nome) {
            if ($nome === '.' || $nome === '..') {
                continue;
            }
            $pasta = $spark . '/' . $nome;
            if (is_dir($pasta)) {
                foreach (arquivos_spark($pasta) as $arquivo) {
                    $arquivos[] = $arquivo;
                }
            }
        }
    }
    if (is_file(caminho_processado())) {
        $arquivos[] = caminho_processado();
    }
    foreach (glob(caminho_manuais() . '/*.csv') ?: [] as $arquivo) {
        if (is_file($arquivo)) {
            $arquivos[] = $arquivo;
        }
    }
    sort($arquivos);
    return $arquivos;
}

function versao_atual(): string
{
    $partes = [];
    foreach (arquivos_acompanhados() as $arquivo) {
        $partes[] = $arquivo . ':' . filemtime($arquivo) . ':' . filesize($arquivo);
    }
    return substr(hash('sha256', implode("\n", $partes)), 0, 16);
}

function achar_grafico(array $graficos, string $id): ?array
{
    foreach ($graficos as $grafico) {
        if ($grafico['id'] === $id) {
            return $grafico;
        }
    }
    return null;
}

function soma_coluna(array $grafico, string $coluna): float
{
    $total = 0.0;
    foreach ($grafico['linhas'] as $linha) {
        $total += (float) ($linha[$coluna] ?? 0);
    }
    return $total;
}

function linha_extremo(array $grafico, string $coluna, bool $maior): ?array
{
    $escolhida = null;
    foreach ($grafico['linhas'] as $linha) {
        if (!isset($linha[$coluna])) {
            continue;
        }
        if ($escolhida === null) {
            $escolhida = $linha;
            continue;
        }
        $atual = (float) $linha[$coluna];
        $referencia = (float) $escolhida[$coluna];
        if ($maior ? $atual > $referencia : $atual < $referencia) {
            $escolhida = $linha;
        }
    }
    return $escolhida;
}

function montar_resumo(array $graficos): array
{
    $categoria = achar_grafico($graficos, 'faturamento_categoria');
    $produto = achar_grafico($graficos, 'faturamento_produto');
    $canal = achar_grafico($graficos, 'faturamento_canal');
    $regiao = achar_grafico($graficos, 'faturamento_regiao');
    $mensal = achar_grafico($graficos, 'faturamento_mensal');

    $base = $categoria ?? $produto ?? $canal;
    $faturamento = $base ? soma_coluna($base, 'Faturamento') : 0.0;
    $pedidos = $base && in_array('Pedidos', $base['metricas'], true) ? soma_coluna($base, 'Pedidos') : 0.0;
    $ticket = $pedidos > 0 ? $faturamento / $pedidos : 0.0;

    $frases = [
        'abertura' => 'De onde vem o faturamento desta base simulada da Track & Field? O pipeline gera, trata e agrega os pedidos. A fala segue esses arquivos.',
        'ano' => 'Ainda não há agregados de faturamento para montar o número do ano.',
        'mix' => 'O mix de categorias aparece quando o Spark grava faturamento_categoria.',
        'produtos' => 'O ranking de produtos aparece quando o Spark grava faturamento_produto.',
        'canais' => 'A comparação de canais aparece quando o Spark grava faturamento_canal.',
        'regioes' => 'A comparação de regiões aparece quando o Spark grava faturamento_regiao.',
        'calendario' => 'A série mensal aparece quando o Spark grava faturamento_mensal.',
        'fecho' => 'Feche dizendo o que a base sustenta e que o pipeline torna o recorte reproduzível.',
    ];
    $perguntas = [];

    if ($faturamento > 0 && $pedidos > 0) {
        $frases['ano'] = 'O período soma ' . brl($faturamento) . ' em ' . number_format($pedidos, 0, ',', '.') . ' pedidos. O ticket médio é ' . brl($ticket) . '.';
    }

    if ($categoria) {
        $porReceita = linha_extremo($categoria, 'Faturamento', true);
        $porVolume = linha_extremo($categoria, 'Pedidos', true);
        if ($porReceita && $porVolume) {
            $ticketReceita = $porReceita['Pedidos'] > 0 ? $porReceita['Faturamento'] / $porReceita['Pedidos'] : 0;
            $ticketVolume = $porVolume['Pedidos'] > 0 ? $porVolume['Faturamento'] / $porVolume['Pedidos'] : 0;
            $frases['mix'] = $porReceita['Categoria'] . ' concentra ' . pct($porReceita['Faturamento'], $faturamento)
                . ' da receita, com ticket de ' . brl($ticketReceita) . '. '
                . $porVolume['Categoria'] . ' responde por ' . pct($porVolume['Pedidos'], $pedidos)
                . ' dos pedidos, com ticket de ' . brl($ticketVolume) . '.';
            $perguntas[] = [
                'pergunta' => 'Por que a categoria com mais pedidos não é a que mais fatura?',
                'resposta' => $porVolume['Categoria'] . ' vende volume. ' . $porReceita['Categoria'] . ' vende ticket: ' . brl($ticketReceita) . ' contra ' . brl($ticketVolume) . '.',
            ];
        }
    }

    if ($produto && $faturamento > 0) {
        $ordenados = $produto['linhas'];
        usort($ordenados, static fn (array $a, array $b): int => $b['Faturamento'] <=> $a['Faturamento']);
        $primeiro = $ordenados[0] ?? null;
        $segundo = $ordenados[1] ?? null;
        if ($primeiro && $segundo) {
            $soma = $primeiro['Faturamento'] + $segundo['Faturamento'];
            $frases['produtos'] = $primeiro['Produto'] . ' e ' . $segundo['Produto'] . ' somam ' . brl($soma) . ', ' . pct($soma, $faturamento) . ' do período.';
            $perguntas[] = [
                'pergunta' => 'Qual produto sustenta a receita?',
                'resposta' => $primeiro['Produto'] . ' lidera com ' . brl($primeiro['Faturamento']) . ', ' . pct($primeiro['Faturamento'], $faturamento) . ' do total.',
            ];
        }
    }

    if ($canal && $faturamento > 0) {
        $partes = [];
        foreach ($canal['linhas'] as $linha) {
            $partes[] = $linha['Canal de Venda'] . ' ' . pct($linha['Faturamento'], $faturamento);
        }
        $frases['canais'] = 'A receita se divide assim: ' . implode(', ', $partes) . '. Nenhum canal concentra a venda sozinho.';
        $lider = linha_extremo($canal, 'Faturamento', true);
        if ($lider) {
            $perguntas[] = [
                'pergunta' => 'O digital já passou a loja física?',
                'resposta' => 'Ainda não como bloco único. ' . $lider['Canal de Venda'] . ' está na frente, com ' . pct($lider['Faturamento'], $faturamento) . ' da receita.',
            ];
        }
    }

    if ($regiao && $faturamento > 0) {
        $maior = linha_extremo($regiao, 'Faturamento', true);
        $menor = linha_extremo($regiao, 'Faturamento', false);
        if ($maior && $menor) {
            $pontos = ($maior['Faturamento'] - $menor['Faturamento']) / $faturamento * 100;
            $frases['regioes'] = $maior['Região'] . ' lidera com ' . pct($maior['Faturamento'], $faturamento)
                . '. A diferença para ' . $menor['Região'] . ' é de ' . number_format($pontos, 1, ',', '.') . ' pontos percentuais.';
        }
    }

    if ($mensal) {
        $pico = linha_extremo($mensal, 'Faturamento', true);
        $vale = linha_extremo($mensal, 'Faturamento', false);
        $media = soma_coluna($mensal, 'Faturamento') / max(count($mensal['linhas']), 1);
        if ($pico && $vale) {
            $frases['calendario'] = $vale['Mês'] . ' é o menor mês, ' . brl($vale['Faturamento']) . '. '
                . $pico['Mês'] . ' é o maior, ' . brl($pico['Faturamento']) . '. A média mensal é ' . brl($media) . '.';
        }
    }

    $frases['fecho'] = 'O valor está concentrado em poucos produtos, o volume em outra categoria, e canal e região não dominam sozinhos. O pipeline deixa esse recorte reproduzível.';

    return [
        'faturamento' => $faturamento,
        'pedidos' => $pedidos,
        'ticket' => $ticket,
        'faturamento_texto' => brl($faturamento),
        'pedidos_texto' => number_format($pedidos, 0, ',', '.'),
        'ticket_texto' => brl($ticket),
        'frases' => $frases,
        'perguntas' => $perguntas,
    ];
}

function montar_dados(): array
{
    $graficos = [];
    $spark = caminho_spark();
    if (is_dir($spark)) {
        $pastas = [];
        foreach (scandir($spark) ?: [] as $nome) {
            if ($nome === '.' || $nome === '..') {
                continue;
            }
            $pasta = $spark . '/' . $nome;
            if (is_dir($pasta)) {
                $pastas[] = $pasta;
            }
        }
        $ordem = ordem_pastas();
        usort($pastas, static function (string $a, string $b) use ($ordem): int {
            $ia = array_search(basename($a), $ordem, true);
            $ib = array_search(basename($b), $ordem, true);
            $ia = $ia === false ? 99 : $ia;
            $ib = $ib === false ? 99 : $ib;
            return $ia <=> $ib ?: strcmp($a, $b);
        });
        foreach ($pastas as $pasta) {
            $grafico = grafico_spark($pasta);
            if ($grafico) {
                $graficos[] = $grafico;
            }
        }
    }
    if (is_file(caminho_processado())) {
        foreach (graficos_processados() as $grafico) {
            $graficos[] = $grafico;
        }
    }
    foreach (graficos_manuais() as $grafico) {
        $graficos[] = $grafico;
    }

    return [
        'versao' => versao_atual(),
        'processado' => is_file(caminho_processado()),
        'resumo' => montar_resumo($graficos),
        'graficos' => $graficos,
    ];
}

