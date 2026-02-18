# 🚀 Softmax ACC IP 설계 및 SoC 구현 (Softmax Accelerator SoC)



## 📅 프로젝트 정보
- **수상 내역**: 🏆 **차세대반도체학과 주관 경진대회 우수상**
- **진행 기간**: 2025.08.01 ~ 2025.09.25
- **기술 스택**: `Verilog HDL`, `Vivado IP Integrator`, `Zynq SoC`, `AXI Interface`, `C/C++`

---

## 📝 프로젝트 개요
딥러닝 연산의 핵심 함수 중 하나인 **Softmax** 연산을 하드웨어 가속기(IP)로 설계하고, 이를 Zynq SoC 플랫폼에 통합하여 소프트웨어 대비 비약적인 성능 향상을 입증한 프로젝트입니다.

## 🔑 주요 기능 및 담당 역할
### 1. RTL Design & Verification
- 지수 연산(Exponential) 및 나눗셈 연산을 위한 최적화된 하드웨어 로직 설계.
- **담당 역할**: 핵심 연산 모듈 RTL 코딩 및 Testbench 검증.

### 2. SoC Integration
- **IP Packaging**: 설계한 모듈을 AXI4-Lite 및 AXI4-Stream 인터페이스를 지원하는 IP로 패키징.
- **Block Design**: Vivado IP Integrator를 사용하여 Processor(PS)와 Accelerator(PL)를 연결하고 전체 시스템 구성.

### 3. 성능 벤치마킹
- ARM 프로세서에서 실행되는 C언어 기반 Softmax 코드와 HW 가속기의 실행 시간을 측정 후 비교.
- **결과**: 최대 **13배**의 처리 속도 향상 달성.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. CDC (Clock Domain Crossing) 및 타이밍 위반
- **어려움**: PS영역(Processing System)과 PL영역(Programmable Logic)의 동작 주파수 차이로 인한 비동기 신호 처리 문제 및 Setup/Hold Time Violation 발생.
- **해결**: 2-FlipFlop Synchronizer와 같은 CDC 기법을 적용하고, 병목이 되는 긴 경로(Critical Path)에 파이프라인 레지스터를 추가(Retiming)하여 타이밍 문제 해결.

### 2. SoC 시스템 이해도 부족
- **어려움**: IP가 개별적으로는 동작하지만, 시스템 버스(AXI)에 연결되었을 때 데이터가 정체되거나 오동작하는 현상.
- **해결**: AXI 프로토콜의 Handshake 타이밍을 정밀 분석하고, ILA(Integrated Logic Analyzer)를 삽입하여 FPGA 내부 신호를 실시간으로 디버깅.

### 3. 검증 환경의 복잡성
- **어려움**: 하드웨어 가속기의 결과값이 정답(Golden Model)과 미세하게 다른 문제 (부동소수점 vs 고정소수점 이슈).
- **해결**: C언어로 비트 단위까지 일치하는 검증 모델을 만들고, 데이터 포맷(Fixed-point) 정밀도를 조정.

---

## 📚 배운점 및 성과
- **PPA 최적화**: 성능(Performance), 전력(Power), 면적(Area)을 고려한 코딩 스타일 연구 및 적용.
- **HW/SW Co-design**: 하드웨어와 소프트웨어가 상호작용하는 임베디드 시스템의 전체적인 숲을 보는 시야 확보.
- **IP 재사용성**: 잘 설계된 IP가 시스템에서 어떻게 재사용되고 통합되는지에 대한 실무적 프로세스 경험.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : Verilog RTL 및 Vitis C 소스
- **[📂 Report](./Report)** : 상세 결과 보고서
- **[📂 Presentation](./Presentation)** : 경진대회 발표 자료
