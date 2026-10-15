# 실행 방법

프로젝트 루트 `UVM_SPI_I2C`에서 실행합니다. Python 3와 Vivado Simulator가 필요하며, 현재 실행 검증 환경은 **Vivado Simulator 2025.2 / 내장 UVM 1.2**입니다.

## 전체 회귀

`xvlog`, `xelab`, `xsim`이 PATH에 등록되어 있으면 다음 명령으로 실행합니다.

```powershell
python sim/run_regression.py
```

설치 경로를 직접 지정할 수도 있습니다.

```powershell
python sim/run_regression.py --vivado-bin 'C:/AMDDesignTools/2025.2/Vivado/bin'
```

## 개별 테스트

```powershell
python sim/run_regression.py --test SerialSmokeTest
python sim/run_regression.py --test SerialDualBusParallelTest
python sim/run_regression.py --test SerialResetRecoveryTest --topology DUAL_SLAVE_UNIT
python sim/run_regression.py --test SerialRandTest --seed 2026
```

| Topology | RTL 구성 | SPI Agent | I2C Agent |
| --- | --- | --- | --- |
| `LOOPBACK` | Master + Slave 1쌍 | Passive | Passive |
| `SPI_SLAVE_UNIT` | SPI 전용 Slave | Active master BFM | Passive |
| `I2C_SLAVE_UNIT` | I2C 전용 Slave | Passive | Active master BFM |
| `DUAL_SLAVE_UNIT` | 독립 SPI Slave + I2C Slave | Active master BFM | Active master BFM |

SerialCtrlAgent는 모든 구성에서 reset과 switch 설정을 담당합니다. 병렬 검증은 서로 다른 Slave 두 개를 사용합니다.

## 결과와 판정

실행기는 [tests.json](../sim/tests.json)의 12개 테스트 클래스를 topology와 seed별로 20회 실행합니다. 결과는 `results/<실행 시각>/summary.json`과 테스트별 로그에 저장됩니다.

- 테스트명, seed, topology, 도구 버전, 소스 SHA-256 기록
- 완료·중단·미처리 전송 수와 coverage hit mask 기록
- UVM_ERROR/FATAL, HDL assertion 오류, 완료 건수, pending queue 검사
- 정적 `TbTop.P_TOPOLOGY`와 테스트 구성이 다르면 시작 시 실패

`run_test()`는 `UVM_TESTNAME`으로 테스트를 선택합니다. 빌드 캐시는 `sim/.build/`에 저장됩니다.

## 추가 확인

```powershell
python sim/audit_sources.py
python sim/check_guards.py --output results/guard_check
```

`audit_sources.py`는 보존 산출물의 해시와 소스 구성을 확인합니다. `check_guards.py`는 Master·Slave의 보드 wrapper를 각각 elaboration하고, 잘못된 topology/test 조합의 거부 동작을 확인합니다. 두 보드의 `TOP`은 하나의 시뮬레이션 filelist에 함께 넣지 않습니다.

[run_vcs.sh](../sim/run_vcs.sh)는 VCS adapter이며 셸 구문만 확인했습니다. 공개된 회귀 결과는 XSim 실행 기준이며, 보드 합성·배치배선·실기 검증은 포함하지 않습니다.

[검증 계획](verification_plan.md) · [지원 프로토콜](protocol_contract.md) · [원본 및 보존 산출물 해시](source_provenance.json) · [프로젝트 소개](../README.md)
