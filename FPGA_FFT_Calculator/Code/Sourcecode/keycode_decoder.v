`timescale 1ns / 1ps

//------------------------------------------------------------------------------
// 키 코드 디코더
//   i_key_value (0~20)
//   -> 숫자/부호/소수점/F1/F2/F3/F4/ENT/ESC 플래그로 변환
//------------------------------------------------------------------------------
module keycode_decoder (
    input  wire [4:0] i_key_value,

    output reg        o_is_digit,      // 0~9 숫자
    output reg [3:0]  o_digit,

    output reg        o_is_minus,      // '-'
    output reg        o_is_dot,        // '/' -> 소수점
    output reg        o_is_del,        // F1 -> delete
    output reg        o_is_next,       // F2 -> 다음 샘플
    output reg        o_is_prev,       // F3 -> 이전 샘플
    output reg        o_is_toggle_ri,  // F4 -> 실수/허수 토글
    output reg        o_is_ent,        // Enter
    output reg        o_is_esc         // Esc
);

    always @* begin
        // 기본값
        o_is_digit      = 1'b0;
        o_digit         = 4'd0;
        o_is_minus      = 1'b0;
        o_is_dot        = 1'b0;
        o_is_del        = 1'b0;
        o_is_next       = 1'b0;
        o_is_prev       = 1'b0;
        o_is_toggle_ri  = 1'b0;
        o_is_ent        = 1'b0;
        o_is_esc        = 1'b0;

        case (i_key_value)
            // 0: 아무 입력 없음은 무시
            5'd1:  o_is_dot       = 1'b1;              // '/' -> 소수점
            5'd2:  o_is_esc       = 1'b1;              // Esc

            5'd3:  begin o_is_digit=1'b1; o_digit=4'd0; end // '0'
            5'd4:  o_is_ent       = 1'b1;              // Enter
            5'd5:  o_is_toggle_ri = 1'b1;              // F4
            // 5'd6: '*' (미사용)

            5'd7:  begin o_is_digit=1'b1; o_digit=4'd1; end // '1'
            5'd8:  begin o_is_digit=1'b1; o_digit=4'd2; end // '2'
            5'd9:  begin o_is_digit=1'b1; o_digit=4'd3; end // '3'
            5'd10: o_is_prev       = 1'b1;             // F3

            5'd11: o_is_minus      = 1'b1;             // '-'

            5'd12: begin o_is_digit=1'b1; o_digit=4'd4; end // '4'
            5'd13: begin o_is_digit=1'b1; o_digit=4'd5; end // '5'
            5'd14: begin o_is_digit=1'b1; o_digit=4'd6; end // '6'
            5'd15: o_is_next       = 1'b1;             // F2
            // 5'd16: '+' (미사용)

            5'd17: begin o_is_digit=1'b1; o_digit=4'd7; end // '7'
            5'd18: begin o_is_digit=1'b1; o_digit=4'd8; end // '8'
            5'd19: begin o_is_digit=1'b1; o_digit=4'd9; end // '9'
            5'd20: o_is_del        = 1'b1;             // F1
            default: ;
        endcase
    end

endmodule
