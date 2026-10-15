# 실행과 검증 범위

Python 3, Vivado XSim 2025.2를 사용한다. 저장소 루트에서:

```powershell
python tools/run_xsim.py RISC_V_SoC/tests.json --vivado-bin "$env:VIVADO_BIN"
```

`--job uart_inst_dma`, `--job board_preflight`, `--job bubble_sort_e2e`로 개별 시험을 선택할 수 있다. 기존 `tools/sim/xsim_runner.py`의 시나리오 이름도 같은 검증 matrix로 연결된다. `glbl.v`는 설치한 Vivado에서 읽고 벤더 파일을 저장소에 복사하지 않는다.

펌웨어를 다시 만들려면 RISC-V bare-metal GCC를 `RISCV_GCC`로 지정한다.

```powershell
$env:BUBBLE_SORT_TICK_DELAY_LOOPS = '1000'
python RISC_V_SoC/tools/firmware/build_bubble_sort_firmware.py
```

이번 검증용 `sw/prebuilt/bubble_sort_demo.mem`은 RV32I/Zicsr·ILP32로 다시 빌드한 938 words, BSS 72 bytes의 입력 이미지다. SHA-256은 `99568a4ae007f279d84bfcd3879b0fee9c20f8fa03cfd00825acb155c689d8c8`이다. `sw/apps/hello_world/src/main.c`는 이름과 달리 Bubble Sort 제어 펌웨어다. 새 펌웨어를 검증에 사용할 때는 생성한 `output/firmware/bubble_sort_demo.mem`을 `sw/prebuilt`로 반영해야 한다.

## 이관하면서 수정한 연결

- 원본 PC의 메모리 파일 절대 경로를 상대 경로로 교체했다.
- 별도 Slave를 `SortDisplaySlaveCore`로 이름 짓고 중복 FND 모듈은 `SortFnd*`로 분리했다.
- Slave의 active-low reset과 TB의 active-high reset을 연결할 때 극성을 변환했다.
- 오래된 TB의 내부 probe 이름과 APB 응답 관찰 시점을 현재 RTL에 맞췄다.
- 펌웨어의 display mode 0/1/2/3 = pass/compare/swap/total 계약에 맞게 Slave를 보완했다. 정상 선택과 범위 밖 값의 오류·W1C 처리를 preflight에서 검사한다.

실행기는 PASS 문구, 오류·fatal, 종료 상태를 함께 검사한다. CPU 명령어 집합의 완전한 compliance 인증이나 새 보드 배치·배선·실기 검증을 의미하지 않는다. `md/PIPELINE_PERF_REPORT.md`, `md/INTEGRATED_TIMING_REPORT.md`는 고정 커밋에 포함된 과거 보고서다.

최종 실행: **15/15 PASS**. 단위·UART·보드 연결 14개 시험과 펌웨어 E2E 1회이며, E2E 내부의 UART load/sort, GPIO start, pause/step/resume, reset, I2C display-mode 5개 시나리오가 모두 통과했다. [실행 명령·로그·소스 해시](../results/2026-10-15/summary.json).
