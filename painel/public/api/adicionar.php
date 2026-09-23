<?php

declare(strict_types=1);

require dirname(__DIR__, 2) . '/src/dados.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['erro' => 'Use POST.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$acao = (string) ($_POST['acao'] ?? '');

if ($acao === 'remover') {
    $id = (string) ($_POST['id'] ?? '');
    if (!preg_match('/^manual-[a-z0-9-]{1,60}$/', $id)) {
        http_response_code(400);
        echo json_encode(['erro' => 'Resultado inválido.'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $slug = substr($id, 7);
    $pasta = caminho_manuais();
    $csv = $pasta . '/' . $slug . '.csv';
    $base = realpath($pasta);
    $real = realpath($csv);
    if ($base === false || $real === false || !str_starts_with($real, $base . DIRECTORY_SEPARATOR)) {
        http_response_code(404);
        echo json_encode(['erro' => 'Resultado não encontrado.'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    unlink($real);
    $titulo = $pasta . '/' . $slug . '.titulo';
    if (is_file($titulo)) {
        unlink($titulo);
    }
    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($acao !== 'adicionar') {
    http_response_code(400);
    echo json_encode(['erro' => 'Ação desconhecida.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$nome = trim((string) ($_POST['nome'] ?? ''));
$slug = slug_resultado($nome);
if ($slug === '' || strlen($slug) > 60) {
    http_response_code(400);
    echo json_encode(['erro' => 'Dê um nome ao resultado, usando letras ou números.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$arquivo = $_FILES['arquivo'] ?? null;
if (!is_array($arquivo) || ($arquivo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['erro' => 'Escolha um arquivo CSV.'], JSON_UNESCAPED_UNICODE);
    exit;
}
if (($arquivo['size'] ?? 0) > 2000000) {
    http_response_code(400);
    echo json_encode(['erro' => 'O CSV passa de 2 MB.'], JSON_UNESCAPED_UNICODE);
    exit;
}
if (strtolower(pathinfo((string) $arquivo['name'], PATHINFO_EXTENSION)) !== 'csv') {
    http_response_code(400);
    echo json_encode(['erro' => 'O arquivo precisa terminar em .csv.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$pasta = caminho_manuais();
if (!is_dir($pasta) && !mkdir($pasta, 0775, true) && !is_dir($pasta)) {
    http_response_code(500);
    echo json_encode(['erro' => 'Não foi possível criar a pasta de resultados.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$destino = $pasta . '/' . $slug . '.csv';
if (!move_uploaded_file((string) $arquivo['tmp_name'], $destino)) {
    http_response_code(500);
    echo json_encode(['erro' => 'Não foi possível gravar o CSV.'], JSON_UNESCAPED_UNICODE);
    exit;
}
file_put_contents($pasta . '/' . $slug . '.titulo', $nome);

$valido = false;
foreach (graficos_manuais() as $grafico) {
    if ($grafico['id'] === 'manual-' . $slug) {
        $valido = true;
        break;
    }
}
if (!$valido) {
    unlink($destino);
    $titulo = $pasta . '/' . $slug . '.titulo';
    if (is_file($titulo)) {
        unlink($titulo);
    }
    http_response_code(400);
    echo json_encode(['erro' => 'O CSV precisa de uma coluna de nomes e pelo menos uma coluna numérica.'], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode(['ok' => true, 'id' => 'manual-' . $slug], JSON_UNESCAPED_UNICODE);
