# 실행과 검증 범위

```powershell
python tools/run_xsim.py Softmax_Accelerator_IP/Code/tests.json --vivado-bin "$env:VIVADO_BIN"
```

Python 3과 Vivado XSim이 필요하다. `Code/run_tests.bat`도 같은 실행기를 사용한다. TOP, 포맷 헤더, interface, package, static TB 순서로 컴파일하고 Python golden model을 호출한다. 원본 UVM 폴더명은 기존 링크를 유지하기 위해 보존했으며, 실제 TB는 `uvm_pkg`를 사용하지 않는 클래스 기반 환경이다.

회귀는 reset matrix, singleton, uniform, mixed vector, backpressure, C_MAX frame boundary, collision/rearm, keep-ignore, special FP32, random coverage의 10개 시나리오다. 13,355 beats가 bit-accurate 모델과 일치했다. 수치 오차 0은 RTL 근사 모델과의 일치를 뜻하며, 실수 softmax와의 수학적 오차 0을 뜻하지 않는다.

`Code/include/SoftmaxFormat.vh`가 현재 기본 포맷을 정의한다. 포맷 sweep은 소프트웨어 모델 실험이며 실제 합성 PPA와 구분한다. `run_softmax_qor.ps1`의 자동화 빌드는 별도 [FPGA_Auto_Project](https://github.com/BUJH99/FPGA_Auto_Project)가 필요하다. `run_softmax_fmax_sweep.py`는 독립 후보 프로젝트를 생성해 구현 실험을 수행하는 선택 도구다.

기존 `SW.C`는 Simple AXI DMA의 32-bit 스트림과 4-byte beat를 사용해 현재 TOP의 FP32 입출력 폭과 맞는다. 플랫폼 BSP·DMA IP·IRQ 설정이 필요하며 이번 작업에서 PS 펌웨어를 보드에 재배포하지 않았다. README의 과거 13배 수치를 이번 포맷 회귀의 성능 결과로 합치지 않는다.

과거 `TOP_verification_plan.md`, `UVM_REPORTl.html`, 수상 이미지는 원문과 경로를 보존했다. 새 회귀의 로그와 JSON은 별도 날짜 결과 폴더에 둔다.

[최종 10개 시나리오 결과](../Report/verification_2026-10-15/softmax_all_artifacts/tb_runtime/suite_summary_all.json) · [실행 로그](../Report/verification_2026-10-15/softmax_all.log). 시나리오 coverage 값을 native Vivado coverage로 중복 표기하던 항목은 새 결과에서 제거했다.
