# 🧪 반도체 디스플레이 공정 설계 (Semiconductor Process Design)

## 📅 프로젝트 정보
- **진행 기간**: 2024.11.26 ~ 2024.12.10
- **관련 과목**: 반도체디스플레이공정
- **주요 내용**: `CMOS LDO`, `8대 공정`, `Process Integration`

---

## 📝 프로젝트 개요
반도체 8대 공정 이론을 바탕으로, **CMOS LDO(Low Drop-Out) Regulator** 회로를 구현하기 위한 전체 **공정 흐름(Process Flow)** 을 설계한 프로젝트입니다.

## 🔑 주요 수행 내용
### 1. Full Process Flow 설계
- **Flow Design**: 웨이퍼 준비부터 산화, 포토, 식각, 이온 주입, 배선까지 전공정 단계 설계.
- **CMOS Integration**: N-Well/P-Well 형성을 통해 PMOS와 NMOS를 단일 기판에 집적하는 공정 시퀀스 구성.

### 2. 소자 특성 제어
- **Threshold Voltage**: Gate Oxide 두께 조절을 통한 문턱 전압 제어 설계.
- **Annealing**: 열처리 공정에 따른 Dopant 확산 프로파일 및 소자 특성 변화 분석.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 공정 통합(Integration) 이슈
- **문제**: 공정 순서 배치에 따라 이전에 형성된 구조가 파괴되거나 원치 않는 기생 성분 발생.
- **해결**: Thermal Budget(열 예산)을 고려하여 고온 공정을 앞단에 배치하는 등 최적의 공정 순서 도출.

### 2. 마스크(Mask) 설계
- **문제**: 2D 평면 설계를 3D 적층 구조로 구현하기 위한 마스크 레이어 정의의 어려움.
- **해결**: 각 공정 단계별 단면도(Cross-sectional view)를 그려가며 역설계 방식으로 필요한 마스크 레이어 확정.

---

## 📚 배운점
- **Process Integration**: 단위 공정들이 모여 하나의 소자를 형성하는 통합적 공정 설계 중요성 이해.
- **3D 구조 이해**: 2D 레이아웃과 실제 3D 소자 구조 간의 관계 파악.

---

## 📂 포트폴리오 목차
- **[📂 Presentation](./Presentation)** : 공정 설계 발표 자료
