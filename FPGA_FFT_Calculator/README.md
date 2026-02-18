# 📡 FPGA 기반 FFT 계산기 (FPGA-based FFT Calculator)

## 📅 프로젝트 정보
- **진행 기간**: 2025.11.30 ~ 2025.12.10
- **기술 스택**: `Verilog HDL`, `FFT Algorithm (Cooley-Tukey)`, `Keypad Interface`, `7-Segment/LCD Display`

---

## 📝 프로젝트 개요
디지털 신호 처리(DSP)의 핵심인 **FFT(Fast Fourier Transform)** 알고리즘을 Verilog HDL을 사용하여 FPGA 상에 하드웨어로 직접 구현한 프로젝트입니다.

## 🔑 주요 구현 내용
### 1. FFT 하드웨어 설계
- **Butterfly Unit**: 복소수 덧셈 및 곱셈을 수행하는 연산 유닛 설계.
- **Control Logic**: Cooley-Tukey 알고리즘의 스테이지별 데이터 흐름 제어 및 Twiddle Factor ROM 테이블 구성.

### 2. 주변장치 인터페이스
- **입력**: 4x4 키패드 입력을 위한 스캐닝 및 디바운싱(Debouncing) 로직 구현.
- **출력**: 변환된 주파수 도메인 데이터를 7-Segment/LCD에 디스플레이.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. 연산 자원 최적화
- **문제**: 부동소수점(Float) 연산 구현 시 FPGA 리소스 소모가 과하고 타이밍 맞추기가 어려움.
- **해결**: **고정소수점(Fixed-point)** 연산으로 변환하여 구현하고, 비트 폭 시뮬레이션을 통해 오차 범위 내에서 자원 효율성 확보.

### 2. 복잡한 FSM 제어
- **문제**: 다단계 연산 구조로 인해 상태 제어 로직이 복잡해짐.
- **해결**: 데이터 흐름도(Signal Flow Graph)를 기반으로 카운터 중심의 제어 로직을 설계하여 FSM 단순화.

---

## 📚 배운점
- **DSP 알고리즘 이해**: 수식으로 된 알고리즘을 디지털 회로로 변환하는 과정 체득.
- **산술 연산 설계**: 하드웨어 곱셈기/가산기 설계 및 오버플로우 처리 기법 습득.
- **시스템 통합**: 연산 코어와 입출력 장치를 결합하여 하나의 기능을 수행하는 시스템 완성.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : FFT Verilog 소스코드
- **[📂 Report](./Report)** : 최종 보고서
