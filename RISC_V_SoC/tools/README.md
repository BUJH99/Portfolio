# RISC-V SoC 개발 도구

펌웨어 빌드, UART 프로그램 적재, SoC 주소 정의 생성, XSim 실행과 명령어 메모리 비교 도구입니다. 아래 명령은 `RISC_V_SoC` 폴더에서 실행합니다.

## 도구 구성

| 경로 | 기능 |
|---|---|
| `common/` | 프로젝트 기본값, RISC-V GCC 탐색, 명령어·메모리 이미지 처리 |
| `soc/` | `soc.yml`에서 RTL·C·링커·메모리 맵 생성 |
| `firmware/` | BootRom, UART 앱, Bubble Sort E2E 펌웨어 빌드 |
| `uart/` | RAXI 로더 패킷 생성·전송, UART 다운로드 GUI |
| `sim/` | 시나리오 이름으로 회귀 테스트 선택 |
| `timing/instr_mem_sweep/` | 명령어 메모리 구현·용량별 시뮬레이션과 합성·배치배선 비교 |

## 개발 환경

Python 3을 사용하며, UART 도구는 `pyserial`, SoC 설정·메모리 실험 도구는 `PyYAML`을 사용합니다.

```powershell
python -m pip install -r .\requirements.txt
```

펌웨어 빌드는 RISC-V GCC를 PATH 또는 `RISCV_GCC`에서 찾습니다. XSim 실행은 Vivado의 `bin` 경로를 PATH, `VIVADO_BIN` 또는 `--vivado-bin`으로 지정합니다.

## 펌웨어 빌드·UART 다운로드

```powershell
.\tools\uart\menu.bat bootrom
.\tools\uart\menu.bat app
.\tools\uart\menu.bat download COM5
.\tools\uart\menu.bat gui
```

`download COM5`는 COM5에 연결된 보드로 기본 앱을 전송하는 예시입니다. 기본값은 [`common/project_config.py`](./common/project_config.py)에 정의되어 있습니다.

| 항목 | 기본값 |
|---|---|
| UART 속도 | 115,200 bps |
| ProgramRam 적재·진입 주소 | `0x1000` |
| 앱 소스 | `sw/apps/hello_world/src/main.c` — Bubble Sort |
| UART 앱 출력 이름 | `hello_world_uart` |

E2E 시뮬레이션용 펌웨어는 다음 명령으로 생성하고 테스트 입력 경로에 배치합니다.

```powershell
python .\tools\firmware\build_bubble_sort_firmware.py
Copy-Item .\output\firmware\bubble_sort_demo.mem .\sw\prebuilt\bubble_sort_demo.mem
```

## XSim 시나리오

```powershell
python .\tools\sim\xsim_runner.py uart_inst_dma
python .\tools\sim\xsim_runner.py bubble_sort_e2e
python .\tools\sim\xsim_runner.py master_slave_preflight
python .\tools\sim\xsim_runner.py axi_apb_bus
```

전체 테스트는 `run_tests.bat`으로 실행합니다. 시나리오 실행기도 `--vivado-bin`과 `--output`을 공통 실행기에 전달합니다.

## SoC 주소 정의 생성

```powershell
python .\tools\soc\generate_soc_artifacts.py
```

[`soc.yml`](../soc.yml)을 읽어 `src/soc_addr_pkg.sv`, `sw/common/include/soc_memory.h`, `sw/linker/generated_memory.ldh`, `md/SOC_MEMORY_MAP.md`를 생성합니다.

펌웨어·UART·메모리 실험 산출물은 `output/`, 회귀 테스트 결과는 `results/`에 생성됩니다. 명령어 메모리 비교 구성과 실행 옵션은 [Instruction Memory Sweep](./timing/instr_mem_sweep/README.md)에 정리되어 있습니다.
