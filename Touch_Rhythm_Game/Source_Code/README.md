# 실행

Python 3.13에서 검증했다. 이 폴더에서 다음 명령을 실행한다.

```powershell
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt
.venv/Scripts/python main.py
```

곡 선택은 위·아래 방향키, 시작은 Space, 4개 lane은 D/F/J/K다. 게임 중 Esc로 종료한다. 원본 음원·폰트·이미지는 배포하지 않으며 `demo_assets.py`가 기하학 그래픽, 기본 폰트, 단순한 원본 tone loop와 32-note chart를 생성한다. 사용 권한이 있는 자산을 기존 `font`, `img`, `song`, `note` 경로에 놓으면 해당 파일을 우선 사용한다.

화면과 오디오 장치 없이 실행 검증:

```powershell
.venv/Scripts/python main.py --headless --smoke-test --screenshot demo.png
```

smoke 모드는 자동 시작과 시험용 키 이벤트를 발생시키고 300개 게임 프레임 후 결과 JSON을 출력한다. 노트가 로드되고 음악이 시작되며 점수가 증가해야 성공한다. 원본 스케치가 없으므로 Arduino·Serial 의존성을 임의로 추가하지 않았다.
