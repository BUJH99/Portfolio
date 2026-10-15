# 실행과 범위

```powershell
python tools/run_xsim.py FPGA_Sensor_Hub/tests.json --vivado-bin "$env:VIVADO_BIN"
```

실제 RTL 최상위 이름은 `TOP`이다. 원본 manifest의 `Top` 표기를 그대로 사용하지 않았다. `src/filelist.f`는 프로젝트 루트 기준 상대 경로이며, 테스트 matrix가 전체 RTL과 `tb/TbTop.sv`를 컴파일한다.

새 smoke TB는 1 MHz로 파라미터를 설정해 센서의 μs 시간을 직접 재현한다. HC-SR04 정상 echo와 timeout, DHT11 정상 프레임과 checksum 오류, UART 수신, BCD 조합 변환, TOP idle 출력을 검사한다. 전체 버튼 동작·시계/스톱워치 상태 공간, 실제 센서 노이즈와 보드 timing은 이 시험 범위 밖이다. 하드웨어 재현에는 사용하는 보드의 핀·전압·clock 제약이 추가로 필요하다.
