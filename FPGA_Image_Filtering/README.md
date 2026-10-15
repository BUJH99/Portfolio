# 🖼️ FPGA 영상 필터링 · Line Buffer 개선

## 📅 프로젝트 정보

- **수행**: 2025.10 ~ 2025.12 · 2026년 RTL 개선
- **구성**: OV5640 카메라, RGB565/RGB888 변환, 3×3 필터, 프레임 버퍼, TFT-LCD
- **기술**: `SystemVerilog` · `Vivado / XSim 2025.2` · `BRAM`

## 📝 프로젝트 개요

카메라 영상의 3×3 윈도우를 만드는 경로를 두 줄의 Line Buffer로 개선했습니다. 현재 정식 코드는 `Code/Source`에 있으며, 기존 설계 보고서와 결과 이미지를 함께 보존했습니다.

## ✅ 핵심 성과

| 480×272 · 100 MHz | 기존 윈도우 | Line Buffer |
| :--- | ---: | ---: |
| 입력 BRAM 읽기 | 390,720회 | **130,560회** |
| 출력 구간 | 1,042,968 cycles | **130,560 cycles** |
| 코어 처리량 | 12.518 MPixel/s | **100.000 MPixel/s** |

- 130,560개 윈도우를 zero-padding 참조 모델과 비교해 일치 확인
- Bypass·Sharpen·Edge Enhance·Emboss의 8개 통합 처리량 시나리오 완료
- Line Buffer OOC 합성 완료: 10 ns 제약에서 추정 WNS **8.332 ns**

처리량 개선은 **시뮬레이션 코어 기준 약 7.988배**입니다. 카메라 스트림의 프레임 준비·재시작 제어와 LCD 영상 정합성은 별도 보완 범위이며, 보드 FPS 향상으로 환산하지 않습니다.

## 📂 코드와 검증

- [RTL](./Code/Source) · [테스트벤치](./Code/TestBench) · [실행 및 검증 범위](./docs/verification.md)
- [새 실행 결과](./Report/verification_2026-10-15/summary.json) · [성능 보고서](./Report/PERFORMANCE_BENCHMARK_REPORT.md)
- [기존 보고서·이미지](./Report) · [소스 이관 기록](./SOURCE_VERSION.md)
