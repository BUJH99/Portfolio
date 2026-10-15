# 실행과 검증 범위

```powershell
python tools/run_xsim.py UVM_FIFO/tests.json --vivado-bin "$env:VIVADO_BIN"
```

Vivado XSim 2025.2의 UVM 1.2로 seed 1, 17, 2026을 실행했다. 원본 VCS 진입점은 `bash tb/run_vcs.sh`이며 이번 환경에서 VCS는 실행하지 않았다.

Scoreboard는 pre-edge Full/Empty로 수락 여부를 계산하고 post-NBA read data와 상태를 비교한다. 기존 Monitor는 드라이버의 다음 명령과 이전 출력을 묶어 false mismatch를 만들었으며, 현재는 수락 시점과 등록 응답 시점을 분리한다. Driver의 손상된 변수명을 복구했다. 명령 분포는 write/read/both/idle = 35/35/20/10을 유지하면서 XSim의 concatenation `dist` 제한을 피하도록 별도 rand command 필드를 사용한다.

각 회귀는 directed 경계 시험, 200개 랜덤 명령, 최종 drain을 수행한다. 3회 합계 1,982 cycles와 337개 read 데이터가 확인되었다. 중간 reset·다른 폭/깊이 조합은 이번 회귀에 포함되지 않는다. covergroup은 유지하지만 `cover property` 집계는 XSim에서 지원되지 않으므로 이를 100% assertion coverage로 표현하지 않는다.

`docs/images`의 Coverage 화면은 과거 기록이다. 새 로그와 수치를 혼합하지 않는다.
