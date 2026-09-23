<?php

declare(strict_types=1);

require dirname(__DIR__, 2) . '/src/dados.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$dados = montar_dados();
if (($_GET['somente'] ?? '') === 'versao') {
    echo json_encode(['versao' => $dados['versao']], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode($dados, JSON_UNESCAPED_UNICODE);
