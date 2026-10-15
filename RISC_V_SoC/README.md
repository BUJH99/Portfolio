# 🧠 RISC-V RV32I 5-Stage SoC

## 📝 프로젝트 개요

Basys3 단일 코어 RV32I SoC의 2026년 5월 버전을 공개합니다. CPU 파이프라인, AXI4-Lite–APB 주변장치, UART 명령어 다운로드와 C 펌웨어를 함께 구성했습니다.

## 🔑 주요 구현

- **5-stage Core**: Fetch·Decode·Execute·Memory·Writeback, Hazard·Forwarding
- **SoC**: AXI4-Lite–APB, UART·GPIO·I2C·SPI·FND·Timer
- **제어**: CSR, trap, interrupt controller, UART InstDMA와 프로그램 RAM
- **실행 예제**: Bubble Sort 펌웨어와 별도 SPI/I2C 표시 Slave의 종단간 연결

## 🧪 검증과 재현

**15 / 15 실행 PASS** · [검증 로그와 소스 해시](./results/2026-10-15/summary.json)

- AXI/APB·Timer·CSR·Trap·InstDMA·메모리·UART Router 단위 시험
- UART 다운로드 후 프로그램 RAM 반영, Master/Slave SPI·I2C 사전 시험
- 실제 펌웨어를 실행하는 Bubble Sort E2E: UART·GPIO·버스·표시 상태 확인

## 📂 코드와 자료

- [RTL](./src) · [테스트벤치](./tb) · [펌웨어](./sw) · [빌드·UART 도구](./tools)
- [실행·검증 결과 안내](./docs/verification.md) · [전체 SoC 구조](./docs/images/OverallSOC.png)
- [메모리 맵](./md/SOC_MEMORY_MAP.md) · [고정 커밋과 이관 기록](./SOURCE_VERSION.md)

공개 범위는 단일 코어 RV32I입니다. 이후 개발된 멀티코어·캐시 확장과 이번 실행 결과를 혼합하지 않습니다.
