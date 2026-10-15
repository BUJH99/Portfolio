# UVM 멀티에이전트 검증 결과 — 2026-10-15

**20/20 회귀 실행 통과.** 12개 테스트 클래스를 4개 topology에서 실행했으며, 랜덤 테스트는 seed 1·17·2026으로 재현했습니다. 도구는 Vivado Simulator 2025.2와 내장 UVM 1.2입니다.

- 정상 테스트 19회: **205개 검증 완료** (SPI 106, I2C 99), 예상하지 않은 UVM_ERROR/FATAL 및 HDL assertion 오류 0개.
- Scoreboard negative 테스트 1회: 오염·누락·중복을 각 1회, 총 **3회 예상 진단**으로 검출하고 정상 전송 3개로 재개 확인.
- 네 가지 구성에서 리셋 복구 확인: 실제 부분 프레임 **6개 중단**, reset epoch 변경, 이후 정상 완료. 모든 실행에서 pending **0**.
- 독립 Slave 두 개의 병렬 테스트: SPI 4개 + I2C 4개 완료, 물리 시간 구간 기준 **5쌍 중첩**. [타임라인 원자료](parallel_timeline.json)로 교차 확인.
- SPI·I2C 각각 정의한 RW×payload cross bin **9/9** 달성. 정상 19회만 병합한 XCRG 리포트의 정의된 3개 covergroup은 100%. 이 수치는 해당 모델의 도달률이며 전체 프로토콜 검증 완전성을 의미하지 않습니다.
- 과거 UVM 보고서·이미지 **21개** 및 다른 Portfolio 프로젝트의 기존 산출물 **31개** SHA-256 일치. 리팩터링 입력 원본 소스 **51개**도 변경 없음.

## 실행별 결과

| Test / 로그 | Topology | Seed | SPI 완료 | I2C 완료 | 중단 | Pending | 결과 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| [SerialSmokeTest](SerialSmokeTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 4 | 4 | 0 | 0 | PASS |
| [SerialSpiSmokeTest](SerialSpiSmokeTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 4 | 0 | 0 | 0 | PASS |
| [SerialI2cSmokeTest](SerialI2cSmokeTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 0 | 4 | 0 | 0 | PASS |
| [SerialProtocolSwitchTest](SerialProtocolSwitchTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 4 | 4 | 0 | 0 | PASS |
| [SerialRandTest](SerialRandTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 14 | 18 | 0 | 0 | PASS |
| [SerialRandTest](SerialRandTest__LOOPBACK__seed17.log) | LOOPBACK | 17 | 18 | 14 | 0 | 0 | PASS |
| [SerialRandTest](SerialRandTest__LOOPBACK__seed2026.log) | LOOPBACK | 2026 | 20 | 12 | 0 | 0 | PASS |
| [SerialCoverageClosureTest](SerialCoverageClosureTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 8 | 8 | 0 | 0 | PASS |
| [SpiSlaveUnitTest](SpiSlaveUnitTest__SPI_SLAVE_UNIT__seed1.log) | SPI_SLAVE_UNIT | 1 | 12 | 0 | 0 | 0 | PASS |
| [I2cSlaveUnitTest](I2cSlaveUnitTest__I2C_SLAVE_UNIT__seed1.log) | I2C_SLAVE_UNIT | 1 | 0 | 13 | 0 | 0 | PASS |
| [SerialDualBusParallelTest](SerialDualBusParallelTest__DUAL_SLAVE_UNIT__seed1.log) | DUAL_SLAVE_UNIT | 1 | 4 | 4 | 0 | 0 | PASS |
| [SerialRepeatedPayloadTest](SerialRepeatedPayloadTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 4 | 4 | 0 | 0 | PASS |
| [SerialRepeatedPayloadTest](SerialRepeatedPayloadTest__SPI_SLAVE_UNIT__seed1.log) | SPI_SLAVE_UNIT | 1 | 4 | 0 | 0 | 0 | PASS |
| [SerialRepeatedPayloadTest](SerialRepeatedPayloadTest__I2C_SLAVE_UNIT__seed1.log) | I2C_SLAVE_UNIT | 1 | 0 | 4 | 0 | 0 | PASS |
| [SerialRepeatedPayloadTest](SerialRepeatedPayloadTest__DUAL_SLAVE_UNIT__seed1.log) | DUAL_SLAVE_UNIT | 1 | 4 | 4 | 0 | 0 | PASS |
| [SerialResetRecoveryTest](SerialResetRecoveryTest__LOOPBACK__seed1.log) | LOOPBACK | 1 | 2 | 2 | 2 | 0 | PASS |
| [SerialResetRecoveryTest](SerialResetRecoveryTest__SPI_SLAVE_UNIT__seed1.log) | SPI_SLAVE_UNIT | 1 | 2 | 0 | 1 | 0 | PASS |
| [SerialResetRecoveryTest](SerialResetRecoveryTest__I2C_SLAVE_UNIT__seed1.log) | I2C_SLAVE_UNIT | 1 | 0 | 2 | 1 | 0 | PASS |
| [SerialResetRecoveryTest](SerialResetRecoveryTest__DUAL_SLAVE_UNIT__seed1.log) | DUAL_SLAVE_UNIT | 1 | 2 | 2 | 2 | 0 | PASS |
| [SerialScoreboardNegativeTest](SerialScoreboardNegativeTest__SPI_SLAVE_UNIT__seed1.log) | SPI_SLAVE_UNIT | 1 | 3 | 0 | 0 | 0 | PASS |

## 근거와 재현

- [실행·명령·소스 해시 전체](summary.json)
- [XCRG Native Coverage HTML](coverage/functionalCoverageReport/dashboard.html) / [Text](coverage/functionalCoverageReport/xcrg_func_cov_report.txt)
- [병합 입력 DB와 해시](coverage_inputs.json) — negative test 제외, 정상 19개 입력. XCRG 화면의 Number of Tests=1은 병합 DB 한 개를 나타냅니다.
- [기존 UVM 산출물 및 원본 소스 보존 검사](preservation_audit.json)
- [다른 Portfolio 산출물 31개 보존 검사](existing_portfolio_preservation.json)
- [Master·Slave 보드 wrapper 별도 elaboration 및 topology 거부 검사](guards/guard_checks.json)
- [초기 Core 패키징 baseline](baseline/README.md)

최종 RTL/TB 내용 해시: `a629f5b60f671856b5ca203f2aa65c51a8b4181904ce7234be19b83ae1ba2ae3`.

```powershell
python sim/run_regression.py
python sim/audit_sources.py
python sim/check_guards.py --output results/guard_check
```

보드 wrapper 검사는 컴파일/elaboration 검사입니다. 실제 보드 합성·배치배선·다운로드는 수행하지 않았습니다. 현재 reset 회귀는 진행 중 write-frame 중단과 이후 write/read 복구를 검증하며, 모든 비트 위치·read-phase reset을 전수 검증하지 않습니다. VCS adapter는 셸 구문을 확인했지만 VCS 실행 환경이 없어 실행 결과에 포함하지 않았습니다.
