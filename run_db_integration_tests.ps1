# Script PowerShell para executar testes de integração com banco de dados

# Definir cores para mensagens
$infoColor = "Cyan"
$successColor = "Green"
$errorColor = "Red"

# Banner
Write-Host ""
Write-Host "============================================================" -ForegroundColor $infoColor
Write-Host "     MAGAPP - TESTES DE INTEGRAÇÃO COM BANCO DE DADOS       " -ForegroundColor $infoColor
Write-Host "============================================================" -ForegroundColor $infoColor
Write-Host ""

# Definir variáveis de ambiente para testes
$env:TEST_DB_HOST = "localhost"
$env:TEST_DB_USER = "test_user"
$env:TEST_DB_PASSWORD = "test_password"
$env:TEST_DB_NAME = "magapp_test"

# Verificar se as variáveis de ambiente foram definidas corretamente
Write-Host "[INFO] Configurações do ambiente de teste:" -ForegroundColor $infoColor
Write-Host "- Host: $($env:TEST_DB_HOST)"
Write-Host "- Usuário: $($env:TEST_DB_USER)"
Write-Host "- Banco: $($env:TEST_DB_NAME)"
Write-Host ""

# Diretório do backend
$backendDir = Join-Path $PSScriptRoot "backend"
Set-Location -Path $backendDir

# Verificar se o MySQL está instalado e acessível
Write-Host "[INFO] Verificando conexão com MySQL..." -ForegroundColor $infoColor
try {
    mysql --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ALERTA] MySQL CLI não encontrado no PATH. Verifique se o MySQL está instalado corretamente." -ForegroundColor "Yellow"
    }
    else {
        Write-Host "[INFO] MySQL CLI detectado." -ForegroundColor $infoColor
    }
}
catch {
    Write-Host "[ALERTA] MySQL CLI não encontrado. Os testes podem falhar se o MySQL não estiver configurado." -ForegroundColor "Yellow"
}

# Configurar o banco de dados de teste
Write-Host ""
Write-Host "[INFO] Configurando banco de dados de teste..." -ForegroundColor $infoColor
try {
    npm run setup:test-db
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ALERTA] Não foi possível configurar o banco de dados de teste automaticamente." -ForegroundColor "Yellow"
        Write-Host "         Você precisará criar manualmente um banco 'magapp_test' com o usuário 'test_user'." -ForegroundColor "Yellow"
    }
    else {
        Write-Host "[INFO] Banco de dados de teste configurado com sucesso." -ForegroundColor $infoColor
    }
}
catch {
    Write-Host "[ALERTA] Erro ao configurar banco de dados: $_" -ForegroundColor "Yellow"
    Write-Host "         Prosseguindo com os testes. Os testes com banco real podem falhar." -ForegroundColor "Yellow"
}

# Função para executar comando e verificar status
function Invoke-CommandWithCheck {
    param (
        [string]$Command,
        [string]$ErrorMessage
    )

    try {
        Write-Host "[INFO] Executando: $Command" -ForegroundColor $infoColor
        Invoke-Expression $Command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERRO] $ErrorMessage (Código: $LASTEXITCODE)" -ForegroundColor $errorColor
            exit $LASTEXITCODE
        }
    }
    catch {
        Write-Host "[ERRO] $ErrorMessage. Detalhes: $_" -ForegroundColor $errorColor
        exit 1
    }
}

# Executar testes com banco de dados mock
Write-Host ""
Write-Host "[INFO] Executando testes de integração com banco de dados mock..." -ForegroundColor $infoColor
Invoke-CommandWithCheck -Command "npm run test:mock-db" -ErrorMessage "Falha nos testes com banco de dados mock"
Write-Host "[SUCESSO] Testes com banco de dados mock concluídos com sucesso." -ForegroundColor $successColor

# Executar testes com banco de dados real
Write-Host ""
Write-Host "[INFO] Executando testes de integração com banco de dados real..." -ForegroundColor $infoColor
Invoke-CommandWithCheck -Command "npm run test:db" -ErrorMessage "Falha nos testes com banco de dados real"
Write-Host "[SUCESSO] Testes com banco de dados real concluídos com sucesso." -ForegroundColor $successColor

# Mensagem final
Write-Host ""
Write-Host "============================================================" -ForegroundColor $successColor
Write-Host "     TODOS OS TESTES DE INTEGRAÇÃO DE BD CONCLUÍDOS         " -ForegroundColor $successColor
Write-Host "============================================================" -ForegroundColor $successColor
Write-Host ""
