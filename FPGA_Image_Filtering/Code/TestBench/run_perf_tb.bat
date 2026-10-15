@echo off
setlocal
set "MODE=%~1"
if "%MODE%"=="" set "MODE=1"
set "SCENARIO=%~2"
if "%SCENARIO%"=="" set "SCENARIO=preload"
if /I "%SCENARIO%"=="core" set "SCENARIO=preload"
if /I "%SCENARIO%"=="camera" set "SCENARIO=stream"
if /I "%SCENARIO%"=="e2e" set "SCENARIO=stream"
python "%~dp0..\..\..\tools\run_xsim.py" "%~dp0..\tests.json" --job integrated_mode%MODE%_%SCENARIO%
exit /b %ERRORLEVEL%
