# 실행과 근거

```powershell
python tools/run_xsim.py FPGA_FFT_Calculator/Code/tests.json --vivado-bin "$env:VIVADO_BIN"
```

2026-10-15 XSim 2025.2 실행에서 `TB_PASS`를 확인했다. 테스트는 FFT 5개 벡터의 실수·허수 8개 bin, BCD 4개 입력, TOP reset/idle 출력을 확인한다. 전체 실수 입력 공간이나 새 보드 구현의 timing sign-off를 의미하지 않는다.

`FFT8DifDatapath`의 3단계는 조합 논리 계산 단계다. 매 단계가 레지스터로 분리된 3단 파이프라인으로 기술하지 않는다. `FFT8InputLatch`, `FFT8OutputLatch`가 경계 레지스터다.

최종 PDF 1쪽에 제출일 2025-12-11, 3쪽에 역할 분담이 있다. 한정호 담당은 UI FSM·키패드 디바운싱/디코딩·7-Segment·BCD 변환이다. FFT 코어와 top 통합의 원래 팀 담당은 전민서로 기재되어 있다. PDF 17쪽의 LUT·WNS는 당시 구현 결과이며 이번 SystemVerilog 이관 후 새 합성 결과로 재사용하지 않는다.

원본 관리 manifest의 Ultra96v2 값은 이 계산기의 JFK-200A 실습 보드 설명과 일치하지 않아 그대로 복사하지 않았다. 보존한 XDC는 JFK 계열 핀 배치이며, 이관 검증은 보드에 독립적인 RTL 시뮬레이션이다.
