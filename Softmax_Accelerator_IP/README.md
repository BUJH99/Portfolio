# 🚀 Softmax ACC IP 설계 및 SoC 구현

## 📅 프로젝트 정보
- **진행 기간**: 2025.08.01 ~ 2025.09.25
- **수상 내역**: 🏆 **차세대반도체학과 주관 경진대회 우수상**
- **기술 스택**: `Verilog HDL`, `Vivado IP Integrator`, `Zynq SoC`, `AXI Interface`, `C/C++`

---

## 📝 프로젝트 개요
Softmax 연산을 수행하는 하드웨어 가속기(IP)를 Verilog로 설계하고, Xilinx Zynq SoC 플랫폼에 AXI 인터페이스로 통합하여 소프트웨어 대비 연산 속도를 가속화한 프로젝트입니다.

## 🔑 주요 구현 내용
### 1. RTL 설계 (Accelerator Design)
- **연산 유닛**: 지수(Exponential) 및 나눗셈(Division) 연산을 위한 하드웨어 로직 구현.
- **최적화**: 파이프라인 기법을 적용하여 Throughput 향상.
- **검증**: 시뮬레이션을 통한 로직 기능 검증.

### 2. SoC 시스템 통합
- **IP 패키징**: AXI4-Lite 및 AXI4-Stream 인터페이스를 탑재하여 커스템 IP 생성.
- **Block Design**: Vivado IP Integrator를 통해 PS(Processing System)와 PL(Programmable Logic) 연결.

### 3. 성능 벤치마킹
- ARM 프로세서(SW)와 가속기(HW)의 실행 시간 비교 측정.
- **결과**: 소프트웨어 대비 약 **13배**의 성능 향상 달성.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. CDC (Clock Domain Crossing) 이슈
- **문제**: PS와 PL 영역의 동작 주파수 차이로 인한 타이밍 위반 및 데이터 불안정.
- **해결**: 신호 경로에 2-FF Synchronizer를 적용하고, Critical Path에 파이프라인 레지스터를 추가(Retiming)하여 Timing Violation 해결.

### 2. AXI 인터페이스 연동
- **문제**: AXI 버스 연결 시 데이터 전송이 지연되거나 누락되는 현상 발생.
- **해결**: AXI 프로토콜의 Handshake 타이밍을 ILA(Integrated Logic Analyzer)로 분석하여 신호 제어 로직 수정.

### 3. 정밀도 차이 보정
- **문제**: 하드웨어 가속기(고정소수점)와 소프트웨어(부동소수점) 간 결과값 오차 발생.
- **해결**: 고정소수점(Fixed-point) 포맷의 정밀도를 조정하고 비트 단위 검증 모델(C언어)을 활용하여 오차 최소화.

---

## 📚 배운점
- **SoC 설계 흐름**: IP 설계부터 시스템 통합, 펌웨어 구동까지의 전체 SoC 개발 프로세스 경험.
- **HW/SW Co-design**: 하드웨어와 소프트웨어의 역할 분담 및 상호작용 이해.
- **PPA 최적화**: 성능, 전력, 면적을 고려한 RTL 설계 기법 습득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : Verilog RTL 및 Vitis C 소스
- **[📂 Report](./Report)** : 상세 결과 보고서
- **[📂 Presentation](./Presentation)** : 경진대회 발표 자료
