# Windows 실행

개선 구현은 Windows API를 사용한다. CMake 3.24 이상, MinGW-w64 GCC 또는 MSVC, Node.js가 필요하다. CMake가 GoogleTest 1.14.0과 nlohmann/json 3.11.3을 가져온다.

`Source_Code`에서:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/codex_build.ps1 -Task test -DependencyMode FetchContent
cd electron
npm ci
npm start
```

`build_one_click.bat`, `run_one_click.bat`도 제공한다. 별도 CMake 빌드 폴더를 사용하면 `AGV_RENDER_IPC_PATH`를 생성한 `agv_render_ipc.exe`로 지정한다. `AGV.exe`와 기존 `build/Debug/outDebug.exe`는 과거 산출물로 보존되며 새 빌드의 실행 진입점은 아니다.

이번 이관에서는 CMake Release 빌드, GoogleTest 59개와 정적 경계 검사 2개를 CTest로 실행해 61/61 통과했다. Electron main/preload/renderer의 JavaScript 구문과 `npm ci` 의존성 설치를 확인했다. Electron 화면의 전체 수동 조작이나 장시간 운영 성능 측정은 이 결과에 포함되지 않는다.
