# 🚀 Softmax Accelerator IP

## 📅 프로젝트 정보

- **수행**: 2025.08 ~ 2025.09 · 차세대반도체학과 경진대회 **우수상**
- **기술**: `Verilog` · `AXI4-Stream` · `SystemVerilog class TB` · `Python`

## 📝 프로젝트 개요

FP32 스트림을 고정소수점으로 변환해 Softmax를 계산하는 RTL 가속기입니다. 포맷 정의, Python 참조 모델, 프로토콜 검증 환경을 같은 코드 묶음으로 정리했습니다.

## ✅ 검증 결과

| 회귀 시나리오 | 비교한 출력 | 오류 |
| :---: | :---: | :---: |
| **10 / 10 PASS** | **13,355 beats** | **0** |

- Reset·frame 경계·backpressure·동시 종료·특수 FP32 정책 검증
- 32-bit AXI-Stream, signed Q7.8, U0.16 지수값, 27-bit 누산기의 포맷 계약 통합
- 정의된 시나리오 커버리지 **100%**. 전체 코드·프로토콜 커버리지를 의미하지 않음
- 기존 DMA 펌웨어의 32-bit word 스트림과 최대 1024개 입력 조건 유지

검증 환경은 UVM 구성 방식을 참고한 **클래스 기반 SystemVerilog TB**입니다. 과거 약 13배 HW/SW 성능 비교는 당시 보드 측정이며, 이번 회귀에서 새로 측정한 속도 수치는 아닙니다.

## 📂 코드와 자료

- [RTL](./Code/Source) · [검증 코드](./Code/Testbench/UVM/TOP_tb) · [펌웨어](./Code/SW)
- [실행·검증 안내](./docs/verification.md) · [포맷 계약](./Report/Design/BITWIDTH_SCALING_QOR_CONTRACT.md)
- [새 회귀 결과](./Report/verification_2026-10-15/summary.json) · [기존 HTML 보고서](./Report/UVM_REPORTl.html) · [수상·보고 자료](./Report) · [소스 이관 기록](./SOURCE_VERSION.md)
