# 🚀 Softmax Accelerator IP

## 📅 프로젝트 정보

- **수행**: 2025.08 ~ 2025.09
- **수상**: 차세대반도체학과 경진대회 **우수상**
- **기술**: `Verilog` · `AXI4-Stream` · `AXI DMA` · `SystemVerilog class TB` · `Python`

## 📝 프로젝트 개요

FP32 입력 벡터를 확률 분포로 변환하는 **Softmax 하드웨어 가속기**입니다. 고정소수점 연산과 LUT를 사용해 지수·로그 함수를 계산하고, 로그 성질을 이용해 정규화 나눗셈을 뺄셈과 지수 연산으로 구성했습니다.

입력 최댓값을 먼저 구해 각 원소에서 빼는 방식으로 지수 연산의 입력 범위를 제한합니다. 32-bit AXI4-Stream으로 프레임을 주고받으며, 최대 **1,024개 원소**를 처리합니다. DMA 펌웨어는 입력 크기별 전송·실행 시간과 하드웨어 출력을 수집합니다.

## ⚙️ 연산 구조

| 단계 | 주요 모듈 | 동작 |
| :--- | :--- | :--- |
| 입력 변환·최댓값 탐색 | `Downscale`, `Fp32ToQ78`, `MaxTrack` | FP32를 Q7.8로 변환해 프레임을 저장하고 최댓값 탐색 |
| 최댓값 감산·재생 | `DownscaleFsm`, `Q78Ram`, `Q78SubSat` | 저장한 벡터에서 최댓값을 빼고 지수·출력 경로로 동시 전달 |
| 지수값 누산 | `ExpSum`, `Sum` | LUT와 곱셈으로 지수값을 근사하고 프레임 단위로 합산 |
| 정규화 스칼라 계산 | `Ln`, `PriEnc16`, `LnExp`, `LnMant` | 누산 결과의 지수·가수를 분리해 로그값 계산 |
| 출력 벡터 계산 | `Sub`, `FrameBuf`, `ExpOut` | 벡터에서 정규화 스칼라를 빼고 출력 지수값 계산 |
| FP32 출력 | `U16ToFp32`, `TOP` | 고정소수점 결과를 FP32 스트림으로 변환 |

수치 포맷은 [SoftmaxFormat.vh](./Code/include/SoftmaxFormat.vh)에 정의했습니다.

| 데이터 | 포맷 |
| :--- | :--- |
| AXI-Stream 입출력 | IEEE-754 FP32, 32-bit |
| 입력 변환·감산·로그 출력 | signed Q7.8, 16-bit |
| 지수 근사값 | unsigned U0.16, 16-bit |
| 지수값 누산 | 27-bit 누산 후 반올림·11-bit 우측 시프트 |
| 로그 내부 합산 | signed Q4.16, 21-bit |
| 로그 LUT 주소 | 지수 5-bit · 가수 10-bit |

- **흐름 제어**: 각 단계의 `Valid/Ready` 핸드셰이크로 입력 공백과 출력 backpressure 처리
- **프레임 제어**: `Last` 또는 최대 입력 개수로 프레임 종료, 출력 완료 후 다음 프레임 수신
- **데이터 단위**: 입력은 32-bit word 단위로 처리하며, 출력 `Keep`는 `4'hF`
- **특수 입력 처리**: 0·subnormal은 Q7.8의 0으로 변환하고, Inf·NaN은 부호에 따라 포화값으로 변환

## ✅ 핵심 성과

[경진대회 발표 포스터](./Report/회로시스템_숭상화.jpg)의 보드 성능 비교 결과입니다.

| 항목 | 결과 |
| :--- | :--- |
| 하드웨어 처리 속도 | 256개 입력에서 ARM Cortex-A9 소프트웨어 대비 **13.01배** |
| Softmax 수치 정확도 | 최대 절대 오차 **5.505 × 10⁻⁴** |

