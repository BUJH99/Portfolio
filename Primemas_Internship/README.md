# 📚 Primemas 인턴십 · 기술 세미나

인턴십에서 학습한 **UVM 검증 방법론**과 **AMBA AXI4 프로토콜**을 공개 사양서에 근거해 정리했습니다. 검증 환경의 구성 원리부터 버스의 전송·응답 규칙까지, 설계와 검증에서 함께 확인해야 할 내용을 다룹니다.

보안상 사내 프로젝트의 소스 코드, 설계 정보, 세미나 원본 자료는 공개하지 않습니다. 이 폴더는 공개 문서에 기반한 설명·표·개념도와 개인 프로젝트 연결로 구성합니다.

## 📝 세미나 구성

| 문서 | 주요 내용 | 학습 초점 |
| --- | --- | --- |
| [UVM 검증 구조와 데이터 흐름](./Seminars/UVM/README.md) | OOP, Test·Env·Agent, Sequence–Driver, phase·factory·configuration, Analysis Port | 자극 생성·신호 구동·관측·검사를 분리하고 재사용 가능한 검증 환경 구성 |
| [AXI4 채널과 트랜잭션 규칙](./Seminars/AXI4/README.md) | 5개 채널, VALID/READY, burst·ID, memory attribute, exclusive access | 채널별 전송 수락과 트랜잭션 완료 조건을 구분하고 검증 항목 도출 |

UVM 문서는 검증 환경 내부의 데이터 흐름을, AXI4 문서는 DUT 인터페이스에서 지켜야 할 규칙을 설명합니다. 두 관점을 연결하면 Monitor가 무엇을 관측하고 Scoreboard가 어떤 순서와 결과를 확인해야 하는지 정리할 수 있습니다.

## 🔗 개인 프로젝트 적용

| 프로젝트 | 연결되는 학습 내용 |
| --- | --- |
| [FIFO UVM 검증](../UVM_FIFO/README.md) | Agent 구성, 관측 transaction, 참조 큐 기반 Scoreboard |
| [SPI / I2C Multi-Agent UVM 검증](../UVM_SPI_I2C/README.md) | 독립 Agent, Virtual Sequence, 복수 인터페이스의 관측·검사 |
| [RISC-V SoC](../RISC_V_SoC/README.md) | AXI4-Lite–APB 연결과 주변장치 레지스터 접근 |

## 📂 기준 문서

- **UVM 1.2**: Accellera [User's Guide](https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf)와 [Class Reference](https://www.accellera.org/images/downloads/standards/uvm/UVM_Class_Reference_Manual_1.2.pdf)를 기준으로 구조와 API 의미를 설명합니다.
- **AMBA AXI4**: Arm [IHI 0022H](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf)의 AXI4 규칙과 [Introduction to AMBA AXI4](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Learn%20the%20Architecture/102202_0100_01_Introduction_to_AMBA_AXI.pdf)를 참고합니다. AXI4-Lite와의 차이는 별도로 정리합니다.

각 세미나 문서의 관련 절에 원문 링크를 표시했습니다. 사양서와 라이브러리 원문은 해당 기관의 공개 문서에서 확인할 수 있습니다.
