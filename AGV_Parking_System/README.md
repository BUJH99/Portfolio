# AGV 무인 주차장 시뮬레이터

다수의 AGV가 차량의 입고·주차·출고를 수행하는 격자 기반 시뮬레이터입니다. 경로 탐색 알고리즘을 비교하고, 교차로 충돌과 교착 상태를 처리하는 과정을 Electron 화면에서 관찰할 수 있습니다.

- **프로젝트 기간**: 2025.03 ~ 2025.12
- **수상**: 형남과학상 동상
- **기술**: C++20, CMake, GoogleTest, Electron, JavaScript

## 주요 기능

- **경로 탐색 비교**: A*, D* Lite, WHCA*·D* Lite·대기 그래프·CBS를 결합한 기본 계획기
- **다중 AGV 제어**: 최대 16대의 이동 우선순위, 충돌 회피, 교착 상태 대응, 충전 및 복귀
- **시나리오 구성**: 7개 맵, 주차·출차 순서 지정, 확률 기반 실시간 요청, 재현 가능한 난수 시드
- **시각화**: AGV 위치와 상태, 계획 경로, 충돌 정보, 처리량·이동 비용·계획 시간
- **실행 방식**: Electron GUI, 대화형 콘솔, 명령행 기반 헤드리스 실행

## 구조

Electron이 C++ 시뮬레이션 프로세스를 실행하고 표준입출력으로 JSON Lines 메시지를 주고받습니다. 콘솔과 GUI는 같은 시뮬레이션 엔진을 사용합니다.

```text
Electron 화면 → preload / main → JSON IPC → SimulationEngine
                                             ↑
                                       콘솔 / 헤드리스
```

| 경로 | 내용 |
|---|---|
| `Source_Code/src/` | 엔진, 경로 계획, 맵, 실행 진입점, 콘솔 및 IPC |
| `Source_Code/include/` | 공개 API와 내부 모델 |
| `Source_Code/electron/` | 데스크톱 UI와 프로세스 연결 |
| `Source_Code/tests/` | 엔진·시나리오·렌더 데이터·IPC 회귀 테스트 |
| `Source_Code/scripts/build.ps1` | CMake 빌드·테스트·콘솔 실행 |
| `Presentation/` · `Thesis/` | 발표 자료와 졸업논문 |

## 실행

**Windows**, **MinGW-w64 GCC(C++20 지원)**, **CMake 3.24 이상**, **Node.js와 npm**이 필요합니다. GCC와 CMake를 PATH에 등록하면 사용할 수 있으며, 빌드 스크립트는 기본 MSYS2 및 Visual Studio CMake 설치 경로도 확인합니다. 최초 빌드·실행 시 의존성을 내려받으므로 인터넷 연결이 필요합니다.

`AGV_Parking_System` 폴더에서:

```powershell
cd Source_Code
.\run_one_click.bat
```

소스를 빌드하고, Electron 의존성을 설치한 다음 GUI를 실행합니다. 실행할 때마다 변경된 C++ 소스가 빌드에 반영됩니다. 빌드만 하려면 `build_one_click.bat`를 실행합니다.

GUI에서는 맵·알고리즘·시나리오를 선택한 뒤 시뮬레이션을 시작하고, 연속 실행·일시정지·단계 실행으로 동작을 확인할 수 있습니다.

### 콘솔 실행

빌드 후 `Source_Code` 폴더에서:

```powershell
# 대화형 설정 및 실행
.\build\agv_console.exe

# 주차 2건과 출차 2건을 화면 없이 실행
.\build\agv_console.exe --headless --seed 1 --map 1 --algo default --mode custom --phase park:2 --phase exit:2 --max-steps 3000
```

알고리즘은 `default`, `astar`, `dstar` 중에서 선택합니다. 전체 명령행 옵션은 `agv_console.exe --help`로 확인할 수 있습니다.

### 테스트

`Source_Code` 폴더에서:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Task test
```

GoogleTest로 입·출차, 알고리즘, 반복 세션, 렌더 프레임과 delta, IPC 요청을 검증합니다. CTest는 엔진과 화면 코드의 의존성 경계 및 코드 규칙 검사도 함께 실행합니다.

### 빌드 경로

기본 빌드 출력은 `Source_Code/build/`입니다. 다른 CMake 빌드 폴더를 사용하는 경우에는 `AGV_RENDER_IPC_PATH`를 지정하고 Electron을 직접 실행합니다.

```powershell
$env:AGV_RENDER_IPC_PATH = 'C:\path\to\agv_render_ipc.exe'
cd electron
npm ci
npm start
```

## 프로젝트 자료

- [발표 자료](./Presentation/AGV%20Algorithm_발표자료.pdf)
- [졸업논문](./Thesis/졸업논문_한정호.pdf)
- [원본 개발 저장소](https://github.com/BUJH99/AGV_REFACTORING)
