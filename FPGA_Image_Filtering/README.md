# 🖼️ Ultra96-V2 FPGA 기반 영상 필터링 시스템

## 📅 프로젝트 정보
- **진행 기간**: 2025.10.30 ~ 2025.12.14
- **하드웨어**: `Xilinx Ultra96-V2 FPGA`
- **기술 스택**: `Verilog HDL`, `AXI Stream`, `Image Processing`, `CNN`, `MMIO`

---

## 📝 프로젝트 개요
**Ultra96-V2 FPGA**를 활용하여 카메라 입력을 받아 실시간으로 영상 필터링 및 CNN 연산을 수행하고 디스플레이로 출력하는 파이프라인 시스템을 구현했습니다.

## 🔑 주요 구현 내용
### 1. 하드웨어 가속기 설계
- **Architecture**: Line Buffer 및 Window Buffer 기반의 영상처리 아키텍처 적용.
- **Processing**: Convolution 연산 모듈 및 필터링 로직 RTL 설계.
- **Display**: TFT-LCD 제어를 위한 컨트롤러 구현.

### 2. 시스템 통합 및 SW
- **Integration**: AXI Stream 인터페이스를 사용하여 영상 데이터 흐름 제어.
- **SW Reference**: C언어로 구현한 알고리즘을 Golden Reference로 삼아 HW 검증.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 실시간 처리 병목 (Bottleneck)
- **문제**: 대용량 영상 데이터 처리 시 대역폭 부족 및 지연(Latency)으로 인한 Frame Drop.
- **해결**: 파이프라인 스테이지를 세분화하여 Throughput을 높이고, 모듈 간 핸드셰이킹(Handshaking) 최적화로 데이터 흐름 개선.

### 2. 클럭 도메인 동기화
- **문제**: 고속의 영상 픽셀 클럭과 시스템 클럭 간 차이로 인한 화면 깨짐.
- **해결**: 비동기 FIFO (Asynchronous FIFO)를 적용하여 클럭 도메인 간 데이터를 안정적으로 전달.

---

## 📚 배운점
- **영상 처리 시스템**: 입력-처리-출력으로 이어지는 실시간 비디오 파이프라인 설계 경험.
- **메모리 활용**: 라인 버퍼 등을 이용한 온칩 메모리(BRAM) 효율적 활용 기법.
- **하드웨어 가속**: 소프트웨어 처리 대비 하드웨어 병렬 처리의 성능상 이점 확인.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : RTL 및 제어 코드
- **[📂 Report](./Report)** : 결과 보고서
