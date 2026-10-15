# 실행과 검증 범위

저장소 루트에서 Python 3과 Vivado XSim을 사용한다. `VIVADO_BIN`에는 설치한 Vivado의 `bin` 경로를 설정한다.

```powershell
python tools/run_xsim.py FPGA_Image_Filtering/Code/tests.json --vivado-bin "$env:VIVADO_BIN"
```

`Code/TestBench/run_module_perf_tb.bat`, `run_perf_tb.bat 1 preload`, `run_perf_tb.bat 1 stream`도 같은 실행기를 사용한다. `run_linebuffer_ooc.bat`은 Line Buffer만 `xczu3eg-sbva484-1-i` 대상으로 OOC 합성한다. 새 실행마다 빌드와 결과 경로를 분리한다.

| 검증 | 결과와 한계 |
| --- | --- |
| 모듈 성능 TB | 480×272의 모든 Line Buffer 윈도우를 독립 zero-padding 모델과 비교. 기존 Case9 대비 읽기 횟수와 전송 간격 측정 |
| 4개 필터 × preload/stream | 8회 처리량 계측 완료. 출력 BRAM write commit 130,560회. 전체 픽셀 값의 필터별 golden 비교는 포함하지 않음 |
| OOC 합성 | 합성 오류 0. 10 ns 제약, WNS 8.332 ns. 배치·배선 후 보드 타이밍 결과가 아님 |
| 카메라 스트림 | 첫 출력이 입력 프레임 완료보다 빠르며 초기 LCD 출력에 X가 존재. frame-ready, 반복 프레임 제어 및 표시 동기화가 필요한 코어 성능 실험 구성 |

현재 TOP은 벤더의 `InputMemory_RGB888`, `OutputMemory_RGB565` IP를 참조한다. 시뮬레이션에서는 `tb_memory_models.v`를 사용한다. 완전한 Vivado Block Design/IP 재생성 및 보드 재검증은 이번 이관 범위에 포함되지 않는다. XDC의 외부 포트 이름은 현재 TOP과 일치하며, PS 내부 clock/reset/filter-mode 연결은 주석 상태다.

기존 미커밋 TB의 계측 의도와 필터 모드 주석은 개선본에 반영되어 있다. 기존 Verilog 소스는 외부 백업 후 교체했고, 비교용 Case9는 `TestBench/reference`에서만 컴파일한다. [새 로그](../Report/verification_2026-10-15)와 [과거 계측](../Report/benchmark_2026-08-01)은 실행 시점을 구분한다.
