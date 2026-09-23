<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$pasta = dirname(__DIR__, 2) . '/estado';
if (!is_dir($pasta) && !mkdir($pasta, 0775, true) && !is_dir($pasta)) {
    http_response_code(500);
    echo json_encode(['estado' => 'erro', 'mensagem' => 'Não foi possível preparar a geração.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$pedido = $pasta . '/pedido';
$status = $pasta . '/status.json';

$ler = static function () use ($status): array {
    if (!is_file($status)) {
        return ['estado' => 'ocioso', 'mensagem' => ''];
    }
    $dados = json_decode((string) file_get_contents($status), true);
    if (!is_array($dados)) {
        return ['estado' => 'ocioso', 'mensagem' => ''];
    }
    return [
        'estado' => (string) ($dados['estado'] ?? 'ocioso'),
        'mensagem' => (string) ($dados['mensagem'] ?? ''),
    ];
};

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $atual = $ler();
    if ($atual['estado'] === 'rodando' || is_file($pedido)) {
        echo json_encode(['estado' => 'rodando', 'mensagem' => 'Gerando novas vendas…'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    file_put_contents($status, json_encode([
        'estado' => 'rodando',
        'mensagem' => 'Gerando novas vendas…',
    ], JSON_UNESCAPED_UNICODE));
    file_put_contents($pedido, (string) time());
    echo json_encode(['estado' => 'rodando', 'mensagem' => 'Gerando novas vendas…'], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode($ler(), JSON_UNESCAPED_UNICODE);
