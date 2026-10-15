# 🧮 FPGA 기반 8-Point FFT 계산기

## 📅 프로젝트 정보

- **수행**: 2025년 · 최종 보고서 2025.12.11
- **보고서 하드웨어**: JFK-200A, 키패드, 8자리 7-Segment
- **본인 담당**: UI FSM, 키패드 디바운싱·디코딩, 표시 구동, Double Dabble BCD 변환
- **팀원 담당**: FFT 코어 설계, TOP 통합
- **기술**: `SystemVerilog` · `Radix-2 DIF FFT` · `XSim`

## 📝 프로젝트 개요

키패드로 입력한 실수 8개를 FFT로 변환하고 복소수 결과를 표시하는 팀 프로젝트입니다. 사용자는 부호·소수점을 포함한 값을 편집한 뒤 FFT를 실행하고, 결과 bin과 실수부·허수부를 선택해 확인할 수 있습니다.

## 🔑 주요 구현과 검증

- **⌨️ 입력 처리**: 4×5 키패드 스캔, 디바운싱·디코딩, 샘플 이동·수정·입력 확정
- **🔢 수 표현**: signed 21-bit 입력과 32-bit 내부 연산·출력, 소수점 3자리를 위한 ×1000 정수 스케일
- **🦋 FFT 연산**: 3단계 조합 논리 Butterfly, 입출력 레지스터, `181/256` Shift-Add 회전 인자 근사
- **🖥️ 결과 표시**: bin 선택과 실수부·허수부 전환, Double Dabble BCD 변환, 8자리 7-Segment 다중화
- **🧪 회귀 검증**: FFT 5개 입력 벡터, BCD 4개 입력, TOP reset 이후 idle 출력 검사

## 🧩 RTL 구성

| 모듈 | 역할 |
|---|---|
| `TOP` | 키패드 입력·콘솔·FFT 코어·표시 구동 연결 |
| `InputController` | `ClkPulse`, `KeyScan`, `KeycodeDecoder`를 통한 입력 이벤트 생성 |
| `FFTConsole` | UI FSM, 실수 샘플 편집·저장, 결과 선택·표시 제어 |
| `FFT8Core` | 연산 시작·완료 제어, 입력 저장, FFT 데이터패스, 결과 순서 정렬·저장 |
| `BinToBcd7` | 24-bit unsigned 값을 7자리 BCD로 변환 |
| `Seg8Digit` | 1 kHz enable 펄스를 이용한 표시 자리 순환과 소수점 구동 |

`FFT8DifDatapath`의 세 계산 단계는 조합 논리이며, `FFT8InputLatch`와 `FFT8OutputLatch`가 입출력 경계 레지스터를 담당합니다.

## ▶️ 시뮬레이션 실행

**Windows**, **Python 3**, **Vivado XSim**이 필요합니다. Vivado의 `bin` 폴더를 PATH에 등록하거나 `VIVADO_BIN` 환경 변수로 지정합니다.

`FPGA_FFT_Calculator` 폴더에서:

```powershell
.\Code\Testbench\run_tests.bat
```

설치 경로를 직접 지정할 수도 있습니다.

```powershell
.\Code\Testbench\run_tests.bat --vivado-bin "C:\AMDDesignTools\2025.2\Vivado\bin"
```

배치 파일은 저장소 공통 실행기인 [`tools/run_xsim.py`](../tools/run_xsim.py)와 [`Code/tests.json`](./Code/tests.json)을 사용합니다. 통과 시 `PASS fft_directed`와 `1/1 passed`가 출력됩니다.

| 검사 | 입력·확인 범위 |
|---|---|
| FFT | Zero, Impulse, Constant, Alternating, Twiddle 입력의 8개 bin 실수부·허수부 |
| BCD | `0`, `1`, `1,234,567`, `9,999,999` 변환 결과 |
| TOP | Reset 이후 `oFFT`, `oReIm`, `oIndex`의 idle 출력 |

실행 결과는 `Code/results/`, 임시 빌드는 `Code/.sim_build/`에 생성됩니다.

## 📌 보드 제약

[`constr_fft.xdc`](./Code/Constraints/constr_fft.xdc)에 `iClk`의 10 MHz 클럭 제약과 I/O 핀 배치가 정의되어 있습니다.

## 📂 코드와 자료

- **[💻 RTL 소스](./Code/Sourcecode)** · **[🧪 테스트벤치·실행 배치](./Code/Testbench)**
- **[⚙️ 테스트 구성](./Code/tests.json)** · **[📍 보드 제약](./Code/Constraints/constr_fft.xdc)**
- **[📄 최종 보고서](./Report/디지털FPGA설계_TermProject보고서_20202840한정호.pdf)**

최종 보고서에는 역할 분담·개발 환경(**3쪽**), 시스템 개요(**4~6쪽**), 모듈 설명(**7~14쪽**), 검증 결과(**15~16쪽**), 합성·타이밍 결과(**17쪽**)가 수록되어 있습니다.
