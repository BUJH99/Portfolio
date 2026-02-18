# 🕹️ MCU 기반 임베디드 제어 시스템 (MCU Control System)

## 📅 프로젝트 정보
- **진행 기간**: 2024.09.23 ~ 2024.11.23 (2학년 2학기)
- **대 회 명**: 숭실대학교 MCU 제어 공모전 (자율주행 아님, 임베디드 제어 주제)
- **하드웨어**: `ATmega128 / Arduino`, `Stepper Motor`, `Sensors (ADC)`, `MAX7219`, `WS2812`
- **기술 스택**: `Embedded C`, `AVR-GCC`, `UART/SPI/I2C Communication`, `FSM Control`

---

## 📝 프로젝트 개요
MCU(Micro Controller Unit)의 다양한 주변장치(Peripheral) 제어 능력을 겨루는 공모전으로, **예선(비데 시스템 구현)** 과 **본선(단계별 미션 수행)** 으로 나누어 진행되었습니다.

---

## 🏆 예선: 지능형 스마트 비데 시스템 (Advanced Bidet Control)
### 🔑 주요 구현 내용
- **System Architecture**: 사람이 앉았음을 감지(압력 센서)해야만 동작하는 **안전 루프(Safety Loop)** 구조 설계.
- **Actuator Control**:
    - **Nozzle Moving**: 스텝 모터(Step Motor)의 정밀 제어를 통해 노즐의 전/후진 및 세정/비데 모드 위치 보정 기능 구현 (`motor.h`).
    - **Water Pressure**: 모터 스텝 수에 따라 3단계 수압 조절 로직 구현.
- **Sensor & Output**:
    - **ADC Filtering**: 서미스터(Thermistor)와 압력 센서의 아날로그 값을 안정적으로 수신하기 위한 ADC 필터링.
    - **User Interface**: Shift Register(`74HC595`)를 활용하여 적은 수의 핀으로 다수의 상태 표시 LED 제어.

### 📜 Source Code Checklist
- `main.c`: 착좌 감지 루프 및 버튼 인터럽트 처리.
- `motor.h`: 노즐/수압 모터의 가감속 및 위치 제어 알고리즘.
- `led.h`: Shift Register를 이용한 비트마스킹 LED 제어.

---

## 🏁 본선: 실시간 제어 미션 (Main Tournament)

### 🥇 Round 1: Key Matrix & LED Matrix 제어
- **Mission**: 4x4 키 매트릭스 입력에 따라 8x8 LED 매트릭스(MAX7219)에 패턴 출력.
- **Tech Spec**:
    - **Key Matrix**: 풀업 저항을 활용한 Row/Column 스캐닝 알고리즘 및 디바운싱(Debouncing) 처리.
    - **SPI Telemetry**: MCU와 MAX7219 드라이버 간 **SPI 통신**으로 고속 데이터 전송.

### 🥈 Round 2: MIDI Controller (UART)
- **Mission**: UART 통신을 이용하여 PC의 가상 악기(VST)를 연주하는 MIDI 컨트롤러 제작.
- **Tech Spec**:
    - **MIDI Protocol**: 표준 MIDI 통신 속도인 **31,250 bps**로 UART 보율(Baud Rate) 설정.
    - **Message Format**: Note ON(`0x90`) / Note OFF(`0x80`) 패킷 구조에 맞춰 3-Byte 데이터(Status, Note, Velocity) 송신.
    - **Logic**: 수신된 데이터를 파싱하여 즉각적으로 MIDI 신호로 변환하여 악기 소리 출력.

### 🥉 Round 3: WS2812 & System Integration
- **Mission**: 키 입력과 UART 통신을 결합하여 Addressable LED(WS2812, Neopixel) 색상 및 패턴 제어.
- **Tech Spec**:
    - **Timing Critical**: WS2812의 엄격한 타이밍 프로토콜(800kHz)을 준수하기 위해 인라인 어셈블리 또는 최적화된 C코드로 신호 생성.
    - **Color Mixing**: RGB 24-bit 데이터를 조작하여 다양한 컬러 패턴 디스플레이.

---

## 🚀 문제 해결 (Troubleshooting)
### 1. Shift Register 타이밍 동기화
- **문제**: LED 제어 시 데이터 래치(Latch) 타이밍이 맞지 않아 오작동 발생.
- **해결**: 데이터 시프트(Shift)와 스토리지 래치(Storage Latch) 클럭 사이의 미세한 딜레이를 오실로스코프로 분석하여 최적의 타이밍 코드 구현 (`led.h`).

### 2. 가변적인 입력 신호 처리 (ADC)
- **문제**: 압력 센서 값이 흔들려(Fluctuation) 착좌 상태가 불안정하게 감지됨.
- **해결**: 이동 평균 필터(Moving Average Filter)를 소프트웨어적으로 구현하여 노이즈를 제거하고 안정적인 판단 로직 확보.

### 3. MIDI 통신 속도 불일치
- **문제**: 일반적인 9600/115200 bps가 아닌 31250 bps 설정 시 오차 발생.
- **해결**: AVR의 `UBRR` 레지스터 값을 데이터시트 공식에 맞춰 정밀 계산하고, 16MHz 외부 클럭 기준으로 오차율 0% 달성.

---

## 📚 배운점
- **Low-Level Control**: 라이브러리에 의존하지 않고 레지스터(Register)를 직접 조작(DDR, PORT, UBRR, SPDR 등)하며 하드웨어 제어의 본질 이해.
- **Wait-Free Logic**: `delay()` 함수 사용을 지양하고 타이머 인터럽트를 활용한 비차단(Non-blocking) 구조의 중요성 체득.
- **Protocol Mastering**: UART, SPI, I2C 등 다양한 통신 규격을 직접 구현하며 데이터시트 분석 능력 향상.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : C언어 펌웨어 소스
- **[📂 Presentation](./Presentation)** : 발표 자료
