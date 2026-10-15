# Image_Filtering 성능 벤치마크 보고서

측정일: 2026-08-01  
도구: AMD Vivado/XSim 2025.2  
대상 FPGA: `xczu3eg-sbva484-1-i`  
영상 크기: 480×272 = 130,560 pixel  
System clock: 100 MHz

## 1. 결론

`TOP`의 기존 `Window3x3Case9`를 실제 2-line-buffer 구조인 `Window3x3LineBuffer`로 교체했다. 새 코어는 외부 input BRAM에서 각 픽셀을 한 번만 순차적으로 읽고, 두 개의 480×24-bit line BRAM과 행별 horizontal shift register로 3×3 이웃을 재사용한다.

측정 결과 window와 통합 processing pipeline 모두 초기 fill 이후 정확히 1 pixel/clock을 달성했다.

| 항목 | 기존 수평 재사용 | 새 2-line-buffer | 변화 |
|---|---:|---:|---:|
| Input BRAM read/frame | 390,720 | 130,560 | 66.7% 감소 |
| 평균 input read/pixel | 2.993 | 1.000 | 66.6% 감소 |
| 픽셀당 평균 출력 간격 | 7.988473 cycle | 1.000000 cycle | 7.988배 개선 |
| Output span | 1,042,968 cycle | 130,560 cycle | 87.48% 감소 |
| Output span time | 10.429680 ms | 1.305600 ms | 87.48% 감소 |
| 처리량 | 12.518 Mpixel/s | 100.000 Mpixel/s | 7.988배 향상 |
| Core-equivalent FPS | 95.880 FPS | 765.931 FPS | 7.988배 향상 |

`765.931 FPS`는 130,560개의 계산 결과가 연속 출력되는 구간을 한 프레임으로 환산한 코어 성능이다. 초기 line fill을 포함한 reset-to-first-frame-complete는 131,046 cycle, 1.310460 ms, 763.09 FPS 상당이다. 실제 시스템의 표시 속도는 LCD timing의 41.55 FPS로 제한된다.

## 2. 구현 구조

새 window generator는 다음 순서로 동작한다.

1. Input frame BRAM을 주소 0부터 130,559까지 한 픽셀씩 순차 읽는다.
2. 현재 픽셀을 첫 번째 line BRAM에 기록한다.
3. 같은 열에 있던 이전 행 픽셀은 두 번째 line BRAM으로 이동한다.
4. 두 line BRAM의 출력과 현재 픽셀을 세 행의 신규 오른쪽 열로 사용한다.
5. 행마다 보유한 두 개의 horizontal tap을 shift해 3×3 window를 완성한다.
6. 첫 열과 마지막 열은 zero padding하고, 마지막 실제 행 뒤에는 가상 zero 행을 한 번 흘려 bottom border를 생성한다.

따라서 3개 행은 `2개 line BRAM + 현재 입력 stream`으로 구성되고, 외부 frame BRAM은 픽셀당 한 번만 읽는다. 두 line memory는 Vivado에서 각각 RAMB18 하나로 추론됐다.

## 3. 독립 모듈 측정

실행 명령:

```bat
tb\run_module_perf_tb.bat
```

테스트벤치는 기존 window와 새 line-buffer window를 동시에 실행한다. 새 window의 130,560개 출력을 software zero-padding reference와 전부 비교한다.

### 3.1 기존 `Window3x3Case9`

| 항목 | 측정값 |
|---|---:|
| Output pixel | 130,560 |
| Input BRAM read | 390,720 |
| Output span | 1,042,968 cycle |
| Frame time | 10.429680 ms |
| Throughput | 12.518 Mpixel/s |
| Equivalent FPS | 95.880 FPS |
| 평균 interval | 7.988473 cycle/pixel |
| Min/Max interval | 3 / 11 cycle |

### 3.2 새 `Window3x3LineBuffer`

| 항목 | 측정값 |
|---|---:|
| Output pixel | 130,560 |
| Input BRAM read | 130,560 |
| Output span | 130,560 cycle |
| Frame time | 1.305600 ms |
| Throughput | 100.000 Mpixel/s |
| Equivalent FPS | 765.931 FPS |
| 평균 interval | 1.000000 cycle/pixel |
| Min/Max interval | 1 / 1 cycle |
| Golden mismatch | 0 |

