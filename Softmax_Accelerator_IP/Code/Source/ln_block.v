/* =====================================================================================================================
 * File Name    : ln_block.v
 * Project      : Softmax layer Accelerator Based on FPGA
 * Author       : 숭상화
 * Creation Date: 2025-09-06
 * Description  : Q5.11 입력에 대해 ln(x)을 Q7.8로 산출하는 4단 파이프라인 블록 (정규화→LUT→합산→형식정렬)
 * Design Notes : 선형 보간 제거(mant LUT 단일 표본 직접 사용). ln(x)=ln(1.mant)+exp*ln2 분해 유지.
 *               Q-포맷 정렬(Q4.11→Q4.16→Q7.8)과 half-up 반올림 유지. AXIS 유사 Valid/Ready 백프레셔 유지.
 * Dependencies : priority_encoder_16bit, ln_lut_exp, ln_lut_mant
 * =====================================================================================================================*/

module ln_block (
    // --- 시스템 신호 ---
    input  wire           iClk,
    input  wire           iRsn,

    // --- 입력 인터페이스 (AXI-Stream Slave 스타일) ---
    input  wire           iValid,
    output wire           oReady,
    input  wire  [15:0]   iData,   // Q5.11 (unsigned)

    // --- 출력 인터페이스 (AXI-Stream Master 스타일) ---
    output wire           oValid,
    input  wire           iReady,
    output wire signed [15:0] oData // Q7.8 (signed)
);

    // --- 핸드셰이크 신호 (4단 파이프라인) ---
    wire pipe1_ready, pipe2_ready, pipe3_ready, pipe4_ready;
    reg  rPipe1_valid, rPipe2_valid, rPipe3_valid, rPipe4_valid;

    assign pipe4_ready = !rPipe4_valid || iReady;
    assign pipe3_ready = !rPipe3_valid || pipe4_ready;
    assign pipe2_ready = !rPipe2_valid || pipe3_ready;
    assign pipe1_ready = !rPipe1_valid || pipe2_ready;
    assign oReady      = pipe1_ready;

    /**********************************************************************
     * Stage 1: FXP(Q5.11) → 정규화(1.mant, E)
     **********************************************************************/
    reg  [4:0] rPipe1_E;      // E = exp + 15 = msb_pos + 4
    reg  [9:0] rPipe1_mant;   // 1.mant 상위 10비트

    wire [3:0] msb_pos;
    wire       is_zero;
    priority_encoder_16bit u_pe (.in(iData), .pos(msb_pos), .zero(is_zero));

    wire [4:0]  wPipe1_E     = msb_pos + 5'd4;
    wire [15:0] wShiftedMant = iData << (15 - msb_pos);
    wire [9:0]  wPipe1_mant  = wShiftedMant[14:5];

    always @(posedge iClk or negedge iRsn) begin
        if (!iRsn) begin
            rPipe1_valid <= 1'b0;
        end else if (pipe1_ready) begin
            rPipe1_valid <= iValid;
            if (iValid) begin
                if (is_zero) begin
                    rPipe1_E    <= 5'd0;
                    rPipe1_mant <= 10'd0;
                end else begin
                    rPipe1_E    <= wPipe1_E;
                    rPipe1_mant <= wPipe1_mant;
                end
            end
        end
    end

    /**********************************************************************
     * Stage 2: LUT 조회 (ln2*exp, ln(1.mant) 단일 표본)
     **********************************************************************/
    reg  signed [15:0] rPipe2_ln2_exp_val; // Q4.11
    reg         [15:0] rPipe2_ln_mant;     // Q0.16 (보간 없음, 단일 표본)

    wire [9:0] mant_addr = rPipe1_mant[9:0];

    wire signed [15:0] wLn2ExpVal; // Q4.11
    wire        [15:0] wLnMant;    // Q0.16

    ln_lut_exp  u_lut_exp  (.addr(rPipe1_E),  .data(wLn2ExpVal));
    ln_lut_mant u_lut_mant (.addr(mant_addr), .data(wLnMant));

    always @(posedge iClk or negedge iRsn) begin
        if (!iRsn) begin
            rPipe2_valid <= 1'b0;
        end else if (pipe2_ready) begin
            rPipe2_valid        <= rPipe1_valid;
            if (rPipe1_valid) begin
                rPipe2_ln2_exp_val <= wLn2ExpVal;
                rPipe2_ln_mant     <= wLnMant;     // 보간 없이 그대로 사용
            end
        end
    end

    /**********************************************************************
     * Stage 3: 포맷 정렬 및 합산 (Q4.16) → Q7.8 반올림
     **********************************************************************/
    reg signed [15:0] rPipe3_data_out; // Q7.8

    wire signed [20:0] ln2_exp_q4_16 = {rPipe2_ln2_exp_val, 5'b0}; // Q4.11 → Q4.16
    wire signed [20:0] ln_mant_q4_16 = {5'b0, rPipe2_ln_mant};     // Q0.16 → Q4.16
    wire signed [20:0] sum_q4_16     = ln2_exp_q4_16 + ln_mant_q4_16;

    // Q4.16 → Q7.8 (half-up)
    wire signed [15:0] temp_q7_8    = {{3{sum_q4_16[20]}}, sum_q4_16[20:8]};
    wire signed [15:0] wFinalResult = temp_q7_8 + sum_q4_16[7];
    

    always @(posedge iClk or negedge iRsn) begin
        if (!iRsn) begin
            rPipe3_valid <= 1'b0;
        end else if (pipe3_ready) begin
            rPipe3_valid    <= rPipe2_valid;
            if (rPipe2_valid) begin
                rPipe3_data_out <= wFinalResult;
            end
        end
    end

    /**********************************************************************
     * Stage 4: 최종 출력 레지스터링
     **********************************************************************/
    reg signed [15:0] rPipe4_data_out;

    always @(posedge iClk or negedge iRsn) begin
        if (!iRsn) begin
            rPipe4_valid <= 1'b0;
        end else if (pipe4_ready) begin
            rPipe4_valid    <= rPipe3_valid;
            if (rPipe3_valid) begin
                rPipe4_data_out <= rPipe3_data_out;
            end
        end
    end

    // --- 최종 출력 ---
    assign oData  = rPipe4_data_out; // Q7.8
    assign oValid = rPipe4_valid;

    // NOTE: 입력 0 처리 정책은 시스템 레벨에서 정의 권장(예: -Inf 대용 상수).
endmodule
