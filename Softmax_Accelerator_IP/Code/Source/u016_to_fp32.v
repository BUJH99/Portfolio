`timescale 1ns/1ps
// ============================================================================
// U0.16 → FP32 콤비 변환 + AXIS 패스스루 래퍼 (Verilog-2001)
// - 백프레셔: s_axis_tready = m_axis_tready (투명 전파)
// - 밸리드/라스트: 패스스루
// - 데이터: 함수 u016_to_fp32로 콤비 변환
// ============================================================================
module u016_to_fp32 (
    input  wire         clk,           // 상태 없음(형식상 보유)
    input  wire         rst_n,         // 상태 없음(형식상 보유)

    // s_axis: U0.16
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire [15:0]  s_axis_tdata,
    input  wire         s_axis_tlast,

    // m_axis: FP32
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire [31:0]  m_axis_tdata,
    output wire         m_axis_tlast
);
    // 백프레셔/핸드셰이크: 패스스루
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tlast  = s_axis_tlast;

    // ── U0.16 → FP32 (순수 콤비) ───────────────────────────────────────────
    function [31:0] u016_to_fp32;
        input [15:0] u;
        integer i;
        integer k;             // MSB 위치 (0..15)
        reg      found;        // 첫 히트 플래그
        reg [7:0]  exp_b;      // biased exponent
        reg [22:0] frac;       // fraction
        reg [15:0] norm;       // 1.xxx 정규화(비트15=1)
        reg [31:0] outv;
    begin
        if (u == 16'd0) begin
            u016_to_fp32 = 32'h0000_0000; // +0.0
        end else begin
            // 1) MSB 탐색(상위비트 우선) - disable/break 없이 구현
            found = 1'b0;
            k     = 0;
            for (i = 15; i >= 0; i = i - 1) begin
                if (!found && u[i]) begin
                    k     = i;       // 최초 1 위치 고정
                    found = 1'b1;
                end
            end

            // 2) 지수: biased = 127 + (k - 16) = k + 111
            exp_b = (k[7:0]) + 8'd111;

            // 3) 정규화: MSB를 bit15로 정렬 → 1.xxx
            norm = u << (15 - k[4:0]);

            // 4) 가수: norm[14:0] 상위 배치 + 8'b0 패딩 → 정확한 23b
            frac = { norm[14:0], 8'b0 };

            // 5) 조립: sign=0, exp=exp_b, frac=frac
            outv = {1'b0, exp_b, frac};
            u016_to_fp32 = outv;
        end
    end
    endfunction

    assign m_axis_tdata = u016_to_fp32(s_axis_tdata);

endmodule
