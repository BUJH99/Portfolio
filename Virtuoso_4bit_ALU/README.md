# 📐 Virtuoso 4-bit ALU Layout Design

## 📅 프로젝트 정보
- **진행 기간**: 2024 (3학년)
- **주제**: Cadence Virtuoso를 이용한 Full Custom Analog Layout 설계
- **공정**: `GPDK 180nm CMOS Process`
- **툴**: `Cadence Virtuoso`, `Spectre (ADE L)`, `Assura/Calibre (DRC/LVS/PEX)`

---

## 📝 프로젝트 개요
디지털 회로의 핵심 연산 장치인 **ALU(Arithmetic Logic Unit)** 를 트랜지스터 레벨에서 직접 설계하고 레이아웃(Layout)까지 구현한 프로젝트입니다. 1-bit ALU를 셀 단위로 설계하고 이를 4-bit로 확장하여 **Ripple Carry** 구조의 산술/논리 연산기를 완성했습니다.

## 🔑 주요 설계 내용
### 1. 회로 설계 (Schematic Design)
- **Architecture**: 
    - **Logic Unit**: AND, OR, XOR, XNOR 게이트 구현.
    - **Arithmetic Unit**: 1-bit Full Adder를 기반으로 Ripple Carry Adder 구조 형성.
    - **Control Unit**: 4x1, 2x1 MUX를 사용하여 8가지 연산 모드(ADD, SUB, INC, DEC, AND, OR, XOR, XNOR) 선택.
- **Transistor Sizing**: 논리 게이트의 Rise/Fall Time 균형을 맞추기 위해 PMOS/NMOS 폭(Width) 비율 최적화.

### 2. 레이아웃 설계 (Layout Design)
- **Standard Cell Strategy**: 모든 셀의 높이를 **4.88μm**로 통일하여 Pitch를 맞추고, VDD/GND 라인을 상/하단에 배치해 조립(Abutment)이 용이하도록 설계.
- **Routing**: Metal 1 (내부 결선) 및 Metal 2 (셀 간 배선)를 활용하여 기생 커패시턴스 최소화.
- **Area Usage**:
    - **Full Adder**: 67.89μm x 4.88μm
    - **Logic Gates**: Inverter (5.15μm), NAND/NOR 등 표준 셀 라이브러리 구축.

### 3. 검증 (Verification)
- **DRC (Design Rule Check)**: Min Width, Min Spacing 등 공정 규칙 위반 사항 0건 달성.
- **LVS (Layout vs Schematic)**: 회로도와 레이아웃의 네트리스트 일치 확인 (Match).
- **PEX (Parasitic Extraction)**: 레이아웃의 기생 성분(R, C)을 추출하여 Post-Layout Simulation 진행, 실제 딜레이 및 전력 소모 분석.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 신호 지연 불균형
- **문제**: Ripple Carry 구조 특성상 상위 비트로 갈수록 Carry 전파 지연 누적.
- **해결**: Full Adder의 Carry Out 경로에 구동력이 큰 버퍼를 추가하고 트랜지스터 사이징을 조절하여 Critical Path 딜레이 개선.

### 2. 면적 효율화
- **문제**: 초기 레이아웃 시 배선이 복잡해져 셀 면적이 불필요하게 커짐.
- **해결**: **Finger** 구조 대신 단순한 Folded 구조를 적용하고, 공통 Source/Drain을 공유(Stacking)하여 확산 영역(Active Area) 면적 최소화.

---

## 📚 배운점
- **Full Custom Flow**: Schematic ➡ Symbol ➡ Simulation ➡ Layout ➡ DRC/LVS ➡ PEX로 이어지는 아날로그/디지털 혼합 신호 설계의 전체 흐름 마스터.
- **Physical Verification**: 물리적 검증 툴을 사용하여 공정 미세 불량을 사전에 차단하는 노하우 습득.

---

## 📂 포트폴리오 목차
- **[📂 Report](./Report)** : 최종 설계 보고서
