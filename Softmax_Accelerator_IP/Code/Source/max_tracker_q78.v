// ============================================================================
// 최대값 트래커(Q7.8, signed): start_first에서 초기화, 이후 in_fire 때 갱신
// ============================================================================
module max_tracker_q78(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_fire,      // 샘플 수락 펄스
    input  wire               start_first,  // 벡터 첫 샘플 수락
    input  wire signed [15:0] x_in,
    output reg  signed [15:0] x_max
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_max <= 16'sd0;
        end else begin
            if (in_fire) begin
                if (start_first) begin
                    x_max <= x_in; // 첫 샘플로 초기화
                end else begin
                    if ($signed(x_in) > $signed(x_max))
                        x_max <= x_in;
                end
            end
        end
    end
endmodule
