# 🎨 Cadence Virtuoso 활용 4bit ALU 설계

## 📅 프로젝트 정보
- **진행 기간**: 2025.06.03 ~ 2025.06.19
- **관련 과목**: 전자회로설계
- **기술 스택**: `Cadence Virtuoso`, `Spectre Simulation`, `Full-Custom Layout`

---

## 📝 프로젝트 개요
**Cadence Virtuoso**를 활용하여 CMOS 트랜지스터 레벨의 스키매틱 설계부터 레이아웃(Layout) 배치까지 전 과정을 수행하여 **4-bit ALU**를 구현했습니다.

## 🔑 주요 구현 내용
### 1. Bottom-up 설계
- **Basic Gates**: Inverter, NAND, NOR 등 기본 게이트 설계 및 검증.
- **Functional Blocks**: Adder, MUX, Decoder 등 기능 블록 구현.
- **Integration**: 블록들을 계층적으로 결합하여 최종 4-bit ALU 완성.

### 2. 레이아웃 및 검증
- **Layout Design**: 공정 디자인 룰(Design Rule)에 맞춰 소자 배치 및 라우팅.
- **Verification**: **DRC(Design Rule Check)** 및 **LVS(Layout Vs Schematic)** 를 통과하여 설계 무결성 확인.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 배선 복잡도 해결
- **문제**: 셀(Cell) 집적도 증가에 따른 메탈 배선 꼬임 및 면적 증가.
- **해결**: Euler Path(오일러 경로) 기반의 Stick Diagram을 활용하여 트랜지스터 배치를 최적화하고 공통 전원선 공유 구조 적용.

### 2. 기생 성분(Parasitics) 최소화
- **문제**: 레이아웃 후 시뮬레이션에서 기생 커패시턴스로 인한 지연 시간 증가.
- **해결**: 배선 길이를 최적화하고 긴 경로에 버퍼(Buffer)를 추가하여 신호 지연 개선.

---

## 📚 배운점
- **Full-Custom Flow**: 스키매틱 ➡ 시뮬레이션 ➡ 레이아웃 ➡ 검증으로 이어지는 IC 설계 전체 흐름 경험.
- **EDA 툴 활용**: Cadence Virtuoso 툴 활용 능력 및 공정 디자인 룰 이해.
- **물리적 설계**: 회로도가 실제 실리콘 웨이퍼 상에서 구현되는 물리적 형태에 대한 이해.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : 설계 데이터
- **[📂 Report](./Report)** : 최종 설계 보고서
