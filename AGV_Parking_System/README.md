# 🚙 AGV 무인 주차장 시뮬레이터

## 📅 프로젝트 정보

- **수행**: 2025.03 ~ 2025.12 · **형남과학상 동상**
- **현재 구현**: `C++20` · `CMake` · `GoogleTest` · `Electron`

## 📝 프로젝트 개요

다수의 AGV가 입·출차 작업을 수행하는 주차장 시뮬레이터입니다. 기존 C 구현의 경로 탐색·충돌 회피 기능을 C++ 엔진과 Electron 화면으로 분리한 개선 코드를 정식 `Source_Code`에 반영했습니다.

## ✅ 주요 구현과 검증

- A*·D* 계열 경로 탐색, 예약 기반 충돌 처리, 교착 상태·충전·복귀 상태 관리
- 엔진 API와 콘솔·JSON IPC 화면 경로 분리, 세션과 프레임 delta 전달
- 주차·출차·반복 세션·로그·화면 데이터·코드 경계 검사 **61 / 61 PASS**
- Windows · GCC 15.2.0 · Release 빌드에서 검증

## 📂 실행과 자료

- [현재 소스](./Source_Code) · [실행 및 테스트](./docs/running.md) · [검증 결과](./results/2026-10-15)
- [논문](./Thesis) · [발표 자료](./Presentation) · [과거 실행 파일](./Source_Code/AGV.exe)
- [원본 저장소](https://github.com/BUJH99/AGV_REFACTORING) · [소스 이관 기록](./SOURCE_VERSION.md)
