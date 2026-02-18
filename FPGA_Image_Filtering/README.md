# 🖼️ Zynq SoC 기반 실시간 영상 필터링 시스템

## 📅 프로젝트 정보
- **진행 기간**: 2025.10.30 ~ 2025.12.14
- **하드웨어**: `Zynq-7000 SoC`, `OV5640 Camera`, `4.3" TFT-LCD`
- **기술 스택**: `Verilog HDL`, `AXI Interface`, `Image Processing (CNN)`, `BRAM Controller`

---

## 📝 프로젝트 개요
**Zynq-7000 SoC**의 PS(Processing System)와 PL(Programmable Logic) 아키텍처를 기반으로, 카메로부터 입력받은 영상을 하드웨어 가속기를 통해 실시간으로 필터링(Sharpen, Edge Enhance 등)하고 LCD로 출력하는 영상 처리 시스템을 구축했습니다.

## 🔑 주요 구현 내용 (Source Code Analysis)
### 1. 하드웨어 가속기 (PL Design)
- **Top Module (`CNN_Top.v`)**: 시스템 클럭(100MHz)과 카메라 픽셀 클럭(PCLK), LCD 구동 클럭 간의 도메인을 분리하고 **Dual Port BRAM**을 이용해 영상 데이터를 버퍼링.
- **Convolution Core (`Conv3x3_ReLU_param.v`)**:
    - **Multi-Kernel**: `Sharpen`, `Edge Enhance`, `Emboss`, `Bypass` 4가지 필터 커널을 파라미터로 내장.
    - **Datapath**: 9개의 픽셀 입력 ➡ 가중치 곱셈(Multiplier) ➡ 누적합(Adder Tree) ➡ **ReLU & Saturation** (0~255) 로직 구현.
    - **Handshaking**: `i_valid`/`i_ready` 프로토콜을 구현하여 데이터 백프레셔(Backpressure)를 제어하는 **Zero-latency Forwarding** 구조 적용.
- **Window Generator (`window3x3_case9.v`)**:
    - **FSM Control**: `S_PLAN`(주소 계산) ➡ `S_EXEC`(BRAM 데이터 페치) ➡ `S_EMIT`(윈도우 출력)의 3단계 상태머신으로 동작.
    - **Boundary Check**: 이미지의 가장자리(Corner/Edge) 픽셀 처리 시 **Padding** 또는 **Mirroring** 로직 수행.

### 2. 메모리 및 제어 인터페이스
- **Frame Buffer**: `InputMemory_RGB888`(Write: PCLK / Read: SysClk)와 `OutputMemory_RGB565`를 사용하여 비동기 클럭 도메인 간 데이터 안정성 확보.
- **Pixel Conversion**: 24-bit RGB 데이터를 16-bit RGB565 포맷으로 실시간 변환하여 메모리 대역폭 절감.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. FSM 기반 윈도우 생성 지연
- **문제**: `window3x3_case9.v` 모듈이 주변 픽셀을 BRAM에서 순차적으로 읽어오는(`S_EXEC`) 동안 파이프라인 스톨(Stall) 발생.
- **해결**: BRAM Read Latency를 고려하여 파이프라인 레지스터를 추가하고, 데이터가 준비완료된 시점에만 `o_valid`를 출력하도록 동기화 로직 개선.

### 2. 색상 데이터 변환 손실 (Color Degradation)
- **문제**: 카메라의 RGB888 데이터를 RGB565로 변환(`rgb565_to_rgb888.v` 역변환 과정 등)할 때 하위 비트 절삭으로 인한 화질 저하.
- **해결**: 단순 Truncation 방식 적용 (향후 Dithering 로직 추가 예정으로 보고서에 기술).

### 3. 클럭 도메인 교차 (CDC)
- **문제**: Camera PCLK(비동기)와 System Clock 간의 타이밍 위반.
- **해결**: **Dual Port BRAM**을 비동기 FIFO처럼 활용하여, Write 포트는 PCLK 도메인에서, Read 포트는 System Clock 도메인에서 동작하도록 설계하여 CDC 문제 해결.

---

## 📚 배운점
- **Hardware-Software Co-design**: Zynq SoC 환경에서 PS(제어)와 PL(연산)의 역할 분담 및 인터페이스 설계 능력 배양.
- **Real-time Processing**: 메모리 대역폭과 타이밍 제약을 고려한 실시간 영상 처리 하드웨어 설계 경험.
- **Resource Optimization**: FPGA 내부의 BRAM 자원을 효율적으로 할당하여 프레임 버퍼를 구성하는 기법 습득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Code)** : RTL 설계 코드 및 테스트벤치
- **[📂 Report](./Report)** : 상세 설계 보고서 (블록 다이어그램 포함)
