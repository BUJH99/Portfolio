# 📟 엘리베이터 회로 설계 및 PCB 제작 (Elevator Circuit PCB)



## 📅 프로젝트 정보
- **주관 및 수강**: 나인ES캠퍼스
- **진행 기간**: 2025.07.14 ~ 2025.07.26
- **기술 스택**: `OrCAD Capture CIS`, `PCB Designer`, `Circuit Design`, `Soldering`

---

## 📝 프로젝트 개요
나인ES캠퍼스에서 주관한 집체 교육을 통해 상용 툴인 **OrCAD**를 활용하여 엘리베이터 제어 회로를 설계하고, 실제 **PCB(Printed Circuit Board)** 로 제작하여 부품 실장(Soldering)까지 완료한 실무형 프로젝트입니다.

## 🔑 주요 기능 및 내용
### 1. 회로도(Schematic) 및 PCB Artwork 설계
- **Capture CIS**: 엘리베이터 동작을 위한 논리 회로 및 전원부, 모터 드라이버 회로 도면 작성.
- **PCB Editor**: 부품 배치(Placement) 및 배선(Routing) 작업을 통해 실제 보드 레이아웃 설계. 노이즈를 최소화하기 위한 Ground Plane 처리.

### 2. 하드웨어 제작 및 디버깅
- **Gerber 파일 생성** 및 PCB 발주 프로세스 이해.
- **Soldering**: 딥(DIP) 부품 및 SMD 부품을 직접 납땜하며 실장 기술 습득.
- **테스트**: 멀티미터 등을 이용한 도통 테스트 및 기능 검증.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 배선 최적화 (Routing Strategy)
- **어려움**: 한정된 양면 기판(2-layer) 공간 내에서 전원선과 신호선이 꼬이지 않게 배선하는 것의 어려움(Auto-router의 한계).
- **해결**: 주요 신호선과 전원선을 우선 수동 배선하고, Via hole을 적절히 활용하여 계층을 이동하며 배선 밀집도 해소.

### 2. 물리적 제작 이슈
- **어려움**: 실제 납땜 시 냉납(Cold joint) 현상이나 브릿지(Bridge) 발생으로 인한 쇼트.
- **해결**: 플럭스(Flux)의 적절한 사용과 인두기 온도 조절 요령을 익혀 수정(Rework) 작업을 수행 및 완료.

---

## 📚 배운점 및 성과
- **EDA 툴 활용 능력**: OrCAD 툴체인 전반에 대한 능숙한 조작 능력 확보.
- **제조 공정 이해**: 설계 파일이 실제 제품(PCB)으로 만들어지기까지의 공정(Drill, Copper Pour, Solder Mask 등) 이해.
- **실무 감각**: 회로 이론이 실제 물리적 기판 위에서 어떻게 적용되는지 체감(임피던스, 열 설계 등).

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)** : OrCAD 설계 파일 프로젝트
- **[📂 Report](./Report)** : 실습 결과 보고서
