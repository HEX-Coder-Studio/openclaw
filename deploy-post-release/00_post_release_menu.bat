@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "PROJECT_DIR=%BASE_DIR%\.."
set "DEPLOY_DIR=D:\OpenClaw\deploy"
set "LOG_FILE=%DEPLOY_DIR%\gateway.log"
set "PORT=18789"
set "VERIFY_SCRIPT=%BASE_DIR%\verify_post_release.ps1"

rem Numeric argument mode
if "%~1"=="1" goto do_publish_once
if "%~1"=="2" goto do_restart_once
if "%~1"=="3" goto do_release_verify_once
if "%~1"=="4" goto do_verify_once
if "%~1"=="5" goto do_logs_once
if "%~1"=="0" goto done

rem Keyword argument mode
if /I "%~1"=="publish" goto do_publish_once
if /I "%~1"=="restart" goto do_restart_once
if /I "%~1"=="release-verify" goto do_release_verify_once
if /I "%~1"=="verify" goto do_verify_once
if /I "%~1"=="logs" goto do_logs_once
if /I "%~1"=="docs" goto do_docs_once

:menu
cls
echo ==============================================================
echo   OpenClaw Post-Release Toolkit
echo   Dir: %BASE_DIR%
echo ==============================================================
echo [1] Publish only
echo [2] Restart only
echo [3] Publish + Restart + Verify (recommended)
echo [4] Verify only
echo [5] Show gateway log tail
echo [D] Open post-release docs
echo [0] Exit
set "CHOICE="
set /p "CHOICE=Select [0-5, D]: " || goto done
if not defined CHOICE goto done

if "%CHOICE%"=="1" goto run_publish
if "%CHOICE%"=="2" goto run_restart
if "%CHOICE%"=="3" goto run_release_verify
if "%CHOICE%"=="4" goto run_verify
if "%CHOICE%"=="5" goto show_logs
if /I "%CHOICE%"=="D" goto open_docs
if "%CHOICE%"=="0" goto done

echo [WARN] Invalid input. Please enter 0-5 or D.
pause
goto menu

:run_publish
if not exist "%BASE_DIR%\01_publish_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\01_publish_only.bat
  pause
  goto menu
)
call "%BASE_DIR%\01_publish_only.bat"
call :pause_result
goto menu

:do_publish_once
if not exist "%BASE_DIR%\01_publish_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\01_publish_only.bat
  exit /b 1
)
call "%BASE_DIR%\01_publish_only.bat"
if errorlevel 1 exit /b 1
exit /b 0

:run_restart
if not exist "%BASE_DIR%\02_restart_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\02_restart_only.bat
  pause
  goto menu
)
call "%BASE_DIR%\02_restart_only.bat"
call :pause_result
goto menu

:do_restart_once
if not exist "%BASE_DIR%\02_restart_only.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\02_restart_only.bat
  exit /b 1
)
call "%BASE_DIR%\02_restart_only.bat"
if errorlevel 1 exit /b 1
exit /b 0

:run_release_verify
if not exist "%BASE_DIR%\03_publish_restart_verify.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\03_publish_restart_verify.bat
  pause
  goto menu
)
call "%BASE_DIR%\03_publish_restart_verify.bat"
call :pause_result
goto menu

:do_release_verify_once
if not exist "%BASE_DIR%\03_publish_restart_verify.bat" (
  echo [ERROR] Missing script: %BASE_DIR%\03_publish_restart_verify.bat
  exit /b 1
)
call "%BASE_DIR%\03_publish_restart_verify.bat"
if errorlevel 1 exit /b 1
exit /b 0

:run_verify
if not exist "%VERIFY_SCRIPT%" (
  echo [ERROR] Missing script: %VERIFY_SCRIPT%
  pause
  goto menu
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFY_SCRIPT%" -ProjectDir "%PROJECT_DIR%" -DeployDir "%DEPLOY_DIR%" -Port %PORT%
call :pause_result
goto menu

:do_verify_once
if not exist "%VERIFY_SCRIPT%" (
  echo [ERROR] Missing script: %VERIFY_SCRIPT%
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFY_SCRIPT%" -ProjectDir "%PROJECT_DIR%" -DeployDir "%DEPLOY_DIR%" -Port %PORT%
if errorlevel 1 exit /b 1
exit /b 0

:show_logs
if not exist "%LOG_FILE%" (
  echo [WARN] Log file not found: %LOG_FILE%
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Path '%LOG_FILE%' -Tail 80"
)
pause
goto menu

:do_logs_once
if not exist "%LOG_FILE%" (
  echo [WARN] Log file not found: %LOG_FILE%
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Path '%LOG_FILE%' -Tail 80"
if errorlevel 1 exit /b 1
exit /b 0

:open_docs
if exist "%BASE_DIR%\DEPLOYMENT_POST_RELEASE.md" (
  start "" "%BASE_DIR%\DEPLOYMENT_POST_RELEASE.md"
) else (
  echo [WARN] Document not found: %BASE_DIR%\DEPLOYMENT_POST_RELEASE.md
  pause
)
goto menu

:do_docs_once
if not exist "%BASE_DIR%\DEPLOYMENT_POST_RELEASE.md" (
  echo [ERROR] Document not found: %BASE_DIR%\DEPLOYMENT_POST_RELEASE.md
  exit /b 1
)
start "" "%BASE_DIR%\DEPLOYMENT_POST_RELEASE.md"
if errorlevel 1 exit /b 1
exit /b 0

:pause_result
if errorlevel 1 (
  echo.
  echo [RESULT] Failed.
) else (
  echo.
  echo [RESULT] Success.
)
pause
exit /b 0

:done
echo Exit post-release toolkit.
endlocal
exit /b 0
