# ⚗️ 반도체 소자 및 공정 설계 (Semiconductor Device & Process Design)

## 📅 프로젝트 정보
- **진행 기간**: 2024 (3학년)
- **주제**: LDO(Low-Dropout) 레귤레이터 회로 구현을 위한 반도체 공정(Process Flow) 및 레이아웃 설계
- **기술 스택**: `Semiconductor Process (8대 공정)`, `Layout Design`, `LDO Regulator`, `MIMIM Capacitor`

---

## 📝 프로젝트 개요
아날로그 회로인 **LDO(Low-Dropout) Regulator**를 실제 반도체 칩으로 제조하기 위한 **전체 공정 시퀀스(Process Flow)** 를 설계한 프로젝트입니다. 회로 스펙을 만족하면서 칩 면적을 최소화하기 위해 소자 배치(Layout)와 공정 파라미터를 최적화했습니다.

## 🔑 주요 설계 내용
### 1. 소자 및 레이아웃 설계 (Device & Layout)
- **LDO 회로 구현**: 1.8V 입력을 받아 안정적인 출력을 내는 LDO 레귤레이터 설계.
- **MIMIM 커패시터**: 일반적인 MIM(Metal-Insulator-Metal) 구조보다 단위 면적당 정전용량이 높은 **MIMIM(5층 구조)** 커패시터를 설계하여 칩 면적을 획기적으로 줄임 (Cc: 0.5pF, CL: 1pF 달성).
- **HCI 방지 설계**: **LDD(Lightly Doped Drain)** 구조를 적용하여 Hot Carrier Injection에 의한 소자 열화를 방지하고 신뢰성 확보.

### 2. 공정 통합 설계 (Process Integration)
- **Active Area 정의**: **STI(Shallow Trench Isolation)** 공정을 도입하여 소자 간 누설 전류를 차단하고 집적도 향상.
- **Gate 형성**: Poly-Si 증착 및 패터닝을 통해 Gate 전극 형성.
- **Photo & Etch**: PR(Positive) 도포, 노광, 현상 및 **Dry/Wet Etching**을 조합하여 미세 패턴 형성 (Design Rule: 3um).
- **Ion Implantation**: N-Well, Source/Drain 형성을 위한 이온 주입 및 **RTA(Rapid Thermal Annealing)** 열처리 공정 설계.
- **Metalization**: 다층 배선(Multilevel Interconnect) 및 MIMIM 구조 형성을 위한 금속 증착 및 식각 공정.

---

## 🔬 공정 및 분석 결과
- **Chip Size**: 118um x 100um (초소형 레이아웃 달성)
- **Design Rule Check**: 3um 공정 마진과 1um 정렬 오차(Alignment Tolerance)를 고려하여 양산 가능한 수준의 설계 검증.
- **Capacitor Efficiency**: MIMIM 병렬 적층 구조를 통해 단일 레이어 대비 면적 효율 극대화.

---

## 📚 배운점
- **Unit Process to Integration**: 개별 단위 공정(증착, 식각, 노광 등)들이 어떻게 유기적으로 연결되어 하나의 칩을 완성하는지 전체 흐름(Flow)을 체득.
- **Design-Process Interaction**: 회로 성능(Capacitance, R)을 만족시키기 위해 공정 구조(MIMIM, LDD)를 어떻게 변경해야 하는지, 설계와 공정 간의 상호 의존성 이해.

---

## 📂 포트폴리오 목차
- **[📂 Report](./Presentation)** : 설계 상세 내용이 담긴 최종 보고서
