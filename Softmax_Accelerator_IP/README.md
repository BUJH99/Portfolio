# 🚀 Softmax ACC IP 설계 및 SoC 구현

## 📅 프로젝트 정보
- **진행 기간**: 2025.08.01 ~ 2025.09.25
- **수상 내역**: 🏆 **차세대반도체학과 주관 경진대회 우수상**
- **기술 스택**: `Verilog HDL`, `Vivado IP Integrator`, `Zynq SoC`, `AXI Interface`, `C/C++`

---

## 📝 프로젝트 개요
Softmax 연산을 수행하는 하드웨어 가속기(IP)를 Verilog로 설계하고, Xilinx Zynq SoC 플랫폼에 AXI 인터페이스로 통합하여 소프트웨어 대비 연산 속도를 가속화한 프로젝트입니다.

## ✅ 핵심 성과
- Verilog 기반 Softmax Accelerator를 RTL로 설계하고 Zynq SoC에 AXI 인터페이스로 통합
- ARM 프로세서 기반 소프트웨어 대비 약 **13배 성능 향상** 확인
- **UVM 구조를 활용한 검증 환경**을 구축해 reset, frame boundary, backpressure, special FP32 입력까지 시나리오 기반 검증 수행
- 총 **10개 검증 시나리오 PASS**, **Merged Coverage 100.0%**, **Errors 0건**의 회귀 결과 확보

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

### 4. UVM 구조 활용 검증
- **검증 구조**: `generator`, `driver`, `monitor`, `scoreboard`, `shadow checker`, `coverage`로 구성된 UVM 스타일 Testbench 확장
- **Golden Model 연동**: Python 기반 reference model로 frame 단위 expected output 생성 및 자동 비교
- **검증 포인트**: `valid/ready/last/keep` 프로토콜, reset 복구, frame 경계 조건, `P_C_MAX` 종료 조건, `keep ignore`, `special FP32` 정책 검증
- **회귀 시나리오**: reset matrix, singleton frame, uniform frame, mixed vector, backpressure, boundary collision, random coverage 포함 총 10개 테스트 구성

---

## 🧪 UVM 검증 요약

| 항목 | 내용 |
| :--- | :--- |
| Verification Scope | `TOP` 모듈 기준 AXI-Stream 입출력, frame 기반 softmax 파이프라인, reset/backpressure 동작 |
| Verification Method | UVM 구조 기반 TB + Python Golden Model + scenario-driven regression |
| Test Scenarios | `test_01_reset_matrix` ~ `test_10_random_cov` |
| Regression Result | **10 / 10 PASS**, **Failed 0**, **Errors 0**, **RTL Error 0.0%** |
| Coverage | **Merged Coverage 100.0%** |
| Throughput Sample | 총 **13,355 beats** 기준 회귀 리포트 생성 |

### 📌 대표 검증 시나리오
- **Reset / Recovery**: idle, capture, replay, output-valid 상태에서의 async reset 복구 검증
- **Protocol / Backpressure**: input gap, downstream stall, fanout stall 상황에서 beat drop/duplication 여부 확인
- **Boundary / Re-arm**: `iLast`, `P_C_MAX`, 종료 충돌 조건과 다음 frame 재수락 무결성 검증
- **Numerical Policy**: uniform input, mixed-sign input, `Inf/NaN` 포함 special FP32 처리와 출력 합 정합성 확인

### 📄 검증 문서
- **[Verification Plan](./Code/Testbench/UVM/TOP_tb/TOP_verification_plan.md)** : 시나리오, coverage, scoreboard/shadow checker 기준 정리
- **[UVM Regression Report](./Report/UVM_REPORTl.html)** : 회귀 실행 결과 및 시나리오별 coverage/오차 분석 리포트
- **[UVM Testbench](./Code/Testbench/UVM/TOP_tb)** : UVM 구조 기반 검증 환경 소스

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
- **Verification Architecture**: UVM 스타일 구조, scenario-driven regression, golden model 연동 기반의 검증 체계 설계 경험.
- **PPA 최적화**: 성능, 전력, 면적을 고려한 RTL 설계 기법 습득.

---

## 📂 포트폴리오 목차
- **[📂 RTL Source](./Code/Source)** : Softmax Accelerator RTL 소스
- **[📂 Software](./Code/SW)** : 성능 비교 및 제어용 SW 코드
- **[📂 UVM Testbench](./Code/Testbench/UVM/TOP_tb)** : UVM 구조 기반 검증 환경
- **[📂 Verification Plan](./Code/Testbench/UVM/TOP_tb/TOP_verification_plan.md)** : 검증 시나리오 및 coverage 계획
- **[📂 UVM Report](./Report/UVM_REPORTl.html)** : 회귀 실행 결과 HTML 리포트
- **[📂 Report Assets](./Report)** : 프로젝트 산출물 및 수상 이미지
