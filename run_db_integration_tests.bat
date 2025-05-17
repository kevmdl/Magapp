@echo off
REM filepath: c:\Users\Kevim\Magapp\run_db_integration_tests.bat
REM Script para executar testes de integração com banco de dados

echo.
echo ============================================================
echo      MAGAPP - TESTES DE INTEGRACAO COM BANCO DE DADOS
echo ============================================================
echo.

REM Definir variáveis de ambiente para testes
set "TEST_DB_HOST=localhost"
set "TEST_DB_USER=test_user"
set "TEST_DB_PASSWORD=test_password"
set "TEST_DB_NAME=magapp_test"

REM Exibir configurações
echo [INFO] Configuracoes do ambiente de teste:
echo - Host: %TEST_DB_HOST%
echo - Usuario: %TEST_DB_USER%
echo - Banco: %TEST_DB_NAME%
echo.

REM Mudar para o diretório do backend
cd /d "%~dp0backend"

REM Verificar se MySQL está instalado
echo [INFO] Verificando conexao com MySQL...
mysql --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo [ALERTA] MySQL CLI nao encontrado no PATH. Verifique se o MySQL esta instalado corretamente.
) else (
  echo [INFO] MySQL CLI detectado.
)

REM Configurar o banco de dados de teste
echo.
echo [INFO] Configurando banco de dados de teste...
call npm run setup:test-db
if %ERRORLEVEL% NEQ 0 (
  echo [ALERTA] Nao foi possivel configurar o banco de dados de teste automaticamente.
  echo          Voce precisara criar manualmente um banco 'magapp_test' com o usuario 'test_user'.
) else (
  echo [INFO] Banco de dados de teste configurado com sucesso.
)

REM Executar testes com banco de dados mock
echo.
echo [INFO] Executando testes de integracao com banco de dados mock...
call npm run test:mock-db
if %ERRORLEVEL% NEQ 0 (
  echo [ERRO] Falha nos testes com banco de dados mock (Codigo: %ERRORLEVEL%)
  exit /b %ERRORLEVEL%
)
echo [SUCESSO] Testes com banco de dados mock concluidos com sucesso.

REM Executar testes com banco de dados real
echo.
echo [INFO] Executando testes de integracao com banco de dados real...
call npm run test:db
if %ERRORLEVEL% NEQ 0 (
  echo [ERRO] Falha nos testes com banco de dados real (Codigo: %ERRORLEVEL%)
  exit /b %ERRORLEVEL%
)
echo [SUCESSO] Testes com banco de dados real concluidos com sucesso.

REM Mensagem final
echo.
echo ============================================================
echo      TODOS OS TESTES DE INTEGRACAO DE BD CONCLUIDOS
echo ============================================================
echo.
