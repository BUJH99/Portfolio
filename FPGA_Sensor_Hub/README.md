# 🌡️ FPGA Sensor Hub

## 📝 프로젝트 개요

HC-SR04·DHT11 센서, UART 명령, 시계·스톱워치, 버튼·스위치와 FND 표시를 연결한 Verilog 프로젝트입니다. 관리 중인 RTL 43개를 이관하고 독립 실행용 filelist와 테스트벤치를 추가했습니다.

## ✅ 확인한 동작

- TOP reset·idle 출력 및 **0~9999 BCD 변환 10,000개 입력**
- HC-SR04 10 μs trigger, 거리 변환, echo timeout
- DHT11 40-bit 온습도 수신 및 잘못된 checksum 거부
- UART 2개 바이트 연속 수신
- XSim 2025.2 smoke regression **PASS**

## 📂 코드와 검증

- [RTL](./src) · [테스트벤치](./tb/TbTop.sv) · [실행 결과](./results/2026-10-15/summary.json)
- [실행·검증 범위](./docs/verification.md) · [소스 이관 기록](./SOURCE_VERSION.md)

보드 제약 파일은 확보되지 않아, 현재 공개 범위는 RTL과 시뮬레이션입니다.
