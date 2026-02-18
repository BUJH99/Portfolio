# 📟 엘리베이터 회로 설계 및 PCB 제작

## 📅 프로젝트 정보
- **진행 기간**: 2025.07.14 ~ 2025.07.26
- **주관 및 수강**: 나인ES캠퍼스
- **기술 스택**: `OrCAD Capture`, `PCB Editor`, `Discrete Logic (CD4000/74HC Series)`

---

## 📝 프로젝트 개요
MCU 없이 **Discrete Logic Gate**만을 조합하여 1층부터 9층까지 동작하는 엘리베이터 제어 회로를 설계하고, **OrCAD**를 이용해 실제 PCB로 제작한 프로젝트입니다.

## 🔑 주요 구현 내용
### 1. 제어 회로 설계 (Discrete Logic)
- **Input & Encoding**: 9개의 층 버튼 입력을 **Priority Encoder (`CD4532B`)** 를 통해 BCD 데이터로 변환.
- **State Storage**: **D-Latch (`CD4042A`)** 를 사용하여 목표 층 데이터를 저장하고, **Group Select (GS)** 신호로 래치 타이밍 제어.
- **Up/Down Logic**: **Magnitude Comparator (`74HC85`)** 가 현재 층과 목표 층을 비교하여 Up/Down 신호 생성.
- **Position Counting**: **Up/Down Counter (`CD4516B`)** 가 클럭에 맞춰 층수를 카운팅하고 7-Segment로 디스플레이.

### 2. 클럭 생성 및 PCB 제작
- **Clock Generator**: 트랜지스터(`2N3904/3906`) 기반의 비안정 멀티바이브레이터로 약 **100Hz**의 구동 클럭 생성.
- **PCB Artwork**: Bottom Layer 배선을 위해 **Mirror(좌우 반전)** 설계를 적용하고, Through-hole 부품 실장.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 래치 타이밍 불안정 (Latch Stability)
- **문제**: 버튼을 누르는 순간의 채터링(Chattering)이나 신호 지연으로 인해 엉뚱한 층 값이 저장되는 현상.
- **해결**: 인코더의 **GS(Group Select)** 신호를 래치의 클럭 입력으로 활용하여, 유효한 버튼 입력이 들어온 순간에만 데이터가 래치되도록 동기화.

### 2. 발진 주파수 오차 보정
- **문제**: 시뮬레이션상의 클럭 주파수와 실제 제작된 회로의 주파수 차이로 엘리베이터 이동 속도가 부자연스러움.
- **해결**: 발진 회로에 **가변저항(VR1)** 을 배치하여 오실로스코프로 파형을 관측하며 최적의 주파수(약 100Hz)로 튜닝.

---

## 📚 배운점
- **Digital Logic Flow**: 인코딩 ➡ 저장 ➡ 비교 ➡ 카운팅으로 이어지는 순차 논리 회로의 전체적인 데이터 흐름 체득.
- **PCB Design Rule**: 부품의 Footprint 생성부터 배선(Routing), 거버 파일 생성까지의 하드웨어 제작 공정 숙지.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : OrCAD 설계 파일
- **[📂 Report](./Report)** : 실습 결과 보고서
