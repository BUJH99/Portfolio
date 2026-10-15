@echo off
setlocal

set "ROOT=%~dp0"
set "ELECTRON_DIR=%ROOT%electron"
set "BACKEND_EXE=%ROOT%build\agv_render_ipc.exe"

where npm.cmd >nul 2>nul
if errorlevel 1 (
    echo npm.cmd not found. Install Node.js first.
    exit /b 1
)

if not exist "%ELECTRON_DIR%\package.json" (
    echo Electron app not found: "%ELECTRON_DIR%\package.json"
    exit /b 1
)

call "%ROOT%build_one_click.bat"
if errorlevel 1 (
    echo Backend build failed.
    exit /b 1
)

if not exist "%BACKEND_EXE%" (
    echo Backend executable still missing: "%BACKEND_EXE%"
    exit /b 1
)

if not exist "%ELECTRON_DIR%\node_modules\electron" (
    echo Installing Electron dependencies...
    pushd "%ELECTRON_DIR%"
    call npm.cmd ci
    if errorlevel 1 (
        popd
        echo npm ci failed.
        exit /b 1
    )
    popd
)

pushd "%ELECTRON_DIR%"
set "AGV_RENDER_IPC_PATH=%BACKEND_EXE%"
call npm.cmd start
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
