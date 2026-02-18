# 🚙 C기반 AGV 활용 무인 주차장 시스템 (AGV Automated Parking System)



## 📅 프로젝트 정보
- **진행 기간**: 2025.03.01 ~ 2025.12.05
- **수 상**: 🏆 **형남과학상 동상**
- **기술 스택**: `C Language`, `Pathfinding (D* Lite, WHCA*, CBS)`, `Real-time Simulation`, `WinAPI`

---

## 📝 프로젝트 개요
AGV(Automated Guided Vehicle)를 이용한 스마트 무인 주차장 시스템을 시뮬레이션으로 구현했습니다. 객체지향 언어(C++)의 STL이나 라이브러리 지원 없이 **Pure C언어**만으로 복잡한 다개체 경로 탐색 알고리즘과 자료구조를 직접 구현하여 CS 기초를 다졌습니다.

## 🔑 주요 기능 및 알고리즘
### 1. 고급 경로 탐색 알고리즘 구현
본 프로젝트는 단일 알고리즘이 아닌, 상황에 맞춰 최적의 경로를 찾기 위해 다양한 기법을 통합했습니다.
- **WHCA* (Windowed Hierarchical Cooperative A*)**: 시간 축(Time-dimension)을 포함한 3차원(x, y, t) 예약 테이블을 사용하여 에이전트 간의 경로 충돌을 사전에 방지.
- **D* Lite**: 동적 환경에서 장애물이 발견되었을 때 전체 경로를 다시 계산하지 않고 변경된 부분만 효율적으로 갱신하는 증분 탐색 알고리즘.
- **Partial CBS (Conflict-Based Search)**: 다수의 에이전트가 밀집된 병목 구간에서 발생하는 복잡한 충돌을 해결하기 위한 상위 레벨 탐색 기법.
- **SCC (Strongly Connected Components)**: 대기 그래프(Wait-for Graph)를 구성하고 강한 연결 요소를 찾아 교착 상태(Deadlock)를 감지 및 순환 대기 해소.

### 2. 시뮬레이션 시스템 아키텍처
- **Interactive Control**: 실시간 일시정지, 스텝 실행, 속도 조절(최대 100배속), 렌더링 스킵 기능 지원.
- **Map Scenarios**: 5가지 맵(기본, 스트레스 테스트 등)을 통해 다양한 상황에서의 알고리즘 성능 검증.
- **Real-time Metrics**: CPU 사용 시간, 메모리 사용량, 알고리즘 연산 횟수(힙 이동, 노드 확장 등)를 실시간으로 프로파일링하여 대시보드에 출력.

### 3. 자료구조 최적화 (C언어)
- **Custom Priority Queue**: 힙(Heap) 자료구조를 직접 구현하여 D* Lite와 A*의 Open List 관리.
- **Memory Management**: 정적/동적 할당을 효율적으로 관리하며 `Display Buffer`등을 활용한 화면 깜빡임 방지(Double Buffering 유사 기법) 구현.

---

## 🚀 직면한 어려움 및 해결 (Troubleshooting)
### 1. 교착 상태 (Deadlock) 해결
- **문제**: 좁은 통로에서 여러 AGV가 서로 마주보거나 순환 대기(Cycle)에 빠지는 현상 발생.
- **해결**: **WFG(Wait-for Graph)** 를 구축하여 에이전트 간의 대기 관계를 모델링하고, **Tarjan's Algorithm** 등을 변형하여 사이클을 감지. 우선순위가 낮은 에이전트가 회피하거나 대기하도록 스케줄링하여 해결.

### 2. 연산 속도와 실시간성
- **문제**: 에이전트 수가 늘어날수록 경로 탐색 연산량이 기하급수적으로 증가하여 시뮬레이션 렉 발생.
- **해결**: **WHCA*의 Window Size(Horizon)** 를 동적으로 조절하는 기법 도입. 충돌이 빈번한 지역에서는 Window를 줄여 반응성을 높이고, 한산한 지역에서는 늘려 장기적인 경로 최적화 수행.

### 3. C언어의 제약 (No STL)
- **문제**: `std::vector`, `std::queue` 등 편의 기능 부재.
- **해결**: 연결 리스트(Linked List)와 환형 버퍼(Circular Buffer) 등 필요한 자료구조를 직접 구현. 이 과정에서 포인터와 메모리 구조에 대한 깊은 이해 획득.

---

## 📚 배운점 및 성과
- **알고리즘 구현력**: 논문으로만 접하던 D* Lite, CBS 같은 심화 알고리즘을 코드로 직접 옮기며 구현 능력 배양.
- **시스템 프로그래밍**: Windows API를 활용한 콘솔 제어, 고정밀 타이머 활용 등 시스템 레벨의 프로그래밍 경험.
- **성능 최적화**: 프로파일링 데이터를 기반으로 병목 지점을 찾고, 캐시 적중률 등을 고려한 데이터 구조 배치 고민.

---

## 📂 포트폴리오 목차
- **[📂 Source Code](./Source_Code)**
  - `AGV.c`: 시뮬레이터 전체 소스 코드 (약 5,000라인, 알고리즘/UI/로직 통합)
- **[📂 Presentation](./Presentation)**
  - `AGV Algorithm_발표자료.pdf`: 프로젝트 상세 발표 슬라이드
- **[📂 Thesis](./Thesis)**
  - `졸업논문_한정호.pdf`: 알고리즘 이론 배경 및 성능 평가 상세 논문
