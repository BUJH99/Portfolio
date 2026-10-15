# 📐 Virtuoso 트랜지스터 수준 ALU 설계

## 📅 프로젝트 정보

- **수행**: 2025년
- **도구**: `Cadence Virtuoso Schematic Editor` · `ADE` · `Transient Simulation`
- **구성**: 기본 CMOS 논리 게이트 → Full Adder·MUX → 1-bit ALU → 4-bit 확장

## 📝 프로젝트 개요

CMOS 트랜지스터로 기본 논리 게이트를 설계하고, 이를 계층적으로 연결해 **산술·논리 연산을 수행하는 ALU**를 구성한 프로젝트입니다. 블록별 회로도와 Symbol을 작성한 뒤 ADE의 과도응답 시뮬레이션으로 입력·출력 파형을 분석했습니다.

Full Adder와 Logic Module의 결과를 MUX로 선택하는 1-bit ALU를 설계하고, 1-bit 블록 4개의 Carry를 연결해 4-bit 구조로 확장했습니다.

## 🔑 주요 설계 내용

| 설계 블록 | 구성과 기능 |
| :--- | :--- |
| 기본 CMOS 게이트 | Inverter, NAND+Inverter 기반 AND, NOR+Inverter 기반 OR, XOR |
| 2×1 MUX | 선택 신호에 따라 두 입력 중 하나를 출력 |
| 4×1 MUX | 2×1 MUX 3개를 계층적으로 연결해 네 입력 중 하나를 선택 |
| Full Adder | XOR·AND·OR 게이트로 Sum과 Carry 생성 |
| Logic Module | AND·OR·XOR·XNOR 연산 결과 생성 |
| 1-bit ALU | Full Adder·Logic Module·MUX로 산술·논리 결과 선택 |
| 4-bit ALU | 1-bit ALU 4개와 Carry 연결, 공통 연산 선택 신호 구성 |

- **트랜지스터 사이징**: 인버터의 PMOS 폭 240 nm, NMOS 폭 120 nm로 2:1 비율을 적용하고 채널 길이 50 nm로 설정
- **산술 경로**: Full Adder와 입력 선택 MUX로 덧셈·뺄셈·증가·감소 연산 구성
- **논리 경로**: Logic Module의 네 연산 결과를 4×1 MUX로 선택
- **최종 출력**: `S2`와 2×1 MUX로 산술·논리 경로 중 하나를 선택하고 `OUT`·`Carry` 출력

## ✅ 시뮬레이션과 결과 분석

| 대상 | 분석 내용 |
| :--- | :--- |
| Inverter·AND·OR·XOR | 입력 조합에 따른 출력 파형과 논리 진리표 비교 |
| 2×1·4×1 MUX | 선택 신호에 따른 입력 전달 동작 분석 |
| Full Adder | `A`, `B`, `Cin` 조합에 따른 `Sum`·`Carry` 비교 |
| Logic Module | AND·OR·XOR·XNOR 출력 파형 분석 |
| 1-bit ALU | 320 μs 과도응답 분석으로 연산 선택 신호와 `OUT`·`Carry` 파형 비교 |

## 📂 설계 보고서

[회로도·시뮬레이션 설정·결과 파형이 포함된 최종 보고서](./Report/아날로그레이아웃TermProject.pdf)

| 내용 | PDF 페이지 |
| :--- | :---: |
| 기본 CMOS 논리 게이트 | 4~9 |
| 2×1·4×1 MUX | 10~13 |
| Full Adder | 14~15 |
| Logic Module | 16~17 |
| 1-bit ALU 회로와 시뮬레이션 | 18~20 |
| 4-bit ALU 확장 회로 | 21 |
