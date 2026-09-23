<?php

declare(strict_types=1);

$paginas = [
    'resultados' => 'Resultados',
    'comparar' => 'Comparar',
];
$pagina = (string) ($_GET['pagina'] ?? 'resultados');
if ($pagina === 'explorar') {
    $pagina = 'resultados';
}
if (!isset($paginas[$pagina])) {
    $pagina = 'resultados';
}
$grafico = (string) ($_GET['grafico'] ?? '');
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= htmlspecialchars($paginas[$pagina], ENT_QUOTES, 'UTF-8') ?> · Track & Field</title>
  <link rel="stylesheet" href="assets/estilo.css">
</head>
<body data-pagina="<?= htmlspecialchars($pagina, ENT_QUOTES, 'UTF-8') ?>" data-grafico="<?= htmlspecialchars($grafico, ENT_QUOTES, 'UTF-8') ?>">
  <header class="topo">
    <div>
      <p class="marca">PI · Ciência de dados</p>
      <strong>Resultados</strong>
    </div>
    <nav>
      <a class="ativa" href="index.php">Resultados</a>
    </nav>
    <button id="gerar" class="primario" type="button">Gerar dados novamente</button>
    <p id="status" class="status"></p>
  </header>
  <main id="app">
    <p>Carregando os resultados…</p>
  </main>
  <div id="dica" hidden></div>
  <script src="assets/app.js"></script>
</body>
</html>
