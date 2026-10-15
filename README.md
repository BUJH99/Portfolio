# 📟 Embedded & Semiconductor Engineering Portfolio

---

## 🛠 Tech Stack

### FPGA & Digital Design
![Verilog](https://img.shields.io/badge/Verilog-HDL-blue?style=flat-square&logo=verilog) 
![Vivado](https://img.shields.io/badge/Xilinx-Vivado-red?style=flat-square&logo=xilinx)
![Virtuoso](https://img.shields.io/badge/Cadence-Virtuoso-000000?style=flat-square&logo=cadence)

### Firmware & Embedded
![C](https://img.shields.io/badge/C-Language-blue?style=flat-square&logo=c)
![ARM](https://img.shields.io/badge/ARM-Cortex-0091BD?style=flat-square&logo=arm)
![Arduino](https://img.shields.io/badge/Arduino-Platform-00979D?style=flat-square&logo=arduino)

### Tools & Others
![OrCAD](https://img.shields.io/badge/OrCAD-PCB-green?style=flat-square)
![Matlab](https://img.shields.io/badge/MATLAB-Simulink-orange?style=flat-square&logo=mathworks)
![Python](https://img.shields.io/badge/Python-Scripting-3776AB?style=flat-square&logo=python)

---

## 📂 Projects

### 🌟 Digital Logic & SoC Design
| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[RISC-V SoC](./RISC_V_SoC)** | Basys3 RV32I 5-stage, UART InstDMA, AXI4-Lite–APB 및 펌웨어 연동 검증 | `SystemVerilog`, `RISC-V`, `C` |
| **[Softmax Accelerator IP](./Softmax_Accelerator_IP)** 🏆 | FP32 스트림 가속기, 포맷 계약·참조 모델 통합, **경진대회 우수상** | `Verilog`, `AXI-Stream`, `SV TB` |
| **[SPI / I2C Multi-Agent UVM](./UVM_SPI_I2C)** | 독립 SPI·I2C Agent, Virtual Sequence, wire-level Scoreboard 및 4개 topology·20회 회귀 검증 | `SystemVerilog`, `UVM 1.2`, `SVA`, `XSim` |
| **[FIFO UVM](./UVM_FIFO)** | 경계 조건·랜덤 명령, 실제 수락 기반 Scoreboard와 3-seed 회귀 | `SystemVerilog`, `UVM 1.2`, `SVA` |
| **[AMBA AHB-APB Bridge](./AMBA_Bus_Bridge)** | AHB-APB 버스 브리지 IP 설계 및 검증 | `Verilog`, `AMBA`, `FSM` |
| **[FPGA FFT Calculator](./FPGA_FFT_Calculator)** | 21-bit 입력·32-bit 연산의 8-point FFT와 키패드·표시 제어 | `SystemVerilog`, `DSP` |
| **[FPGA Image Filtering](./FPGA_Image_Filtering)** | 두 줄 Line Buffer로 입력 BRAM 읽기 감소 및 코어 처리량 개선 | `SystemVerilog`, `Image Processing`, `BRAM` |
| **[FPGA Sensor Hub](./FPGA_Sensor_Hub)** | HC-SR04·DHT11·UART·FND 통합 RTL과 센서 smoke 검증 | `Verilog`, `Sensors`, `XSim` |
| **[Virtuoso 4-bit ALU](./Virtuoso_4bit_ALU)** | 트랜지스터 수준 게이트·1-bit ALU 설계와 4-bit 확장 | `Virtuoso`, `ADE` |

### 🛠 Embedded System & Firmware
| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[MCU Register Control](./MCU_Control)** | 라이브러리 없는 Bare-metal 펌웨어 개발 | `Embedded C`, `AVR/ARM` |
| **[AGV Parking System](./AGV_Parking_System)** 🏆 | C++ 엔진·Electron UI로 개선한 다개체 AGV 시뮬레이터, **형남과학상 동상** | `C++20`, `Electron`, `Algorithm` |
| **[Elevator PCB Design](./Elevator_Circuit_PCB)** | 엘리베이터 제어 회로 설계 및 PCB 제작 | `OrCAD`, `PCB` |
| **[터치식 리듬게임](./Touch_Rhythm_Game)** | 4레인 노트·타이밍 판정·콤보·Fever를 구현한 리듬게임 | `Python`, `Pygame` |

### 🧪 Process & Others
| Project | Description | Tech Stack |
| :--- | :--- | :--- |
| **[Semiconductor Process](./Semiconductor_Display_Process)** | CMOS LDO 공정 흐름(Process Flow) 설계 | `Process Integration` |
| **[FPGAClaw](./FPGA_Automation)** | Manifest 기반 FPGA 시뮬레이션·빌드·보고서 자동화 | `BAT`, `Python`, `Tcl` |
| **[ChipBook](./ChipBook)** | 반도체 설계 개념·도식·문제 풀이 웹 가이드북 | `HTML`, `CSS`, `JavaScript` |
| **[UVM / AXI4 Seminars](./Primemas_Internship)** | 인턴십 기술 세미나 학습 요약과 참고 자료 | `UVM`, `AXI4`, `Documentation` |
