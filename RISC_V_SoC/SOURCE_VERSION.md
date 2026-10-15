# 소스와 자료의 기준

원본: [KCCI_SeoulTech](https://github.com/BUJH99/KCCI_SeoulTech)의 고정 커밋 `69519d6d2e943f5afc5ad1fabfbcb92b900d8f54`. `RISCV_RV32I_5STAGE`와 같은 커밋의 `SLVAE_BUBBLE/src`에서 직접 추출했다. 이후 로컬 멀티코어 확장 내용은 포함하지 않았다.

패키징 변경: 메모리 상대 경로, 별도 Slave core 이름·FND 중복명 분리, TB probe/reset/APB sampling 수정, 펌웨어와 Slave의 4개 표시 모드 계약 일치. [변경 및 실행 범위](./docs/verification.md)를 참고한다.

이관일: **2026-10-15**. [파일별 원본/공개 SHA-256](./docs/source_manifest.json)을 통해 변경 여부를 확인할 수 있다. 기존 보고서·이미지는 경로와 바이트를 보존했다.
