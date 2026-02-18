# 🌉 AMBA Protocol 기반 AHB-APB Bridge 설계

## 📅 프로젝트 정보
- **진행 기간**: 2025.06.24 ~ 2025.07.14
- **프로젝트 유형**: 🎓 **학부생 연구 인턴 과제 (Undergraduate Research Intern)**
- **기술 스택**: `Verilog HDL`, `AMBA AHB/APB Protocol`, `ModelSim`, `FSM Design`, `SP-SRAM Interface`

---

## 📝 프로젝트 개요
System-on-Chip (SoC) 설계의 핵심인 **AMBA(Advanced Microcontroller Bus Architecture)** 버스 프로토콜을 분석하고, 고속 시스템 버스(**AHB**)와 저속 주변장치 버스(**APB**) 간의 데이터 전송을 중개하는 **Bridge IP**를 설계했습니다.
단순한 신호 연결을 넘어, 파이프라인된 AHB 동작과 2-Cycle 기반의 APB 동작 간의 타이밍 불일치를 해결하기 위한 **동기화 로직**과 **FSM** 설계에 초점을 맞췄습니다.

## 🔑 주요 기능 및 구현 내용

### 1. AHB-APB Bridge FSM 설계
서로 다른 속도의 버스 프로토콜을 중개하기 위해 **3-State FSM (`IDLE`, `SETUP`, `ENABLE`)** 을 구현했습니다.
- **IDLE**: AHB 마스터의 유효한 전송 요청(`HSEL` & `HTRANS`)을 대기. 유효 요청 시 주소와 제어 신호를 래치(Latch)하고 `SETUP`으로 천이.
- **SETUP**: APB 전송을 시작하기 위해 `PSEL`을 활성화. 이때 AHB 마스터에게는 **Wait State (`HREADYout=0`)** 를 주어 데이터 동기화 시간을 확보.
- **ENABLE**: `PENABLE`을 활성화하여 실제 데이터 전송 수행. APB 슬레이브의 응답(`PREADY`)을 확인하여 트랜잭션 완료 또는 대기.

### 2. 신호 동기화 및 제어 (Signal Control)
- **Wait State Generation**: APB는 Setup과 Access, 최소 2클럭이 필요하므로 AHB 측에 `HREADYout` 신호를 제어하여 마스터를 일시 정지시키는 로직 구현.
- **Address Decoding**: `0x8000` ~ `0x803C` 범위의 주소를 타겟으로 하는 **Memory Mapped I/O** 디코딩 로직 구현 (`ApbIfBlk.v`).
- **Data Latching**: AHB의 Address Phase 정보를 저장하여 APB의 Data Phase에 안정적으로 전달하기 위한 레지스터 로직.

### 3. APB Slave & Memory Interface
- **SP-SRAM Controller**: APB 프로토콜을 싱글 포트 SRAM 인터페이스(`CSn`, `WEn`, `Addr`)로 변환하는 컨트롤러 구현.
- **Zero-Wait Response**: SRAM의 빠른 응답 속도를 고려하여 `PSEL` & `PENABLE` 조건 충족 시 즉시 `PREADY`를 반환하도록 설계.

---

## 🚀 프로젝트 구조 (Labs & Project)
본 프로젝트는 단계별 실습(Lab)을 통해 개념을 익히고 최종 프로젝트를 완성하는 방식으로 진행되었습니다.
- **Labs**: 기본 논리 회로 및 Verilog 문법 실습
- **Project**: AHB-APB Bridge 및 전체 Top 모듈 통합 검증
  - `Ahb2Apb_Top.v`: Bridge 핵심 로직 (FSM 포함)
  - `ApbIfBlk.v`: APB Interface 및 Address Decoder
  - `SpSram16x32.v`: 16x32 Single Port SRAM 모델

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)

### 1. Wait State를 통한 버스 속도 동기화
- **문제상황**: AHB는 파이프라인(Pipeline) 기반으로 매 클럭 주소/데이터 페이즈가 진행되는 반면, APB는 `SETUP` -> `ACCESS`의 최소 2클럭주기가 필요했습니다. 이로 인해 AHB 마스터가 APB의 처리 속도를 넘어서는 요청을 보낼 경우 데이터 손실(Data Loss) 발생 가능성이 있었습니다.
- **해결방안**:
  - `Ahb2Apb_Top.v`의 **FSM** 설계 시 `SETUP` 상태에서 강제로 `HREADYout = 0`을 출력하여 AHB 마스터를 **Stall(대기)** 시키는 로직을 구현했습니다.
  - `ENABLE` 상태에서는 APB 슬레이브의 완료 신호(`PREADY`)를 그대로 AHB로 전달(`Bypass`)하여, 슬레이브가 준비될 때까지 마스터가 대기하도록 동기화를 완벽하게 수행했습니다.

### 2. 파이프라인 프로토콜 간 데이터 무결성 보장
- **문제상황**: AHB 프로토콜은 주소 페이즈(Address Phase)와 데이터 페이즈(Data Phase)가 겹쳐서 들어오는데, APB는 주소와 데이터를 동시에 요구합니다. AHB의 주소 신호는 다음 사이클에 바로 변하므로, 이를 APB에 그대로 연결하면 타이밍 위반이 발생했습니다.
- **해결방안**:
  - **Latching Logic 구현**: AHB의 주소 페이즈가 유효한 시점(`HREADYin=1`)에 주소(`HADDR`)와 제어 신호(`HWRITE`)를 내부 레지스터(`rHADDR`, `rHWRITE`)에 캡처(Capture)하여 저장했습니다.
  - 저장된 레지스터 값을 APB 인터페이스에 연결함으로써, AHB 버스의 상태 변화와 무관하게 APB 트랜잭션 내내 안정적인 신호를 공급했습니다.

### 3. 유효 주소 필터링 (Address Decoding)
- **문제상황**: APB 버스에 연결된 SRAM의 주소 영역(`0x8000` ~ `0x803C`) 이외의 잘못된 접근 요청이 들어올 경우, 오동작하거나 버스 에러가 발생할 수 있었습니다.
- **해결방안**:
  - `ApbIfBlk.v` 모듈 내에 **Address Decoder**를 구현했습니다.
  - 입력 주소가 `BASE_ADDR`와 `END_ADDR` 사이에 있는 경우에만 `ADDRInRANGE` 신호를 활성화하고, 이 신호가 유효할 때만 SRAM의 `Chip Select (CSn)`와 `Write Enable (WEn)`이 동작하도록 안전장치를 마련했습니다.

---

## 📚 배운점 및 성과
- **타이밍 다이어그램 해석 능력**: AMBA 규격 문서를 통해 `SETUP`, `ACCESS` 페이즈의 정확한 타이밍 요건을 파악하고 코드로 구현.
- **Cross-Domain 설계 경험**: 고속 도메인(AHB)과 저속 도메인(APB) 간의 핸드셰이킹 메커니즘을 FSM으로 제어하며 시스템 안정성 확보.
- **SoC 아키텍처 이해**: 마스터-슬레이브 구조와 주소 디코딩, 메모리 맵(Memory Map) 설계의 중요성 체득.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)**
  - `RTL/Src`: Bridge, APB Interface, Top 모듈 소스 코드
  - `Testbench`: 시뮬레이션 검증 환경
- **[📂 Report](./Report)**
  - `[HDD] AHB to APB_...`: 상세 설계 과정 및 파형 분석 결과 보고서