### 3.3 `Conv3x3ReluParam`

| 항목 | 측정값 |
|---|---:|
| Accepted/output pixel | 130,560 / 130,560 |
| Output span | 130,560 cycle |
| Throughput | 100.000 Mpixel/s |
| Equivalent FPS | 765.931 FPS |
| 출력 간격 | 1 cycle/pixel, 즉 매 클록 1픽셀 |

## 4. TOP 통합 측정

실행 명령:

```bat
tb\run_perf_tb.bat 1 core
```

| 구간 | First cycle | Last cycle | Span | 처리량 |
|---|---:|---:|---:|---:|
| 3×3 window | 484 | 131,043 | 130,560 | 100.00 Mpixel/s |
| Convolution | 485 | 131,044 | 130,560 | 100.00 Mpixel/s |
| RGB565 write command | 485 | 131,044 | 130,560 | 100.00 Mpixel/s |
| Output BRAM commit | 486 | 131,045 | 130,560 | 100.00 Mpixel/s |

- Window valid/transfer: 130,560 / 130,560
- Window stall: 0 cycle
- Convolution valid/transfer: 130,560 / 130,560
- Convolution stall: 0 cycle
- Reset-to-complete: 131,046 cycle = 1.310460 ms
- Active output span: 130,560 cycle = 1.305600 ms

현재 downstream은 항상 write 가능한 고정-rate pipeline이므로 line-buffer window에는 backpressure가 없다. 임의의 downstream stall을 허용하려면 read request를 멈추기 전에 in-flight pixel을 보존할 FIFO를 추가해야 한다.

## 5. OOC 합성 결과

새 line buffer 실행 명령:

```bat
tb\run_linebuffer_ooc.bat
```

100 MHz, 10.000 ns constraint의 post-synthesis OOC 결과다.

| 모듈 | LUT | FF | RAMB18 | DSP | WNS | Data path |
|---|---:|---:|---:|---:|---:|---:|
| 기존 `Window3x3Case9` | 374 | 373 | 0 | 6 | +5.309 ns | 4.672 ns |
| 새 `Window3x3LineBuffer` | 267 | 432 | 2 | 0 | +8.332 ns | 1.276 ns |
| `Conv3x3ReluParam` | 958 | 25 | 0 | 0 | +5.522 ns | 4.496 ns |

새 line buffer는 RAMB18 두 개로 최종 mapping됐고 TNS는 0이다. 기존의 `row×480+col` random address 계산이 사라져 DSP 사용은 6개에서 0개로 감소했다.

## 6. 1.75배 문구와의 관계

기술서의 `1.75배`는 naive 반복-read 구조에서 기존 수평 window 재사용 구조로 바꾼 첫 최적화 단계의 수치다. 이번 구현은 그 기존 수평 재사용 RTL을 다시 true 2-line-buffer로 바꾼 두 번째 최적화다.

따라서 두 수치를 같은 개선으로 섞으면 안 된다.

- 1차 개선: naive → 수평 window 재사용 = 기술서의 1.75배
- 2차 개선: 수평 window 재사용 → true 2-line-buffer = 이번 실측 7.988배

면접에서는 다음처럼 구분한다.

> “기술서의 1.75배는 당시 naive 반복-read 구조를 수평 재사용 구조로 개선한 결과입니다. 이후 같은 병목을 더 제거하기 위해 2개의 line BRAM과 horizontal shift register로 재설계했습니다. 보관된 수평 재사용 RTL과 동일 조건으로 비교하니 input BRAM read가 390,720회에서 130,560회로 줄었고, 평균 II가 7.988에서 1로 감소해 추가로 7.99배 향상됐습니다.”

## 7. 재현 파일

- 새 RTL: `src/Window3x3LineBuffer.sv`
- TOP 연결: `src/TOP.sv`
- 비교·golden TB: `tb/TbTop_module_perf.sv`
- 모듈 benchmark: `tb/run_module_perf_tb.bat`
- 통합 benchmark: `tb/run_perf_tb.bat`
- 새 window OOC 합성: `tb/run_linebuffer_ooc.bat`
- 전체 OOC 합성: `tb/run_ooc_timing.bat`
- 결과 로그와 report: `output/benchmark/`
