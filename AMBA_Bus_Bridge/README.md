# 🌉 AMBA Protocol 기반 AHB-APB Bridge 설계

> **"SoC 버스 통신의 핵심: 고속 AHB와 저속 APB를 잇는 다리 놓기"**

## 📅 프로젝트 정보
- **진행 기간**: 2025.06.24 ~ 2025.07.14
- **기술 스택**: `Verilog HDL`, `AMBA AHB/APB Protocol`, `ModelSim`, `FSM Design`

---

## 📝 프로젝트 개요
ARM사의 표준 버스 프로토콜인 **AMBA(Advanced Microcontroller Bus Architecture)** 규격을 분석하고, 고속 버스인 **AHB**와 저전력 주변장치 버스인 **APB** 사이의 데이터 전송을 중개하는 **Bridge IP**를 설계했습니다.

## 🔑 주요 기능 및 내용
### 1. 프로토콜 분석 및 FSM 설계
- **AHB Slave Interface**: AHB 마스터의 요청(HSEL, HTRANS, HWRITE 등)을 받아들이는 슬레이브 로직 구현.
- **APB Master Interface**: APB 슬레이브들에게 통신 규격(PSEL, PENABLE, PWRITE 등)에 맞춰 신호를 생성하는 마스터 로직 구현.
- **Synchronization**: 서로 다른 동작 속도와 타이밍을 맞추기 위해 **1-Wait State FSM**을 설계하여 안정적인 데이터 핸드셰이킹 보장.

### 2. 검증 환경 구축
- 다양한 읽기/쓰기 시나리오(Burst, Single transfer)를 생성하는 테스트벤치 작성 및 파형 검증.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 타이밍 동기화 (Timing Synchronization)
- **어려움**: AHB의 파이프라인 동작(Address Phase, Data Phase)과 APB의 2-cycle 동작(Setup, Access) 간의 타이밍 불일치로 인한 데이터 오염 위험.
- **해결**: 상태 머신(FSM) 내에 명시적인 `WAIT` 스테이트를 두어 APB의 전송이 완료(`PREADY`)될 때까지 AHB 응답(`HREADYOUT`)을 제어하는 로직 구현.

### 2. 프로토콜 확장성 (Study Limitation)
- **어려움/아쉬움**: 현재 산업계 표준인 AXI4 프로토콜까지 확장하여 구현하지 못한 점.
- **개선점**: 향후 AXI-AHB, AXI-APB 브리지 설계를 위한 선행 학습으로 본 프로젝트의 구조를 모듈화함.

---

## 📚 배운점 및 성과
- **버스 프로토콜 완벽 이해**: 데이터시트와 타이밍 다이어그램을 기반으로 표준 규격을 코드로 옮기는 구현력 확보.
- **Verilog 설계 원칙 숙지**: FSM 설계 시 Moore/Mealy 머신의 장단점 고려 및 안정적인 코딩 스타일 정립.
- **시스템 관점 확대**: 개별 모듈 설계가 아닌 모듈 간 '통신'과 '인터페이스'의 중요성 인식.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : AHB-APB Bridge Verilog 소스
- **[📂 Report](./Report)** : 상세 설계 보고서
