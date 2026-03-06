`timescale 1ns/1ps // 시뮬레이션 시간 정밀도 통일로 타이밍 해석 일관성 확보(1ns 단위, 1ps 해상도)

/* =====================================================================================================================
 * File Name : FSMD_sub.v
 * Project   : Softmax layer Accelerator Based on FPGA
 * Author    : 숭상화
 * Creation Date: 2025-08-30
 * Description : Q7.8 고정소수점 벡터에서 기준값(d2)을 빼며, 외부 카운터와 연동해 프레임 경계를 관리하는 FSMD 서브트랙터
 * Design Notes :
 *   - 형식: Q7.8(16b, signed two's complement)로 연산하며 포화 선택(SATURATE) 지원 → 오버플로 시 수치 안정성 유지 목적
 *   - 프로토콜: data2_en으로 기준값 래치 이후 data1_req로 연속 프레임 요청, data1_en 수신 사이클에 outc 펄스로 외부 카운터 증분
 *   - 타이밍: data1_en 수신 다음 사이클에 data_valid_o 1펄스로 결과 확정 → 파이프라인 경합 방지
 *   - 경계: count_i == (last_count-1) 처리 시 last=1로 종료 신호화, data1_req=0으로 백프레셔 유발해 수신 중단
 * Dependencies : 독립 모듈(상위에서 외부 카운터/스트림 소스와 결선), 시스템 전체에서는 Downscale→Sub→Exp→Norm 흐름에 배치
 =====================================================================================================================*/

/**
 * @brief Q7.8 고정소수점 벡터 감산 FSMD
 * @details
 *   - 목적: softmax 전처리 단계(Xi - Xmax)의 수치 범위 축소로 exp 영역의 오버플로 여지 최소화
 *   - 데이터패스: data2_en으로 기준 d2_q 래치 → data1_i 수신 시 sub_q7p8(a=data1_i, b=d2_q) → 다음 사이클 valid 펄스
 *   - 제어: data1_req로 프레임 지속 요청, data1_en 수신 사이클에 outc=1로 외부 카운터 증분, last_count 기준으로 종료 판정
 *   - 제약/가정: ready가 수신 허가 신호로 동작, last_count는 총 프레임 수를 의미(0..last_count-1), count_i는 외부에서 동기 증가
 *   - 타이밍 포인트: data1_en 수신과 결과 유효(data_valid_o) 사이에 1사이클 파이프 지연을 둬 레지스터 전파/정합 안정화
 * @param clk 클록 상승엣지 동기화로 상태/파이프 갱신
 * @param rst_n 비동기 Low-Active 리셋으로 초기 상태 강제(전역 리셋과의 친화성 위해 채택)
 * @param data2_en 기준값 래치 트리거(IDLE에서만 의미)로 다음 런을 위한 기준 설정
 * @param data2_i 기준값(Q7.8)으로 전체 프레임에 공통 적용되는 감산 피감수 b
 * @param data1_req 상위 소스에 프레임 지속 요청 신호(런 구간 유지)로 백프레셔 제어
 * @param data1_en 입력 프레임 유효 수신(핸드셰이크)으로 같은 사이클 outc 펄스 발생
 * @param data1_i 감산 대상 입력(Q7.8)으로 d2_q와의 차를 계산
 * @param count_i 외부 카운터 현재값으로 종료 임계(last_count-1) 비교에 사용
 * @param ready 하위 경로 수용 가능 표시로 과도 수신 방지(REQ 수락 게이팅)
 * @param last_count 총 프레임 개수로 마지막 인덱스 판정에 활용
 * @param data_o 감산 결과(Q7.8)로 다음 사이클에 확정
 * @param data_valid_o 결과 유효 1사이클 펄스로 다운스트림 캐치 타이밍 기준
 * @param outc data1_en 수신 사이클에 발생하는 카운터 증가 펄스로 count_i 외부 증분 트리거
 * @param last 마지막 프레임 처리 사이클에서 1로 세그먼트 종료를 명시
 */

 /**********************************************************************
 * Stage 0: 파라미터/IF 선언
 * - Q7.8 고정소수점 전제 하에 포화 선택 가능(SATURATE) → 소프트맥스 전처리의 수치 안정성 보장
 **********************************************************************/
module fsmd_subtractor #(
    parameter integer SATURATE = 1, // 1이면 오버플로 시 포화로 박아 exp 입력 범위 안정화, 0이면 래핑으로 성능 우선 선택
    parameter integer count_width  = 8 // 외부 카운터 폭을 상위 시스템 스펙에 맞춰 가변화하여 자원 최적화 유연성 확보
)(
    input  wire         clk, // 상태/파이프 동기 클록
    input  wire         rst_n, // 시스템 전역과의 결선 용이성을 위해 Low-Active 비동기 리셋 채택

    // stream-2 (trigger/latch)
    input  wire         data2_en, // 기준값 래치 트리거(IDLE에서 다음 런 시작 지시)로 벡터 기준 고정 의도
    input  wire [15:0]  data2_i, // 기준 데이터 Q7.8로 모든 프레임에 동일하게 적용하여 Xi - Xmax 구현

    // stream-1 (data frames)
    output reg          data1_req, // 입력 소스에 지속 요청 발신으로 파이프 비우기 방지 및 처리율 확보
    input  wire         data1_en, // 유효 프레임 수신 승인으로 outc와 결과 계산 시점을 결정
    input  wire [15:0]  data1_i, // 감산 대상 Q7.8 입력으로 동적 프레임 데이터

    // external counter feedback
    input  wire [count_width - 1:0]  count_i, // 외부 카운터 현재값으로 종료 임계 비교에 사용하여 오프바이원 위험 제거
	
	input  wire 		ready, // 하위 경로 수용 가능 신호로 REQ에서 수락 게이트를 형성하여 백프레셔 순응
	
	input  wire [count_width - 1:0]  last_count, // 총 프레임 수(상한)로 마지막 처리 인덱스를 last_count-1로 명확화

    // results
    output reg  [15:0]  data_o, // Q7.8 결과값으로 다음 사이클 확정해 다운스트림 샘플 타이밍 단순화
    output reg          data_valid_o, // 결과 유효 1펄스로 단일 사이클 캐치 계약 제공
    output reg          outc, // data1_en 수신 사이클에 외부 카운터 증분 펄스를 보장해 소스 인덱스와 결과 정합 유지
    output reg          last // 마지막 프레임 처리 사이클에 1로 세그먼트 경계 명시하여 후속 단계 플러시/롤업 용이
);

    /**********************************************************************
     * Stage 1: 상수/상태/레지스터
     * - Q7.8 최대/최소를 명시해 포화 연산 기준치를 고정(표준 16b 2의 보수 범위)
     **********************************************************************/
    localparam [15:0] Q16_POS_MAX = 16'h7FFF; // +127.99609375로 Q7.8 양수 최댓값(포화 상한) 지정 근거
    localparam [15:0] Q16_NEG_MIN = 16'h8000; // -128.0로 Q7.8 음수 최솟값(포화 하한) 지정 근거

    localparam [1:0] IDLE = 2'd0; // 기준 래치 대기 상태로 data2_en 감지에 집중
    localparam [1:0] REQ  = 2'd1; // 입력 프레임 요청/수락 상태로 data1_req 유지와 수락 게이팅 수행
    localparam [1:0] RUN  = 2'd2; // 결과 산출/발행 사이클로 다음 사이클 유효 펄스 보장

    reg [1:0] state, state_n; // 현재/다음 상태 분리로 조합/순차 경로 독립성 확보

    reg [15:0] d2_q; // 기준값 레지스터로 런 동안 불변 유지해 모든 프레임에 동일 보정 적용

    reg [15:0] result_q; // 파이프 중간 레지스터(여유 확보 목적)로 타이밍 마진 향상에 대비
    
    reg waiting; // REQ→RUN 전이 후 한 사이클 휴지 삽입해 백투백 수락으로 인한 중복 처리 위험 회피

    // 마지막 트랜잭션 여부 플래그 // 경계 신호는 last로 직접 발행하므로 별도 플래그 저장 불필요 판단

    /**********************************************************************
     * Stage 2: 함수 - Q7.8 감산(포화 선택)
     * - 17b 확장으로 부호 비트 전파와 오버플로 판정 정확도 확보
     **********************************************************************/
    function [15:0] sub_q7p8;
        input [15:0] a; // 감산 피연산자 A로 수신 데이터
        input [15:0] b; // 감산 피연산자 B로 래치된 기준
        reg signed [16:0] wide; // 17b 확장으로 부호 연장 후 산술 정확성 보장
        reg s_a, s_b, s_r; // 부호 비교용 보조 비트로 오버플로 판정에 활용
        reg ovf; // 오버플로 플래그로 포화 경계 선택에 사용
    begin
        if (SATURATE) begin // 수치 안정성 우선 설계 시 포화 경계 채택
            wide = $signed({a[15], a}) - $signed({b[15], b}); // 17b 부호확장 감산으로 최상위 비트 손실 방지
            s_a  = a[15]; // A 부호 기록으로 교차부호 상황 탐지
            s_b  = b[15]; // B 부호 기록으로 교차부호 상황 탐지
            s_r  = wide[16]; // 결과 부호 관찰로 오버플로 여부 판단 기준 취득
            ovf  = ((s_a == ~s_b) && (s_r != s_a)); // a - b의 오버플로 조건(교차부호에서 결과 부호 불일치)로 표준 규칙 적용
            if (ovf)
                sub_q7p8 = s_a ? Q16_NEG_MIN : Q16_POS_MAX; // 오버플로 시 입력 부호에 따라 하한/상한으로 포화해 왜곡 최소화
            else
                sub_q7p8 = wide[15:0]; // 정상 범위면 하위 16b 취해 Q7.8 표현 유지
        end else begin
            sub_q7p8 = a - b; // 래핑 선택 시 자원/지연 최소화 우선으로 단순 감산
        end
    end
    endfunction // 연산 함수 종료로 조합 경로 캡슐화

    /**********************************************************************
     * Stage 3: 순차 로직(FSM 상태/출력 펄스 관리)
     * - data1_en 수신 사이클에 outc=1, 다음 사이클에 data_valid_o=1로 명확한 1사이클 오프셋 유지
     **********************************************************************/
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // 비동기 리셋로 전역 초기화 신속 보장
            state        <= IDLE; // 초기 상태를 IDLE로 명시해 안전 기동
            d2_q         <= 16'd0; // 기준값 클리어로 불정 초기 데이터 영향 차단
            result_q     <= 16'd0; // 파이프 초기화로 X-상태 전파 방지

            data1_req    <= 1'b0; // 초기에는 소스 요청 중단으로 불필요 트래픽 억제
            data_o       <= 16'd0; // 출력 기본값으로 초기 안정
            data_valid_o <= 1'b0; // 유효 펄스 비활성
            outc         <= 1'b0; // 카운터 펄스 없음
            last         <= 1'b0; // 경계 신호 비활성
            waiting      <= 1'b0; // 휴지 상태 클리어로 첫 수락 준비
        end else begin // 정상 동작 경로
            state        <= state_n; // 다음 상태로 전이하여 FSM 진행

            data_valid_o <= 1'b0; // 1사이클 펄스 보장을 위해 기본 0으로 클리어
            outc         <= 1'b0; // 펄스 기본값 0 유지로 글리치 방지
			data1_req    <= 1'b0; // 기본은 0으로 두고 상태별로 명시적 구동해 의도 드러냄
			last         <= 1'b0; // 마지막 신호도 펄스화로 소비 측 단순화
			waiting      <= 1'b0; // 기본 클리어로 REQ에서 조건 충족 시 수락 가능하게 함
            case (state)
                // ----------------- IDLE -----------------
                IDLE: begin // 기준값 래치 대기 단계로 런 시작 조건 충족 시 진입 준비
                    data1_req <= 1'b0; // 아직 프레임 요청하지 않아 소스 유휴 유지
                    
                    if (data2_en) begin // 기준값 준비 신호 수신 시
                        d2_q      <= data2_i; // 같은 사이클에 기준 래치해 런 동안 고정값으로 사용
                        data1_req <= 1'b1; // 즉시 프레임 요청 시작으로 처리 지연 최소화
                    end
                end

                // ----------------- REQ ------------------
                REQ: begin // 프레임 지속 요청 단계로 수락 조건이 맞을 때만 소비
                    data1_req <= 1'b1; // 소스에 지속 요청 유지로 처리율 확보
                    if (data1_en && ready && !waiting) begin // 입력 유효·하위 수용·휴지 아님의 3조건 동시 만족 시
                        outc         <= 1'b1; // 같은 사이클 외부 카운터 증가로 count_i 추적 일관성 유지
                        //last_tran_d <= (count_i == (CNT_MAX-1)); // 경계 판정은 last_count 비교로 통일해 중복 상태 제거
                    end
                end

                // ----------------- RUN ------------------
                RUN: begin // 결과 산출/발행 사이클로 다음 사이클 valid 펄스 예정
                    data_o    <= sub_q7p8(data1_i, d2_q); // 기준과의 차를 계산해 출력 레지스터에 확정(조합→레지 동결)
                    data_valid_o <= 1'b1; // 수신 다음 사이클 유효 펄스로 다운스트림 동기화 단순화                
                    if (count_i == last_count - 1'b1) begin // 현재 인덱스가 마지막 항목이면
                        data1_req <= 1'b0; // 추가 요청 중단으로 소스 백프레셔 형성
                        last <= 1'b1; // 세그먼트 종료를 명시해 후속 단계 롤업/플러시 트리거
                    end else begin
                        data1_req <= 1'b1; // 다음 프레임을 연속 요청해 처리율 극대화
                        waiting      <= 1'b1; // 한 사이클 휴지 설정으로 REQ에서 즉시 재수락 방지(더블컨슘 회피)
                    end
                end

                // ----------------- default(DONE 대행) ---
                default: begin // 정의 외 상태 보호용으로 안전 정지 동작 수행
                    data1_req <= 1'b0; // 요청 중단으로 안정화
                end
            endcase
        end
    end

    /**********************************************************************
     * Stage 4: 조합 전이 로직
     * - 입력 수락 조건과 종료 임계를 기반으로 IDLE↔REQ↔RUN 전이 명확화
     **********************************************************************/
    always @* begin
        state_n     = state; // 기본은 유지로 글리치 방지

        case (state)
            IDLE: begin // 기준값 준비 대기
                if (data2_en)
                    state_n = REQ; // 기준 래치 후 즉시 요청 단계로 진입해 지연 최소화
                else
                    state_n = IDLE; // 대기 지속으로 불필요 전이 방지
            end

            REQ: begin // 프레임 요청/수락
                if (data1_en && ready && !waiting)
                    state_n = RUN; // 수락과 동시에 다음 사이클 결과 발행 단계로 전이
                else
                    state_n = REQ; // 수락 조건 미충족 시 요청 유지
            end

            RUN: begin // 결과 발행
                if (count_i == last_count - 1'b1)
                    state_n = IDLE; // 마지막 처리 완료 후 초기 상태로 복귀해 다음 런 준비
                else
                    state_n = REQ; // 더 남았으면 다시 요청 단계로 회귀해 파이프 유지
            end

            default: state_n = IDLE; // 비정상 보호 경로로 안전 복귀
        endcase
    end

endmodule // 모듈 종료: softmax 전처리 감산 FSMD의 경계/타이밍 계약을 명확히 한 구현