SystemVerilog 클래스 기반 테스트벤치에서 Python의 **RTL 수치 규칙을 재현한 참조 모델**과 출력 데이터를 비교합니다. 모니터·스코어보드·프로토콜 assertion·프레임 상태 체커를 통해 수치와 스트림 동작을 함께 검증합니다.

| 검증 시나리오 | 비교한 출력 | RTL 참조 모델 불일치 | 시나리오 커버리지 |
| :---: | :---: | :---: | :---: |
| **10 / 10 PASS** | **13,355 beats** | **0** | **100%** |

| 테스트 | 검증 내용 |
| :--- | :--- |
| Reset matrix | 입력 수집·재생·출력·유휴 상태의 리셋과 새 프레임 복구 |
| Singleton frame | 원소 1개인 프레임의 출력값과 종료 신호 |
| Uniform frame | 동일 입력과 다양한 프레임 길이의 정규화 결과 |
| Mixed vector | 양수·음수 혼합, 최댓값 위치, 양자화 동률 |
| Backpressure protocol | 입력 공백·출력 정지·내부 동시 전달 시 데이터 유지 |
| Frame boundary | 최대 길이 직전·최대 길이의 프레임 종료 |
| Collision / rearm | `Last`와 최대 길이 조건의 동시 발생 및 다음 프레임 수락 |
| Keep policy | 입력 `Keep` 패턴에 따른 결과 일치와 출력 `Keep` 값 |
| Special FP32 | 0·subnormal·Inf·NaN의 고정소수점 변환 규칙 |
| Random coverage | 프레임 길이·데이터·stall 조합의 무작위 검증 |

## 🔧 실행 방법

**Python 3, matplotlib, Vivado XSim** 환경에서 저장소 루트를 기준으로 실행합니다.

```powershell
python -m pip install matplotlib
.\Softmax_Accelerator_IP\Code\run_tests.bat --vivado-bin "C:\AMDDesignTools\2025.2\Vivado\bin"
```

[tests.json](./Code/tests.json)이 RTL과 테스트벤치를 컴파일하고 `TESTNAME=all`로 10개 시나리오를 실행합니다. 결과 요약은 `Code/results/`에 생성됩니다.

| 도구 | 용도 |
| :--- | :--- |
| [sweep_softmax_formats.py](./Code/tools/sweep_softmax_formats.py) | 테스트벤치의 입력·기대값 프레임으로 정밀도 후보 비교, Exp·Ln 입력 공간 전수 비교 |
| [run_softmax_fmax_sweep.py](./Code/tools/run_softmax_fmax_sweep.py) | 독립 후보 프로젝트의 Vivado 합성·배치·배선 및 타이밍·자원 사용량 비교 |
| [SW.C](./Code/SW/SW.C) | AXI DMA 전송, 인터럽트 기반 시간 측정, 입력 크기별 하드웨어 출력 수집 |

DMA 펌웨어는 Xilinx BSP의 Simple DMA·인터럽트 설정을 사용하며, 10·32·64·128·256·512·1,000·1,024개 입력의 실행 시간을 측정합니다.

## 📂 코드와 자료

| 경로 | 내용 |
| :--- | :--- |
| [Code/Source](./Code/Source) | Softmax RTL과 TOP 연결 |
| [Code/include](./Code/include) | 수치 포맷 정의 |
| [Code/Constraints](./Code/Constraints) | 100 MHz 클록 제약 |
| [Code/Testbench/UVM/TOP_tb](./Code/Testbench/UVM/TOP_tb) | 클래스 기반 테스트벤치와 Python 참조 모델·리포트 도구 |
| [Report/UVM_REPORTl.html](./Report/UVM_REPORTl.html) | 시나리오별 검증 결과, 오차 분석, 커버리지 상세 보고서 |
| [Report/회로시스템_숭상화.jpg](./Report/회로시스템_숭상화.jpg) | 경진대회 발표 포스터 |
