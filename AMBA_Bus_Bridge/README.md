# 🌉 AMBA AHB-APB Bridge 설계

## 📅 프로젝트 정보
- **진행 기간**: 2025.06.24 ~ 2025.07.14
- **프로젝트 유형**: 🎓 **학부생 연구 인턴 과제 (Undergraduate Research Intern)**
- **기술 스택**: `Verilog HDL`, `AMBA Protocol`, `FSM Design`, `ModelSim`

---

## 📝 프로젝트 개요
SoC 내부 버스 표준인 **AMBA 프로토콜**을 분석하고, 고속 **AHB** 버스와 저속 **APB** 버스 간의 통신을 중개하는 **Bridge IP**를 Verilog로 설계했습니다.

## 🔑 주요 구현 내용
### 1. FSM 기반 Bridge 설계
- **FSM 구현**: `IDLE` ➡ `SETUP` ➡ `ENABLE` 3단계 상태 머신을 통해 프로토콜 변환 제어.
- **신호 제어**: AHB 마스터 요청을 받아 APB 슬레이브 프로토콜(`PSEL`, `PENABLE`)에 맞춰 신호 생성.

### 2. 동기화 및 인터페이스
- **Wait State**: 속도가 느린 APB의 응답을 기다리기 위해 AHB `HREADY` 신호를 제어하여 동기화.
- **Address Decoding**: `0x8000` 등 특정 주소 영역을 감지하여 해당 슬레이브를 선택하는 로직 구현. (SRAM Interface)

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 타이밍 불일치 해결
- **문제**: 파이프라인으로 동작하는 AHB와 2-Cycle이 필요한 APB 간의 속도 차이로 인한 데이터 손실 위험.
- **해결**: FSM의 `SETUP` 상태에서 `HREADYout=0`을 출력하여 AHB 마스터를 대기(Stall)시키는 방식으로 타이밍 동기화.

### 2. 신호 무결성 확보
- **문제**: AHB 주소 신호가 다음 클럭에 바로 변동되어 APB 전송 중 주소가 유효하지 않게 됨.
- **해결**: AHB 주소 페이즈 시점에 주소와 제어 신호를 내부 레지스터에 래치(Latch)하여 APB 전송 구간 동안 신호를 유지.

---

## 📚 배운점
- **프로토콜 이해**: AMBA AHB/APB 사양을 상세 분석하고 타이밍 다이어그램을 코드로 구현하는 능력.
- **CDC 설계**: 서로 다른 속도를 가진 도메인 간의 인터페이스 설계 및 핸드셰이킹 기법 습득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : RTL 소스 및 테스트벤치
- **[📂 Report](./Report)** : 설계 및 검증 보고서
