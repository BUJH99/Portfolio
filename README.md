# 📟 Embedded & Semiconductor Engineering Portfolio

RTL 기반 SoC·하드웨어 가속기 설계, UVM 검증, 임베디드 시스템 구현 프로젝트를 정리한 포트폴리오입니다.

## 📂 Projects

### 🌟 RTL & SoC Design

| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[RISC-V SoC](./RISC_V_SoC)** | RV32I 5단계 파이프라인 CPU와 버스·주변장치·펌웨어를 통합한 SoC 설계 | `SystemVerilog`, `RISC-V`, `AXI4-Lite / APB`, `Embedded C` |
| **[Softmax Accelerator IP](./Softmax_Accelerator_IP)** 🏆 | 하드웨어 친화적 Softmax 알고리즘 구현, **경진대회 우수상** | `Verilog`, `AXI4-Stream`, `SystemVerilog TB` |
| **[AMBA AHB-APB Bridge](./AMBA_Bus_Bridge)** | AHB–APB 프로토콜 변환과 전송 제어를 수행하는 Bridge IP 설계 및 검증 | `Verilog`, `AHB / APB`, `FSM` |
| **[FPGA FFT Calculator](./FPGA_FFT_Calculator)** | 8-point FFT 연산과 키패드 입력·결과 표시를 통합한 FPGA 계산기 구현 | `SystemVerilog`, `FFT`, `FSM` |
| **[FPGA Image Filtering](./FPGA_Image_Filtering)** | 카메라 영상 입력·3×3 Convolution 필터링·LCD 출력 파이프라인 구현 | `SystemVerilog`, `Convolution`, `BRAM` |
| **[FPGA Sensor Hub](./FPGA_Sensor_Hub)** | 초음파·온습도 센서 계측과 UART 통신·FND 표시를 통합한 센서 허브 구현 | `Verilog`, `UART`, `FSM` |

### 🧪 Verification & Protocol

| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[SPI / I2C Multi-Agent UVM](./UVM_SPI_I2C)** | 독립 SPI·I2C Agent와 Virtual Sequence 기반 멀티에이전트 UVM 검증 환경 구현 | `SystemVerilog`, `UVM 1.2`, `SVA` |
| **[FIFO UVM](./UVM_FIFO)** | FIFO 데이터 순서·경계 조건·동시 읽기/쓰기를 검증하는 UVM 테스트벤치 구현 | `SystemVerilog`, `UVM 1.2`, `SVA` |
| **[UVM / AXI4 Seminars](./Primemas_Internship)** | SPEC 기반 UVM 검증 구조 ·AXI4 Protocol 정리 | `UVM`, `AXI4`, `Documentation` |

### 🛠 Embedded & Applications

| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[MCU Register Control](./MCU_Control)** | AVR 레지스터 직접 제어 기반 센서·모터·LED·통신 펌웨어 구현 | `Embedded C`, `AVR`, `UART / SPI` |
| **[AGV Parking System](./AGV_Parking_System)** 🏆 | 다중 AGV의 경로 탐색·충돌 회피·교착 상태 처리를 구현한 주차 시뮬레이터, **형남과학상 동상** | `C++20`, `Electron`, `Path Planning` |
| **[터치식 리듬게임](./Touch_Rhythm_Game)** | 4레인 노트·타이밍 판정·콤보·Fever를 구현한 리듬게임 | `Python`, `pygame-ce` |

### 🔬 Circuit & Process Design

| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[Virtuoso 4-bit ALU](./Virtuoso_4bit_ALU)** | CMOS 트랜지스터 기반 논리 게이트·산술 연산 회로와 4-bit ALU 설계 | `Virtuoso`, `ADE`, `CMOS` |
| **[Elevator PCB Design](./Elevator_Circuit_PCB)** | 엘리베이터 제어 회로 분석·시뮬레이션 및 PCB 제작 | `OrCAD`, `Discrete Logic`, `PCB` |
| **[Semiconductor Process](./Semiconductor_Display_Process)** | CMOS LDO 회로의 제조 공정 흐름과 소자 단면 설계 | `CMOS`, `Process Integration` |

### ⚙️ Automation & Learning Tools

| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[FPGAClaw](./FPGA_Automation)** | FPGA 시뮬레이션·합성·구현·보고서 생성을 연결하는 개발 자동화 도구 | `BAT`, `Python`, `Tcl` |
| **[ChipBook](./ChipBook)** | 디지털 회로·반도체 설계 개념을 도식과 문제 풀이로 정리한 웹 가이드북 | `HTML`, `CSS`, `JavaScript` |

## 🛠 Tech Stack

### RTL & SoC

![Verilog](https://img.shields.io/badge/Verilog-HDL-1F6FEB?style=flat-square)
![SystemVerilog](https://img.shields.io/badge/SystemVerilog-RTL-1F6FEB?style=flat-square)
![Vivado](https://img.shields.io/badge/Vivado-FPGA-E31837?style=flat-square)

### Verification

![UVM 1.2](https://img.shields.io/badge/UVM-1.2-6F42C1?style=flat-square)
![SVA](https://img.shields.io/badge/SVA-Assertions-6F42C1?style=flat-square)
![XSim](https://img.shields.io/badge/XSim-Simulation-6F42C1?style=flat-square)
![ModelSim](https://img.shields.io/badge/ModelSim-Simulation-6F42C1?style=flat-square)

### Firmware

![Embedded C](https://img.shields.io/badge/C-Embedded-00599C?style=flat-square&logo=c&logoColor=white)
![AVR](https://img.shields.io/badge/AVR-MCU-00979D?style=flat-square)
![GPIO / ADC / Timer](https://img.shields.io/badge/GPIO%20%2F%20ADC%20%2F%20Timer-Peripherals-00979D?style=flat-square)
![UART / SPI / I2C](https://img.shields.io/badge/UART%20%2F%20SPI%20%2F%20I2C-Interfaces-00979D?style=flat-square)

### Circuit Design

![Cadence Virtuoso](https://img.shields.io/badge/Cadence-Virtuoso-111111?style=flat-square)
![ADE](https://img.shields.io/badge/ADE-Simulation-111111?style=flat-square)
![OrCAD](https://img.shields.io/badge/OrCAD-PCB-22863A?style=flat-square)

### Software & Automation

![C++20](https://img.shields.io/badge/C%2B%2B-20-00599C?style=flat-square&logo=cplusplus&logoColor=white)
![Python](https://img.shields.io/badge/Python-Scripting-3776AB?style=flat-square&logo=python&logoColor=white)
![BAT](https://img.shields.io/badge/BAT-Windows-4D4D4D?style=flat-square)
![Tcl](https://img.shields.io/badge/Tcl-Automation-E4A62A?style=flat-square)
![CMake](https://img.shields.io/badge/CMake-Build-064F8C?style=flat-square&logo=cmake&logoColor=white)

### UI & Web

![HTML](https://img.shields.io/badge/HTML-Web-E34F26?style=flat-square&logo=html5&logoColor=white)
![CSS](https://img.shields.io/badge/CSS-Style-663399?style=flat-square&logo=css&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Web-F7DF1E?style=flat-square&logo=javascript&logoColor=black)
![Electron](https://img.shields.io/badge/Electron-Desktop-47848F?style=flat-square&logo=electron&logoColor=white)
![pygame-ce](https://img.shields.io/badge/pygame--ce-Game-3776AB?style=flat-square)

## 📫 Contact

**Email**: [eddlle15@gmail.com](mailto:eddlle15@gmail.com)
