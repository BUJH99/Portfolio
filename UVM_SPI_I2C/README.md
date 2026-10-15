# 🔌 SPI / I2C UVM 검증

## 📅 프로젝트 정보

- **기술 스택**: `SystemVerilog`, `UVM 1.2`, `SVA`, `Python`
- **검증 환경**: `Vivado Simulator 2025.2` · 2026.10.15 검증

---

## 📝 프로젝트 개요

**SPI·I2C 통신의 데이터 정합성과 프로토콜 동작을 검증**하는 프로젝트입니다.
독립적인 SPI·I2C Agent와 Virtual Sequence를 구성해 루프백, 단위 검증, 병렬 전송을 검증했습니다.

## ✅ 핵심 성과

| 회귀 테스트 | 정상 전송 검증 | 예상 외 오류 |
| :---: | :---: | :---: |
| **20 / 20 PASS** | **205건** | **0건** |

- **Coverage**: 정의한 RW×payload 조합에서 SPI·I2C 각각 **9 / 9 달성**
- **병렬 검증**: 독립 Slave 2개에서 실제 전송 구간 **5쌍 중첩** 확인
- **예외 검증**: 리셋 복구 및 관측값 오염·누락·중복 검출 확인

---

## 🔑 주요 구현 내용

- **Multi-Agent**: 제어·SPI·I2C Agent 분리 및 Active / Passive 구성
- **Virtual Sequence**: 루프백·단위·병렬 시나리오를 하나의 환경에서 실행
- **Scoreboard**: 실제 버스 전송을 복원해 입력 데이터·응답·LED 상태 비교
- **Coverage · SVA**: 검증된 완료 전송의 커버리지 수집 및 핀 동작 규칙 확인

---

## 📂 포트폴리오 목차

- **[📂 RTL Source](./src)** · **[📂 UVM Testbench](./tb)**
- **[📊 검증 결과](./results/2026-10-15_multi_agent/README.md)** · **[Coverage Report](./results/2026-10-15_multi_agent/coverage/functionalCoverageReport/dashboard.html)**
- **[📐 검증 구조](./docs/architecture.md)** · **[실행 방법](./docs/running.md)**
- **[📄 기존 보고서 (2026.04.20)](./results/historical_2026-04-20/index.html)** · **[이미지](./docs/images)**
