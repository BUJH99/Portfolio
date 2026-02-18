# 🧮 FPGA 기반 8-Point FFT 계산기

## 📅 프로젝트 정보
- **진행 기간**: 2024.11.20 ~ 2024.12.10 (3학년 2학기)
- **하드웨어**: `JFK-200A Kit` (Xilinx Artix-7 Logic Compatible), `4x4 Keypad`, `8-Digit 7-Segment`
- **기술 스택**: `Verilog HDL`, `Vivado 2024.1`, `Fixed-Point Arithmetic`

---

## 📝 프로젝트 개요
사용자가 키패드를 통해 입력한 **8개의 실수(Real) 샘플**에 대해 **고속 푸리에 변환(FFT)** 을 수행하고, 그 결과(복소수)를 7세그먼트 디스플레이에 출력하는 하드웨어 계산기입니다.

## 🔑 주요 구현 내용 (Source Code Analysis)
### 1. FFT 코어 설계 (`fft8_core.v`)
- **Algorithm**: **8-Point Radix-2 DIF** (Decimation-In-Frequency) 알고리즘 적용.
- **Optimization**: 복잡한 실수 곱셈기(Multiplier) 사용을 배제하고, 회전 인자(Twiddle Factor, $W_8^1 = 1/\sqrt{2}$)를 **Shift-Add 방식**($181/256 \approx 0.707$)으로 근사하여 하드웨어 자원 최적화.
- **Datapath**: 소수점 3자리 정밀도를 위해 입력값에 $\times 1000$ 스케일링을 적용한 **21-bit 고정 소수점(Fixed-Point)** 연산 체계 구축.

### 2. UI 및 제어기 (`fft_ui_ctrl.v`)
- **Calculator Interface**: 숫자(0~9), 소수점(.), 부호(-), Backspace, Enter 기능을 갖춘 FSM 기반 입력기 구현.
- **State Machine**: `MODE_INPUT` (데이터 입력) ➡ `MODE_WAIT_FFT` (연산 대기) ➡ `MODE_OUTPUT` (결과 표시)의 3단계 상태 제어.
- **Display**: 실수부(Real)와 허수부(Imaginary)를 토글 버튼으로 전환하며 확인 가능.

### 3. 상위 모듈 통합 (`fft8_keypad_top.v`)
- **Integration**: Key Scanning 모듈, UI 컨트롤러, FFT 가속 코어, 7-Segment 디코더를 최상위 모듈에서 통합 및 클럭/리셋 동기화.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 하드웨어 자원 최적화
- **문제**: 소수점 연산을 위한 부동 소수점(Floating Point) 유닛 사용 시 FPGA 자원 소모 과다 및 타이밍 문제 발생.
- **해결**: 모든 실수를 정수($\times 1000$)로 변환하여 처리하는 **고정 소수점 연산**을 도입하고, $1/\sqrt{2}$ 곱셈을 비트 시프트(Shift)와 덧셈(Add) 조합으로 대체하여 DSP 사용량 최소화.

### 2. 디스플레이 깜빡임 및 잔상
- **문제**: 8자리 7세그먼트의 Dynamic Multiplexing 주기가 맞지 않아 글자가 겹쳐 보이거나 흐려지는 현상.
- **해결**: `clk_pls.v`를 통해 1ms 단위의 안정적인 스캔 클럭을 생성하고, 각 자리수(Digit) 간의 데드 타임을 미세 조정하여 선명한 출력 확보.

---

## 📚 배운점
- **Algorithm to RTL**: 수학적 알고리즘(FFT Butterfly)을 하드웨어 논리 회로로 변환하는 설계 방법론 습득.
- **Data Precision**: 고정 소수점 연산에서의 정밀도(Precision)와 오버플로우(Overflow) 관리의 중요성 체득.
- **System Integration**: 입력 장치(키패드)부터 연산 코어, 출력 장치(디스플레이)까지 전체 임베디드 시스템의 데이터 흐름 제어 경험.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Code)** : FFT Core 및 제어 RTL 소스
- **[📂 Report](./Report)** : 최종 설계 보고서
