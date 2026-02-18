# 🧪 반도체 디스플레이 공정 프로젝트 (Semiconductor Process Design)



## 📅 프로젝트 정보
- **진행 기간**: 2024.11.26 ~ 2024.12.10
- **관련 과목**: 반도체디스플레이공정
- **주요 내용**: `CMOS LDO`, `8대 공정`, `Process Integration`

---

## 📝 프로젝트 개요
반도체 8대 공정(포토, 식각, 증착 등) 이론을 바탕으로, 실제 **CMOS LDO(Low Drop-Out) Regulator** 회로가 웨이퍼 상에 구현되기까지의 전체 공정 흐름(Process Flow)을 설계한 프로젝트입니다.

## 🔑 주요 기능 및 내용
### 1. Full Process Flow 설계
- **Wafer ~ Packaging**: Bare Wafer 준비부터 산화(Oxidation), 포토(Photolithography), 식각(Etching), 이온 주입(Ion Implantation), 금속 배선(Metallization) 등 전공정 설계.
- **CMOS 구조 해석**: PMOS와 NMOS를 동일 기판에 집적하기 위한 N-Well/P-Well 형성 과정 시뮬레이션.

### 2. 소자 특성과 공정 변수 상관관계 분석
- Gate Oxide 두께 조절을 통한 Threshold Voltage 제어 계획 수립.
- 열처리(Annealing) 공정이 Dopant 확산에 미치는 영향 분석.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 공정 순서(Integration) 설계의 복잡성
- **어려움**: 단위 공정 순서가 바뀌었을 때 소자가 파괴되거나 의도치 않은 기생 성분이 생기는 문제(Thermal Budget 고려).
- **해결**: 표준 CMOS 공정(Twin-tub process) 레퍼런스를 심층 분석하여 열 예산(Thermal Budget)을 고려한 최적의 공정 순서 도출.

### 2. 포토마스크(Mask) 설계
- **어려움**: 평면적인 회로도를 3차원 적층 구조로 변환할 때 필요한 마스크 레이어 정의의 어려움.
- **해결**: 단면도(Cross-sectional view)를 단계별로 드로잉하며 각 공정 단계에 필요한 마스크를 역설계하는 방식으로 해결.

---

## 📚 배운점 및 성과
- **공정 통합(Process Integration) 이해**: 단순한 단위 공정의 나열이 아닌, 소자의 전기적 특성을 결정짓는 통합적 관점에서의 공정 설계 역량 함양.
- **반도체 구조 이해**: 2D 회로도가 실제 물리적인 3D 구조물로 어떻게 구현되는지에 대한 공간적 이해도 증진.

---

## 📂 포트폴리오 목차
- **[📂 Presentation](./Presentation)** : 공정 설계 발표 자료
