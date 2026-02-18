# 🎨 Cadence Virtuoso 활용 4bit ALU 설계 (Full-Custom Layout Design)

> **"트랜지스터 하나부터 칩 레이아웃까지: Bottom-up 방식의 디지털 IC 설계"**

## 📅 프로젝트 정보
- **진행 기간**: 2025.06.03 ~ 2025.06.19
- **관련 과목**: 교내 전공 과목 (전자회로설계)
- **기술 스택**: `Cadence Virtuoso`, `Spectre Simulation`, `Analog/Digital Circuit Design`, `Layout`

---

## 📝 프로젝트 개요
산업 표준 EDA 툴인 **Cadence Virtuoso**를 활용하여 트랜지스터 레벨의 스키매틱(Schematic) 설계부터 레이아웃(Layout) 배치까지 전 과정을 수행한 프로젝트입니다. 최종적으로 **4-bit ALU(Arithmetic Logic Unit)** 를 구현하고 검증했습니다.

## 🔑 주요 기능 및 내용
### 1. Bottom-up 설계 프로세스
- **Basic Gates**: CMOS Inverter, NAND, NOR 게이트 설계 및 SPICE 시뮬레이션 검증.
- **Functional Modules**: 1-bit Full Adder, MUX, Decoder 등 소규모 블록 설계.
- **Top Integration**: 모듈을 계층적으로 결합하여 최종 4-bit ALU 완성.

### 2. 레이아웃(Layout) 및 검증
- 공정 디자인 룰(Design Rule)을 준수하며 각 소자의 배치 및 배선(Routing) 수행.
- **DRC(Design Rule Check)** 및 **LVS(Layout Vs Schematic)** 통과를 통한 무결성 검증.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 레이아웃 배선 복잡도 (Routing Complexity)
- **어려움**: 셀(Cell) 단위가 커질수록 메탈 배선(Metal Layer)이 꼬이고 면적이 비효율적으로 늘어나는 문제.
- **해결**: Euler Path(오일러 경로)를 활용한 Stick Diagram을 미리 그려보며 트랜지스터 배치를 최적화하고, 공통 전원선(VDD/GND)을 공유하는 구조(Cell Abutment) 적용.

### 2. 기생 성분(Parasitics) 문제
- **어려움**: 레이아웃 후 시뮬레이션(Post-layout simulation)에서 기생 커패시턴스로 인해 예상보다 지연시간(Delay)이 증가함.
- **해결**: 배선 길이를 최소화하고, 구동 능력이 필요한 경로에는 버퍼(Buffer)를 추가하여 신호 무결성 확보.

---

## 📚 배운점 및 성과
- **IC 설계 Flow 완주**: 스키매틱 ➡ 시뮬레이션 ➡ 레이아웃 ➡ 검증으로 이어지는 Full-Custom 설계의 전체 파이프라인 경험.
- **Tool 숙련도 향상**: Virtuoso의 단축키, 파라미터 설정을 능숙하게 다루며 엔지니어링 툴 활용 능력 극대화.
- **물리적 설계 감각**: 회로도 상의 로직이 실제 실리콘 웨이퍼 상에서 어떤 면적과 형태로 구현되는지에 대한 직관 획득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : 설계 데이터 및 스크립트
- **[📂 Report](./Report)** : 최종 설계 보고서
