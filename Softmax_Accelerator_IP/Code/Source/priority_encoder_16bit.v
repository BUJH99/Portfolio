/* =====================================================================================================================
 * File Name   : priority_encoder_16bit.v
 * Project     : Softmax layer Accelerator Based on FPGA
 * Author      : 숭상화
 * Creation Date: 2025-08-30
 * Description : 16비트 벡터에서 최상위 1의 인덱스를 산출하고, 모든 비트가 0인 예외를 zero 플래그로 구분하는 조합 로직
 * Design Notes: MSB 우선 순위(지연 최소화 목적), 조합로직(레지스터 지연 0사이클), casex 사용(X 마스킹 주의),
 *               기본 할당으로 래치 방지, pos 폭 4b(0~15 인덱스 커버)
 * Dependencies: None (standalone)
 * NOTE        : casex는 X를 와일드카드로 간주하므로, 시뮬/합성 일관성을 위해 upstream에서 X 발생을 억제하는 것이 안전
 * TODO        : 필요 시 LSB 우선 변형, 혹은 one-hot/thermometer 입력 변환기와의 인터페이스 가이드 추가
 * =====================================================================================================================*/

/**
 * @brief 16b 입력의 최상위 set 비트 위치를 4b 인덱스로 출력하고, 입력이 전부 0이면 zero=1로 표기
 * @details MSB 우선 탐색으로 분기 결정 지연을 줄이기 위함이며, 조합 경로만 사용해 파이프라인 단계 증가를 피함.
 *          기본값을 선할당하여 모든 분기에서 신호가 정의되도록 해 래치 합성 위험을 제거함.
 * @param in   [15:0] 검색 대상 비트맵(예: 16-way 유효 플래그); 폭 16은 테이블/세그먼트 수와 1:1 매핑을 가정 // 폭=16인 이유: 0~15 인덱스 직접 대응해 추가 디코딩 없이 분기 가능
 * @param pos  [3:0]  최상위 set 비트의 인덱스(0~15); 4b면 충분(2^4=16) // 인덱스 상한 15를 커버하는 최소 폭 선택으로 자원 절감
 * @param zero        입력이 모두 0이면 1, 아니면 0; 다운스트림에서 예외 경로를 즉시 우회하기 위함 // 분기 비용 감축을 위해 별도 비교 없이 플래그 제공
 */

 /**********************************************************************
 * Stage 1: MSB Priority Encode (Combinational)
 * - MSB 우선 순위를 통해 분기 결정 지연을 최소화(테이블 선택·노멀라이즈 경로에 유리)
 **********************************************************************/

module priority_encoder_16bit ( // MSB 기반 우선순위 인코딩을 단일 사이클 조합 경로로 제공해 파이프라인 딜레이를 추가하지 않음
    input  wire [15:0] in, // 16채널 비트맵 입력; 상위 비트가 더 높은 우선순위를 갖도록 정의하여 결정 지연 최소화
    output reg  [3:0]  pos, // 최상위 1의 인덱스(0~15); 4b로 표기해 추가 폭 확장 비용을 방지
    output reg         zero // 입력이 전부 0인지 즉시 판별해 다운스트림의 예외 처리 분기 비용 절약
); // 포트 폭·플래그 설계로 다운스트림 디코딩/비교 비용을 줄여 전체 경로 지연을 관리

    always @(*) begin // 조합 블록: 레지스터 지연 없이 즉시 결과 산출해 임계 경로를 짧게 유지
        pos = 4'd0; // 기본값 선할당으로 모든 경로에서 정의를 보장(래치 합성 방지 및 default 경로 명확화)
        zero = 1'b1; // 기본 가정은 “모두 0”; 매칭 발생 시에만 0으로 내려 예외 플래그 생성 비용 최소화

        casex (in)
            16'b1xxx_xxxx_xxxx_xxxx: begin pos = 4'd15; zero = 1'b0; end
            16'b01xx_xxxx_xxxx_xxxx: begin pos = 4'd14; zero = 1'b0; end
            16'b001x_xxxx_xxxx_xxxx: begin pos = 4'd13; zero = 1'b0; end
            16'b0001_xxxx_xxxx_xxxx: begin pos = 4'd12; zero = 1'b0; end
            16'b0000_1xxx_xxxx_xxxx: begin pos = 4'd11; zero = 1'b0; end
            16'b0000_01xx_xxxx_xxxx: begin pos = 4'd10; zero = 1'b0; end
            16'b0000_001x_xxxx_xxxx: begin pos = 4'd9;  zero = 1'b0; end
            16'b0000_0001_xxxx_xxxx: begin pos = 4'd8;  zero = 1'b0; end
            16'b0000_0000_1xxx_xxxx: begin pos = 4'd7;  zero = 1'b0; end
            16'b0000_0000_01xx_xxxx: begin pos = 4'd6;  zero = 1'b0; end
            16'b0000_0000_001x_xxxx: begin pos = 4'd5;  zero = 1'b0; end
            16'b0000_0000_0001_xxxx: begin pos = 4'd4;  zero = 1'b0; end
            16'b0000_0000_0000_1xxx: begin pos = 4'd3;  zero = 1'b0; end
            16'b0000_0000_0000_01xx: begin pos = 4'd2;  zero = 1'b0; end
            16'b0000_0000_0000_001x: begin pos = 4'd1;  zero = 1'b0; end
            16'b0000_0000_0000_0001: begin pos = 4'd0;  zero = 1'b0; end
            default: begin // 어떤 비트도 1이 아니거나 X로 인해 매칭 불가한 경우의 보호 경로
                pos = 4'd0; // 정의된 기본 인덱스로 수렴시켜 다운스트림의 예외 처리 부담을 낮춤
                zero = 1'b1; // “모두 0” 시나리오를 명시적으로 신호화하여 별도 비교 연산을 제거
            end // default에서의 명시적 할당으로 합성 시 래치 및 X-전파를 억제
        endcase // 케이스 순서 자체가 우선순위를 인코딩하므로 재정렬은 타이밍/기능에 영향

    end // 조합 블록 종료: 모든 경로가 값 할당됨을 보장하여 안정적 합성 유도

endmodule // 모듈 종료: 단일 사이클 우선순위 결정기로 분기 선택의 임계경로를 단축
