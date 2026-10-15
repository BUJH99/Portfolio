# 🧪 FIFO UVM 검증

## 📝 프로젝트 개요

4-bit × 8-entry 동기 FIFO를 UVM Agent·Scoreboard·Coverage로 검증한 프로젝트입니다. DUT의 실제 수락 조건과 출력 데이터를 큐 기반 참조 모델로 비교합니다.

## ✅ 주요 구현과 검증

| 랜덤 seed | 검증한 clock cycles | 수락된 write / read |
| :---: | ---: | ---: |
| 1 | 659 | 110 / 110 |
| 17 | 666 | 110 / 110 |
| 2026 | 657 | 117 / 117 |

- Fill·drain·overflow·underflow·동시 read/write 후 200개 랜덤 명령 실행
- 3회 모두 **UVM error/fatal 0**, 종료 시 pending 데이터 0
- 입력을 clock edge 이전, 등록 출력을 NBA 이후 관찰하도록 Monitor 타이밍 수정
- Full/Empty 상호 배제와 read-data X 검출 assertion 포함

## 📂 코드와 자료

- [RTL](./src/Top.sv) · [UVM 테스트벤치](./tb) · [실행·검증 안내](./docs/verification.md)
- [새 회귀 결과](./results/2026-10-15/summary.json) · [과거 구조도·Coverage 이미지](./docs/images)
- [소스 이관 기록](./SOURCE_VERSION.md)
