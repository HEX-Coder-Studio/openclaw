@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "PROJECT_DIR=%BASE_DIR%\.."
set "DEPLOY_MENU=%PROJECT_DIR%\deploy_menu.bat"

if not exist "%DEPLOY_MENU%" (
  echo [ERROR] deploy_menu.bat not found: %DEPLOY_MENU%
  exit /b 1
)

echo [INFO] Running restart only...
cd /d "%PROJECT_DIR%" || (
  echo [ERROR] Cannot enter project directory: %PROJECT_DIR%
  exit /b 1
)
call "%DEPLOY_MENU%" restart
if errorlevel 1 (
  echo [ERROR] Restart failed.
  exit /b 1
)

echo [OK] Restart completed.
exit /b 0
