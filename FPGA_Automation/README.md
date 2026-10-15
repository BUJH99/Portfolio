# 🛠️ FPGAClaw · FPGA Automation Toolkit

## 📝 프로젝트 개요

프로젝트 선택부터 시뮬레이션·Vivado 빌드·보고서 확인까지 Windows 메뉴와 manifest로 연결한 FPGA 개발 자동화 도구입니다.

## 🔑 주요 구현

- `fpga_auto.yml` 기반 프로젝트 검색과 TOP·소스·TB·제약 설정
- XSim 실행, 합성·구현·bitstream, 계층 분석과 HTML 보고서 생성
- 공통 BAT·Python·Tcl 도구와 simulation/reporting/vivado 영역 분리
- Telegram 연동을 통한 원격 상태 확인과 작업 조작

![프로젝트 선택 및 실행 화면](./docs/images/FPGAClaw_UI.png)

## 📂 코드와 자료

- [원본 저장소](https://github.com/BUJH99/FPGA_Auto_Project) · [예제 manifest](./examples/fpga_auto.yml)
- [홈·도움말·모바일 화면](./docs/images) · [선정 범위](./SOURCE_VERSION.md)

이 폴더는 소개·설정 예시·화면 자료를 제공하며, 실행 프레임워크는 원본 저장소에서 관리합니다.
