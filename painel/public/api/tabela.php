<?php

declare(strict_types=1);

require dirname(__DIR__, 2) . '/src/dados.php';

$id = (string) ($_GET['id'] ?? '');
$grafico = achar_grafico(montar_dados()['graficos'], $id);
if ($grafico === null || $grafico['tipo'] === 'dispersao') {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Gráfico não encontrado.';
    exit;
}

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="' . $id . '.csv"');

$saida = fopen('php://output', 'w');
if ($grafico['tipo'] === 'caixa') {
    fputcsv($saida, ['min', 'q1', 'mediana', 'q3', 'max'], ',', '"', '\\');
    $linha = $grafico['linhas'][0];
    fputcsv($saida, [$linha['min'], $linha['q1'], $linha['mediana'], $linha['q3'], $linha['max']], ',', '"', '\\');
    exit;
}

$colunas = array_merge([$grafico['eixo']], $grafico['metricas']);
fputcsv($saida, $colunas, ',', '"', '\\');
foreach ($grafico['linhas'] as $linha) {
    $registro = [];
    foreach ($colunas as $coluna) {
        $registro[] = $linha[$coluna] ?? '';
    }
    fputcsv($saida, $registro, ',', '"', '\\');
}
