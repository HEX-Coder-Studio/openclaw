@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "PROJECT_DIR=%BASE_DIR%\.."
set "DEPLOY_DIR=D:\OpenClaw\deploy"
set "PORT=18789"
set "VERIFY_SCRIPT=%BASE_DIR%\verify_post_release.ps1"

if not exist "%BASE_DIR%\01_publish_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\01_publish_only.bat
  exit /b 1
)
if not exist "%BASE_DIR%\02_restart_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\02_restart_only.bat
  exit /b 1
)
if not exist "%VERIFY_SCRIPT%" (
  echo [ERROR] Missing script: %VERIFY_SCRIPT%
  exit /b 1
)

echo [STEP] Publish
call "%BASE_DIR%\01_publish_only.bat"
if errorlevel 1 (
  echo [ERROR] Publish failed.
  exit /b 1
)

echo [STEP] Restart
call "%BASE_DIR%\02_restart_only.bat"
if errorlevel 1 (
  echo [ERROR] Restart failed.
  exit /b 1
)

echo [STEP] Verify post-release runtime
powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFY_SCRIPT%" -ProjectDir "%PROJECT_DIR%" -DeployDir "%DEPLOY_DIR%" -Port %PORT%
if errorlevel 1 (
  echo [ERROR] Verification failed.
  exit /b 1
)

echo [OK] Publish + Restart + Verification passed.
exit /b 0
