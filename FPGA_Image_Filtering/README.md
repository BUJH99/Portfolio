# 🖼️ Ultra 96-V2 FPGA 활용 영상 필터링 시스템 (FPGA Image Processing)

> **"하드웨어로 보는 세상: FPGA 기반 CNN 가속 및 영상 신호 처리 시스템"**

## 📅 프로젝트 정보
- **진행 기간**: 2025.10.30 ~ 2025.12.14
- **하드웨어**: `Xilinx Ultra96-V2`
- **기술 스택**: `Verilog HDL`, `CNN Algorithm`, `Image Filtering`, `AXI Stream`, `Memory Mapped I/O`

---

## 📝 프로젝트 개요
교내 프로젝트 과목을 통해 **Ultra96-V2 FPGA** 보드 상에서 카메라 영상 입력을 받아 실시간으로 필터링(CNN 기반 연산 등)을 수행하고 디스플레이로 출력하는 전체 파이프라인 시스템을 구현했습니다.

## 🔑 주요 기능 및 담당 역할
### 1. Golden Reference Model (SW)
- C언어를 사용하여 CNN 알고리즘을 구현하고, Multi-thread를 적용하여 SW 레벨에서의 최적화 한계점 파악.
- 이를 HW 설계의 기준(Golden Reference)으로 활용.

### 2. Hardware Implementation (SoC)
- **담당 역할**: 전체 SoC 아키텍처 통합, Convolution 연산 모듈 설계, TFT-LCD 컨트롤러 설계, MMIO(Memory Mapped I/O) 기반 제어 로직 구현.
- **데이터 로직**: 윈도우 버퍼(Window Buffer) 및 라인 버퍼(Line Buffer) 아키텍처를 적용하여 픽셀 스트리밍 처리.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 실시간 데이터 병목 (Bottleneck)
- **어려움**: 대용량 영상 데이터를 메모리에서 읽고 쓸 때 버스 대역폭 부족으로 인한 Frame Drop 및 딜레이 발생. 라인 버퍼 제어 로직의 복잡성.
- **해결**: 모듈별 데이터 패스 및 레이턴시를 분석하여 병목 지점을 특정. **핸드셰이킹(Handshaking) 프로토콜**을 정교하게 설계하여 모듈 간 동기화를 맞추고, 파이프라인을 깊게 구성하여 처리량(Throughput) 증대.

### 2. 신호 동기화 및 타이밍
- **어려움**: 고속 영상 클럭과 시스템 클럭 간의 도메인 차이로 인한 화면 깨짐 현상.
- **해결**: FIFO를 활용한 비동기 클럭 도메인 처리 및 타이밍 컨스트레인트(Constraints) 설정을 통한 안정화.

---

## 📚 배운점 및 성과
- **영상 처리 파이프라인 구축**: 입력(Cam) ➡ 처리(Filter/CNN) ➡ 출력(LCD)으로 이어지는 리얼타임 비디오 시스템 설계 경험.
- **메모리 계층 구조 활용**: 영상 처리에 필수적인 라인 버퍼 및 윈도우 버퍼링 기법을 통해 온칩 메모리(BRAM) 활용 능력 극대화.
- **하드웨어 가속의 위력 확인**: SW로는 달성하기 힘든 실시간 영상 처리를 FPGA의 병렬성으로 해결하며 하드웨어 설계의 효용성 체감.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : RTL 설계 및 제어 소프트웨어 소스
- **[📂 Report](./Report)** : 프로젝트 완료 보고서
