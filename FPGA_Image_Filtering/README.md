# 🖼️ Zynq SoC 기반 실시간 영상 필터링 시스템

## 📅 프로젝트 정보
- **진행 기간**: 2025.10.30 ~ 2025.12.14
- **하드웨어**: `Zynq-7000 SoC`, `OV5640 Camera`, `4.3" TFT-LCD`
- **기술 스택**: `Verilog HDL`, `AXI Interface`, `Image Processing (CNN)`, `BRAM Controller`

---

## 📝 프로젝트 개요
**Zynq-7000 SoC**의 PS(Processing System)와 PL(Programmable Logic) 아키텍처를 기반으로, 카메로부터 입력받은 영상을 하드웨어 가속기를 통해 실시간으로 필터링(Sharpen, Edge Enhance 등)하고 LCD로 출력하는 영상 처리 시스템을 구축했습니다.

## 🔑 주요 구현 내용
### 1. 하드웨어 가속기 (PL Design)
- **Image Pipeline**: `Camera` ➡ `Input Buffer(BRAM)` ➡ `Window Generator` ➡ `Convolution` ➡ `Output Buffer` ➡ `LCD`의 데이터 흐름 설계.
- **Convolution Core**: 3x3 커널 기반의 **Sharpen**, **Edge Enhance** 필터 및 **Bypass** 모드를 지원하며, **ReLU** 활성화 함수를 내장한 연산 유닛 구현.
- **Window Generation**: 스트리밍되는 영상 데이터에서 실시간으로 3x3 픽셀 매트릭스를 추출하는 라인 버퍼(Line Buffer) 로직 설계.
- **Memory Management**: **Vivado BRAM IP**를 활용하여 480x272 해상도의 입력(RGB888) 및 출력(RGB565) 프레임 버퍼 구축.

### 2. 시스템 제어 (PS-PL Interconnect)
- **Mode Control**: **AXI GPIO**를 통해 PS 영역에서 PL의 영상 필터 모드를 실시간으로 제어.
- **Clock Domain**: 시스템 클럭(100MHz)과 카메라/디스플레이 구동을 위한 분주 클럭(12.5MHz/25MHz) 간의 동기화 설계.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 색상 데이터 변환 손실 (Color Degradation)
- **문제**: 카메라의 24비트(RGB888) 데이터를 LCD 출력을 위해 16비트(RGB565)로 변환하는 과정에서 색상 밴딩(Color Banding) 현상 발생.
- **해결**: 상위 비트를 단순히 잘라내는(Truncation) 방식 대신, 향후 **디더링(Dithering)** 또는 **오차 확산(Error Diffusion)** 알고리즘을 적용하여 화질을 개선할 수 있음을 확인하고 기술적 대안을 보고서에 제시.

### 2. 모듈 간 핸드셰이킹 타이밍 (Handshaking)
- **문제**: 윈도우 생성 모듈과 컨볼루션 연산 모듈 사이의 데이터 유효 시점이 어긋나 픽셀 밀림 현상 발생.
- **해결**: `Valid` 및 `Ready` 신호 기반의 핸드셰이킹 구조를 명확히 정의하여, 데이터가 완전히 준비된 시점에만 연산이 수행되도록 파이프라인 제어 로직 수정.

---

## 📚 배운점
- **Hardware-Software Co-design**: Zynq SoC 환경에서 PS(제어)와 PL(연산)의 역할 분담 및 인터페이스 설계 능력 배양.
- **Real-time Processing**: 메모리 대역폭과 타이밍 제약을 고려한 실시간 영상 처리 하드웨어 설계 경험.
- **Resource Optimization**: FPGA 내부의 BRAM 자원을 효율적으로 할당하여 프레임 버퍼를 구성하는 기법 습득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Code)** : RTL 설계 코드 및 테스트벤치
- **[📂 Report](./Report)** : 상세 설계 보고서 (블록 다이어그램 포함)
