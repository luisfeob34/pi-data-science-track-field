param([string]$Url = 'http://localhost:8080', [int]$PortaDebug = 9222)
$ErrorActionPreference = 'Stop'
$raizProjeto = Split-Path $PSScriptRoot -Parent
$edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$profilePath = Join-Path $env:TEMP ('pi-r-browser-' + [guid]::NewGuid().ToString('N'))
$edgeArgs = @('--headless', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--window-size=1500,1100', "--remote-debugging-port=$PortaDebug",
    ('--user-data-dir="' + $profilePath + '"'), $Url)
$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList $edgeArgs -WindowStyle Hidden -PassThru
$socket = [Net.WebSockets.ClientWebSocket]::new()
$script:mensagemId = 0
function Enviar-CDP([string]$Metodo, [hashtable]$Parametros = @{}) {
    $script:mensagemId++
    $id = $script:mensagemId
    $mensagem = @{id = $id; method = $Metodo; params = $Parametros} | ConvertTo-Json -Depth 20 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($mensagem)
    $limite = [Threading.CancellationTokenSource]::new(15000)
    try {
        $socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, $limite.Token).GetAwaiter().GetResult()
        do {
            $fluxo = [IO.MemoryStream]::new()
            do {
                $buffer = New-Object byte[] 65536
                $recebido = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $limite.Token).GetAwaiter().GetResult()
                $fluxo.Write($buffer, 0, $recebido.Count)
            } until ($recebido.EndOfMessage)
            $resposta = [Text.Encoding]::UTF8.GetString($fluxo.ToArray()) | ConvertFrom-Json
            $fluxo.Dispose()
        } until ($resposta.id -eq $id)
        if ($resposta.error) { throw ($resposta.error | ConvertTo-Json -Compress) }
        return $resposta.result
    } finally { $limite.Dispose() }
}
function Avaliar([string]$Expressao) {
    $resultado = Enviar-CDP 'Runtime.evaluate' @{expression = $Expressao; returnByValue = $true}
    if ($resultado.exceptionDetails) { throw ($resultado.exceptionDetails | ConvertTo-Json -Compress) }
    return $resultado.result.value
}
function Aguardar([string]$Expressao) {
    for ($tentativa = 0; $tentativa -lt 40; $tentativa++) {
        if (Avaliar $Expressao) { return }
        Start-Sleep -Milliseconds 500
    }
    throw ('Falha na verificação: ' + $Expressao + ' | largura: ' + (Avaliar 'window.innerWidth') + ' | rolagem: ' + (Avaliar 'document.documentElement.scrollWidth'))
}
try {
    $alvo = $null
    for ($tentativa = 0; $tentativa -lt 20 -and !$alvo; $tentativa++) {
        try {
            $paginas = Invoke-RestMethod "http://localhost:$PortaDebug/json"
            $alvo = $paginas | Where-Object { $_.type -eq 'page' -and $_.url.StartsWith($Url) } | Select-Object -First 1
        } catch { }
        if (!$alvo) { Start-Sleep -Milliseconds 500 }
    }
    if (!$alvo) { throw 'Não foi possível conectar ao navegador de teste.' }
    $socket.ConnectAsync([Uri]$alvo.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    Enviar-CDP 'Page.enable' | Out-Null
    Aguardar "document.querySelectorAll('#kpis .kpi').length === 4 && document.querySelectorAll('#ranking .main-svg').length > 0"
    $indicadores = Avaliar "document.querySelector('#kpis').innerText"
    Write-Output $indicadores
    $captura = Enviar-CDP 'Page.captureScreenshot' @{format = 'png'; captureBeyondViewport = $false}
    [IO.File]::WriteAllBytes((Join-Path $raizProjeto 'results/r/painel-shiny.png'), [Convert]::FromBase64String($captura.data))
    Avaliar 'document.querySelector(''a[data-value="previsoes"]'').click()' | Out-Null
    Aguardar "document.querySelectorAll('#previsao_grafico .main-svg').length > 0 && document.querySelectorAll('#previsao_tabela table tbody tr').length > 0"
    Write-Output (Avaliar "document.querySelector('#nota_previsao').innerText")
    $captura = Enviar-CDP 'Page.captureScreenshot' @{format = 'png'; captureBeyondViewport = $false}
    [IO.File]::WriteAllBytes((Join-Path $raizProjeto 'results/r/painel-previsoes.png'), [Convert]::FromBase64String($captura.data))
    Avaliar "document.querySelector('#validacao').closest('details').open = true" | Out-Null
    Aguardar "document.querySelectorAll('#validacao table tbody tr').length === 3"
    Avaliar 'document.querySelector(''a[data-value="estatistica"]'').click()' | Out-Null
    Aguardar "document.querySelectorAll('#leituras .leitura').length === 5"
    Avaliar "document.querySelector('#testes').closest('details').open = true" | Out-Null
    Aguardar "document.querySelectorAll('#testes table tbody tr').length === 5"
    $erros = Avaliar "Array.from(document.querySelectorAll('.shiny-output-error:not(.shiny-output-error-validation)')).map(x => x.innerText).join('; ')"
    if ($erros) { throw $erros }
    Enviar-CDP 'Emulation.setDeviceMetricsOverride' @{width = 390; height = 844; deviceScaleFactor = 1; mobile = $true} | Out-Null
    Avaliar 'document.querySelector(''a[data-value="visao"]'').click(); window.scrollTo(0, 0)' | Out-Null
    Aguardar "window.innerWidth === 390 && !document.querySelector('#filtros-painel').open"
    Aguardar "document.documentElement.scrollWidth <= window.innerWidth + 2"
    Avaliar "document.querySelector('#filtros-painel summary').click()" | Out-Null
    Aguardar "document.querySelector('#filtros-painel').open"
    Avaliar "document.querySelector('#categorias').selectize.setValue('Calçados')" | Out-Null
    Aguardar "document.querySelector('#filtros_ativos').innerText.includes('Calçados')"
    Avaliar "document.querySelector('#limpar').click()" | Out-Null
    Aguardar "!document.querySelector('#filtros_ativos').innerText.includes('Categorias:')"
    Avaliar "document.querySelector('#filtros-painel summary').click(); window.scrollTo(0, 0)" | Out-Null
    $captura = Enviar-CDP 'Page.captureScreenshot' @{format = 'png'; captureBeyondViewport = $false}
    [IO.File]::WriteAllBytes((Join-Path $raizProjeto 'results/r/painel-mobile.png'), [Convert]::FromBase64String($captura.data))
    Avaliar "window.scrollTo(0, 1000)" | Out-Null
    Aguardar "document.querySelector('#aba').getBoundingClientRect().top >= 0 && document.querySelector('#aba').getBoundingClientRect().top < 30"
    Write-Output 'Tela de 390px validada: filtros, limpeza, abas fixas e layout sem rolagem horizontal.'
    Write-Output 'Navegador validado: KPIs, ranking, previsões e cinco testes estatísticos renderizados.'
} finally {
    if ($socket.State -eq [Net.WebSockets.WebSocketState]::Open) {
        try { Enviar-CDP 'Browser.close' | Out-Null } catch { }
    }
    $socket.Dispose()
    if (!$edgeProcess.HasExited) { Stop-Process -Id $edgeProcess.Id -ErrorAction SilentlyContinue }
}
