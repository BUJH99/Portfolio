@echo off
setlocal
python "%~dp0..\..\..\tools\run_xsim.py" "%~dp0..\tests.json" --job module_perf
exit /b %ERRORLEVEL%
