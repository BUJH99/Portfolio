# 🌡️ FPGA Sensor Hub

## 📝 프로젝트 개요

시계·스톱워치·초음파 거리 측정·온습도 측정을 하나의 FPGA에서 제어하는 센서 허브입니다. 버튼·스위치와 PC의 UART 명령을 공통 제어 신호로 변환하고, 동작 상태와 측정값을 4자리 FND 및 UART ASCII 문자열로 출력합니다.

- **대상 보드**: Ultra96-V2 · Zynq UltraScale+ ZU3EG
- **구성**: HC-SR04, DHT11, 버튼·스위치, 4자리 FND, UART RX/TX
- **기술**: `Verilog` · `FSM` · `UART / FIFO` · `BCD` · `Vivado / XSim`
- **기본 설정**: 시스템 클럭 100 MHz, UART 9,600 bps, 16배 oversampling, FIFO 깊이 16

## 👤 본인 역할

- **RTL 구조 설계·TOP 통합**: 기능별 모듈 분할과 입력·제어·표시·통신 경로 연결
- **입력·기능 제어**: 버튼·스위치 동기화, 디바운싱, 에지 검출, UART 명령 병합, 시계·스톱워치 FSM과 카운터 구성
- **센서 인터페이스 설계**: HC-SR04 trigger·echo 계측과 timeout 처리, DHT11 40-bit 수신·checksum 검증 FSM 구현
- **출력 경로 통합**: 센서 값의 BCD 변환, FND 스캔·점멸·소수점 제어, UART FIFO·ASCII 송수신 경로 구성

## ✅ 주요 구현

| 모드 | 기능 | 주요 코어 |
|---|---|---|
| `0` · Watch | 시간 계수, 표시 형식 전환, 자리별 값 편집 | `WatchCore` |
| `1` · Stopwatch | 시간 계수·정지, 표시 전환, 편집·초기화 | `StopwatchCore` |
| `2` · HC-SR04 | 10 μs trigger, echo 폭 기반 거리 변환, 자동·수동 측정 | `Hcsr04Core` |
| `3` · DHT11 | 단일 데이터선으로 온습도 40-bit 수신, checksum 검증, 자동·수동 측정 | `Dht11Core` |

**센서 응답 처리**는 클럭 기반 FSM으로 구성했습니다. HC-SR04는 응답 대기와 echo 계측에 timeout을 두고, DHT11은 LOW 구동·High-Z 해제로 통신 방향을 제어하며 checksum이 일치하는 데이터로 출력값을 갱신합니다.

**입력과 표시 경로**는 여러 기능이 공유합니다. 보드 입력과 UART 명령을 `mode`·`cmdCode`로 통합하고, `DisplayMux`가 모드별 BCD 데이터와 점멸·소수점 마스크를 선택해 공통 FND 컨트롤러에 전달합니다. 센서 자동 측정 주기의 기본값은 HC-SR04 **100 ms**, DHT11 **2 s**입니다.

## 🧩 모듈 구성

| 경로 | 구성 |
|---|---|
| 공통 클럭·입력 | `GlobalTickGen` → `INPUTFPGA` → `InputControl` |
| UART 명령 입력 | `uart_interface` → `ascii_decoder` → `InputControl` |
| 기능 실행 | `ControlUnit` → `WatchCore` · `StopwatchCore` · `Hcsr04Core` · `Dht11Core` |
| FND 출력 | `DisplayMux` → `SensorBcdConverter` · `DisplayModeSelector` → `FndController` |
| UART 문자열 출력 | `AsciiSender` → `tx_fifo` · `tx_arbiter` · `uart_tx` |

RTL은 43개 모듈로 구성되며, 최상위 모듈은 [`TOP`](./src/TOP.v)입니다. [`src/filelist.f`](./src/filelist.f)는 프로젝트 폴더를 기준으로 전체 RTL 경로를 담고 있습니다.

## 🎛️ UART 제어

영문 명령은 대문자와 소문자를 모두 지원합니다.

| 명령 | 동작 |
|---|---|
| `C` | 전체 초기화 |
| `R` | 모드 잠금 해제 상태에서 다음 모드 선택 |
| `L` | 현재 모드 초기화 |
| `1` · `2` · `3` | 표시 형식 전환 · 편집 모드 전환 · 모드 잠금 전환 |
| `U` · `D` | 시계·스톱워치 값 증감, 센서 모드에서 `D`로 수동 측정 |
| `S` · `Q` | FND 표시값 · 시스템 상태 요청 |
| `T` · `Y` | 스톱워치 · 시계 데이터 요청 |
| `H` · `J` | 초음파 거리 · 온습도 측정 요청 |

## 🧪 시뮬레이션 검증

[`TbTop.sv`](./tb/TbTop.sv)는 1 MHz 테스트 클럭으로 센서의 μs 단위 신호를 생성하고, 출력값과 타이밍을 검사합니다.

| 대상 | 검사 내용 |
|---|---|
| TOP | Reset 이후 FND·센서 trigger·UART idle 출력 |
| BCD 변환 | `0~9999`의 **10,000개 입력**을 정수 연산으로 구한 참조값과 비교 |
| HC-SR04 | **10 μs trigger**, 120 μs echo의 **2 cm 변환**, 무응답 timeout 결과 |
| DHT11 | 정상 40-bit 온습도 프레임 수신, 잘못된 checksum 프레임 거부 |
| UART | `0x55`, `0xA6` 두 바이트 연속 수신 |

## ▶️ 실행 방법

**Windows · Python 3 · Vivado XSim** 환경에서 `FPGA_Sensor_Hub` 폴더를 기준으로 실행합니다.

```powershell
$env:VIVADO_BIN = "C:\AMDDesignTools\2025.2\Vivado\bin"
python ..\tools\run_xsim.py .\tests.json
```

[`tests.json`](./tests.json)과 저장소 공통 실행기 [`tools/run_xsim.py`](../tools/run_xsim.py)가 RTL과 테스트벤치를 컴파일하고 `sensor_smoke` 테스트를 실행합니다. 결과는 `results/`, 임시 빌드는 `.sim_build/`에 생성됩니다.

## 📂 코드와 검증

- **[💻 RTL 소스](./src)** · **[🧩 최상위 모듈](./src/TOP.v)**
- **[🧪 테스트벤치](./tb/TbTop.sv)** · **[⚙️ 테스트 구성](./tests.json)**
- **[📋 RTL 파일 목록](./src/filelist.f)** · **[🎛️ UART 명령 디코더](./src/ascii_decoder.v)**
