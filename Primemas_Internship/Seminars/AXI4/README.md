# 🔌 AXI4 세미나

## 📝 설명한 내용

- **5개 독립 채널**: AW·W·B·AR·R의 역할과 read/write transaction 흐름
- **VALID/READY**: 수락 시점, payload 유지, 채널 사이의 의존성
- **Burst와 순서**: 전송 속성, ID·응답·ordering의 관계
- **Memory attribute**: bufferable·cacheable 등 속성이 의미하는 접근 조건
- **Exclusive access**: read/write 쌍과 성공·실패 응답의 의미

![채널과 interconnect](./images/axi-channel-interconnect.svg)

*기존 채널 구조 PNG를 재구성한 참고 도식입니다. 원저작자는 확인되지 않았습니다.*

## 📂 참고 도식·문헌

- [Handshake 의존성](./images/axi-handshake-dependencies.svg)
- [Memory attributes](./images/axi-memory-attributes.svg)
- [Exclusive access: Arm IHI 0022H §A7.2](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf#page=96)
- [SoC AXI4-Lite–APB 적용](../../../RISC_V_SoC)

그림은 기존 자료를 재구성한 참고 도식입니다. [이미지 출처와 참고 문헌](../../SOURCE_VERSION.md)에 파일 유래와 사양서 근거를 구분해 표기했습니다. 세미나의 범위와 실제 SoC에서 구현한 AXI4-Lite 범위도 구분합니다.
