# 🧮 FPGA 기반 8-Point FFT 계산기

## 📅 프로젝트 정보

- **수행**: 2025년 · 최종 보고서 2025.12.11
- **하드웨어**: JFK-200A, 키패드, 8자리 7-Segment
- **본인 담당**: UI FSM, 키패드 디바운싱·디코딩, 표시 구동, Double Dabble BCD 변환
- **기술**: `SystemVerilog` · `Radix-2 DIF FFT` · `XSim`

## 📝 프로젝트 개요

키패드로 입력한 실수 8개를 FFT로 변환하고 복소수 결과를 표시하는 팀 프로젝트입니다. 기존 코드 위치에 제어·연산·표시 모듈을 분리한 개선 구현을 반영했습니다.

## 🔑 주요 구현과 검증

- **21-bit 입력 → 32-bit 내부 연산·출력**, 소수점 3자리 표시를 위한 ×1000 정수 스케일
- 3단계 조합 논리 Butterfly와 입출력 레지스터, `181/256` Shift-Add 회전 인자 근사
- Zero·Impulse·Constant·Alternating·Twiddle 5개 벡터와 BCD 4개 입력, TOP idle 검사 **PASS**
- 기존 XDC를 현재 TOP 포트 이름에 맞춰 수정. 원래 보드 핀과 10 MHz 제약 유지

## 📂 코드와 자료

- [RTL](./Code/Sourcecode) · [테스트벤치](./Code/Testbench) · [실행 결과](./Report/verification_2026-10-15/summary.json)
- [실행 안내·역할 구분](./docs/verification.md) · [기존 보고서](./Report) · [소스 이관 기록](./SOURCE_VERSION.md)
