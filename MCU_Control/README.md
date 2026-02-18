# ⚙️ 레지스터 기반 MCU 제어 (Register-based MCU Control)

## 📅 프로젝트 정보
- **진행 기간**: 2024.09.01 ~ 2024.11.22
- **기술 스택**: `AVR/ARM MCU`, `Embedded C`, `Datasheet Analysis`

---

## 📝 프로젝트 개요
라이브러리를 사용하지 않고 **Datasheet** 분석을 통해 MCU의 레지스터를 직접 제어하는 **Bare-metal 펌웨어**를 개발한 프로젝트입니다.

## 🔑 주요 구현 내용
### 1. Low-Level Firmware 개발
- **Peripheral Control**: GPIO, PWM, Timer/Counter 등 주변장치를 레지스터 단위에서 설정 및 제어.
- **Interrupt Handling**: 외부 인터럽트 및 타이머 인터럽트를 활용한 효율적인 이벤트 처리.

### 2. 시스템 최적화
- **Scheduling**: 초기 Polling 방식에서 Interrupt 기반 방식으로 변경하여 실시간성 확보.
- **Reverse Engineering**: 오실로스코프로 외부 신호를 분석하고 이를 MCU로 모사하여 통신 프로토콜 구현.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. Polling 방식의 한계
- **문제**: 단일 루프에서 모든 센서를 Polling하여 처리 속도 저하 및 반응 지연 발생.
- **해결**: 긴급한 센서 감지는 인터럽트(ISR)로 처리하고 일반 작업은 메인 루프에서 처리하도록 구조 개선.

### 2. 하드웨어 자원 제약
- **문제**: 제한된 핀 개수로 인한 회로 구성의 어려움.
- **해결**: 핀 멀티플렉싱(Multiplexing) 및 회로 간소화를 통해 가용 자원 효율화.

### 3. 타이밍 동기화
- **문제**: 클럭 설정 오류로 인한 통신 타이밍 불일치.
- **해결**: Datasheet의 Clock Tree를 분석하여 Prescaler를 정확히 재설정하고 안정적인 타이밍 확보.

---

## 📚 배운점
- **Datasheet 분석**: 기술 문서를 독해하여 하드웨어 제어에 필요한 레지스터 정보를 추출하는 능력.
- **임베디드 기초**: 라이브러리 내부의 실제 동작 원리(Interrupt, Memory Map 등) 이해.
- **하드웨어 디버깅**: 오실로스코프 등 계측 장비를 활용한 신호 분석 및 문제 해결.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : C언어 펌웨어 소스
- **[📂 Presentation](./Presentation)** : 발표 자료
