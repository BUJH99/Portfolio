# 2026-10-15 포트폴리오 보충 결과

기존 4개 프로젝트는 정식 코드 경로에서 개선본으로 교체했다. 새 프로젝트·대표 화면·세미나 요약과 리듬게임 실행본을 추가하고 루트 목차를 연결했다. 이전 코드의 복원 수단은 Git 이력과 저장소 밖 작업 백업이다.

| 프로젝트 | 이번 반영 | 실제 확인 |
| --- | --- | --- |
| [영상 필터링](../../FPGA_Image_Filtering) | Line Buffer RTL·TB·성능 계측 | 모든 윈도우 비교, 8회 통합 처리량 계측, OOC 합성 |
| [FFT](../../FPGA_FFT_Calculator) | 32-bit 연산 모듈 분리·XDC 갱신 | FFT 5벡터·BCD 4입력·TOP idle PASS |
| [Softmax](../../Softmax_Accelerator_IP) | 포맷 헤더·모델·TB 통합 | 10시나리오·13,355 beats·오류 0 |
| [AGV](../../AGV_Parking_System) | C++20 엔진·Electron UI 교체 | CMake Release·CTest 61/61·npm ci |
| [FIFO UVM](../../UVM_FIFO) | 독립 검증 패키지·샘플링 수정 | 3 seeds·337 read 비교·오류 0 |
| [RISC-V SoC](../../RISC_V_SoC) | 고정 커밋 단일 코어·Slave·펌웨어 | 15/15 실행, E2E 5시나리오 PASS |
| [Sensor Hub](../../FPGA_Sensor_Hub) | RTL·filelist·센서 TB | BCD 10,000입력·HC-SR04·DHT11·UART PASS |
| [FPGAClaw](../../FPGA_Automation) / [ChipBook](../../ChipBook) | 소개·예제·대표 화면·원본 링크 | 선정 파일 해시 및 링크 확인 |
| [UVM·AXI4 세미나](../../Primemas_Internship) | 요약 2개·도식 9개 | 원문 범위와 도식 연결 확인 |
| [리듬게임](../../Touch_Rhythm_Game) | 원본 Python 복구·자체 데모 자산 | 32노트·300프레임·입력 판정·점수 증가 |

[실행 요약 JSON](./summary.json) · [기존 파일 보존 해시](./preservation.json) · [새 로그 원본/공개 해시](./evidence_hashes.json)

보고서·PDF·이미지·기존 실행 산출물은 그대로 보존했다. 코드 교체 및 README 수정 대상으로 정한 파일을 제외한 **기존 486개 파일**이 이관 전 SHA-256과 일치한다. 기존 UVM SPI/I2C 프로젝트는 이미 완료한 버전을 유지했다.

영상 통합 시험의 frame-ready/LCD 정합성 한계, Sensor Hub 보드 제약 미확보, 리듬게임 Arduino 원본 미확보, 새 보드 실기 검증 미수행은 각 프로젝트에 명시했다. Reachability는 원본 전달 전까지 보류한다. 과거 성능·Coverage 그림은 이번 실행 결과와 구분한다.
