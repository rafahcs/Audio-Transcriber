$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$python = Join-Path $root ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Host "Criando ambiente Python em .venv..."
    python -m venv (Join-Path $root ".venv")
    if ($LASTEXITCODE -ne 0) {
        throw "Não foi possível criar o ambiente virtual. Verifique a instalação do Python."
    }
}

Write-Host "Instalando/verificando dependências..."
& $python -m pip install --quiet -r (Join-Path $root "requirements.txt")
if ($LASTEXITCODE -ne 0) {
    throw "A instalação das dependências falhou. Confira a conexão e a mensagem acima."
}

$env:PYTHONPATH = $root

Write-Host "Iniciando o backend..."
$backend = Start-Process -FilePath $python `
    -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000") `
    -WorkingDirectory $root `
    -PassThru

$health = $null
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    if ($backend.HasExited) {
        throw "O backend encerrou durante a inicialização. Veja a janela do backend."
    }

    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -TimeoutSec 2
        break
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if ($null -eq $health) {
    Stop-Process -Id $backend.Id -ErrorAction SilentlyContinue
    throw "O backend não respondeu em http://127.0.0.1:8000/health. Veja a janela do backend."
}

Write-Host "Backend pronto. Iniciando o Streamlit..."
try {
    $frontend = Start-Process -FilePath $python `
        -ArgumentList @("-m", "streamlit", "run", "app\streamlit_app.py", "--server.address=127.0.0.1", "--server.port=8501") `
        -WorkingDirectory $root `
        -PassThru
    Start-Sleep -Seconds 2
    if ($frontend.HasExited) {
        throw "O Streamlit encerrou durante a inicialização. Veja a janela do Streamlit."
    }
}
catch {
    Stop-Process -Id $backend.Id -ErrorAction SilentlyContinue
    throw
}

Write-Host ""
Write-Host "Aplicação: http://localhost:8501"
Write-Host "API:       http://localhost:8000/docs"
Write-Host "Saúde:     http://localhost:8000/health"
Write-Host "Feche as janelas do backend e do Streamlit para encerrar os serviços."
