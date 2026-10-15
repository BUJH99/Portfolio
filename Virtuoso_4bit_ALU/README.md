# 📐 Virtuoso 트랜지스터 수준 ALU 설계

## 📅 프로젝트 정보

- **수행**: 2025년 · 보고서 제출일 2025.06.19
- **도구**: `Cadence Virtuoso` · `ADE` · `Transient Simulation`
- **구성**: 기본 CMOS 논리 게이트 → Full Adder·MUX → 1-bit ALU → 4-bit 확장

## 🔑 확인 가능한 설계 내용

- PMOS/NMOS 사이징을 적용한 Inverter·AND·OR·XOR 회로
- 2×1·4×1 MUX와 Full Adder를 이용한 산술·논리 경로 구성
- 1-bit ALU 연산별 과도응답 파형과 진리표 비교
- 1-bit ALU 4개를 연결한 4-bit 확장 회로

## 📂 원문 근거

- [최종 보고서](./Report/아날로그레이아웃TermProject.pdf)
- PDF **4쪽**: PMOS/NMOS 폭 비율과 **최소 L=50 nm** 설정
- PDF **8~9쪽**: XOR 회로와 파형 · **14~20쪽**: Full Adder·Logic·ALU 검증 · **21쪽**: 4-bit 확장

현재 공개 PDF는 회로도와 시뮬레이션 근거입니다. 정확한 PDK 버전, XOR 12T→6T 개선, DRC/LVS/PEX 결과는 이 PDF에서 확인되지 않아 성과 수치로 기재하지 않습니다. 기존 문서 원문은 보존했습니다.
