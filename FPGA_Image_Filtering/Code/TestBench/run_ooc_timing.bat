@echo off
setlocal

if "%VIVADO_BIN%"=="" set VIVADO_BIN=C:\AMDDesignTools\2025.2\Vivado\bin

pushd "%~dp0\.."
call "%VIVADO_BIN%\vivado.bat" -mode batch -source TestBench\run_ooc_timing.tcl -nojournal -nolog
set RC=%ERRORLEVEL%
popd
exit /b %RC%
