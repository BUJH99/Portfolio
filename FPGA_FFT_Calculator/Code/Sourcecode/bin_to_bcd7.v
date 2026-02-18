// 24-bit unsigned -> 7-digit BCD (0 ~ 9,999,999)
// Double-dabble (shift-add-3), 24 cycles
module bin_to_bcd7 (
    input  wire        i_clk,
    input  wire        i_rstn,
    input  wire        i_start,      // 1 pulse when new value should be latched
    input  wire [23:0] i_val,        // |value|, already saturated to 0~9_999_999
    output reg         o_busy,
    output reg         o_done,       // 1-cycle pulse when done
    output reg [27:0]  o_bcd7        // {d6,d5,...,d0}, d6=MSD
);

    localparam S_IDLE  = 2'd0;
    localparam S_SHIFT = 2'd1;

    reg [1:0]  state;
    reg [23:0] bin_reg;
    reg [27:0] bcd_reg;
    reg [4:0]  bit_cnt;      // 24 bits → 0..23

    // 조합: add-3 & shift
    integer d;
    reg [27:0] bcd_next;
    reg [23:0] bin_next;
    reg [3:0]  digit;

    always @* begin
        bcd_next = bcd_reg;
        // 각 자리 >=5 면 +3
        for (d = 0; d < 7; d = d + 1) begin
            digit = bcd_next[d*4 +: 4];
            if (digit >= 4'd5)
                digit = digit + 4'd3;
            bcd_next[d*4 +: 4] = digit;
        end

        bin_next = bin_reg;
        {bcd_next, bin_next} = {bcd_next, bin_next} << 1;
    end

    // 순차
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            state   <= S_IDLE;
            o_busy  <= 1'b0;
            o_done  <= 1'b0;
            o_bcd7  <= 28'd0;
            bin_reg <= 24'd0;
            bcd_reg <= 28'd0;
            bit_cnt <= 5'd0;
        end else begin
            o_done <= 1'b0;

            case (state)
            S_IDLE: begin
                o_busy <= 1'b0;
                if (i_start) begin
                    bin_reg <= i_val;
                    bcd_reg <= 28'd0;
                    bit_cnt <= 5'd24;   // 24비트 변환
                    o_busy  <= 1'b1;
                    state   <= S_SHIFT;
                end
            end

            S_SHIFT: begin
                // 한 비트씩 변환
                bcd_reg <= bcd_next;
                bin_reg <= bin_next;

                if (bit_cnt == 5'd1) begin
                    // 마지막 비트까지 처리 완료
                    o_bcd7 <= bcd_next;
                    o_busy <= 1'b0;
                    o_done <= 1'b1;
                    state  <= S_IDLE;
                end else begin
                    bit_cnt <= bit_cnt - 5'd1;
                end
            end

            default: begin
                state <= S_IDLE;
            end
            endcase
        end
    end
endmodule
