@echo off
setlocal
python "%~dp0..\tools\run_xsim.py" "%~dp0tests.json" %*
exit /b %ERRORLEVEL%
