`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: KeycodeDecoder
// description: Decodes scanned keypad values into calculator control flags.
// [MODULE_INFO_END]
module KeycodeDecoder (
    input  logic [4:0] iKeyValue,

    output logic       oIsDigit,
    output logic [3:0] oDigit,

    output logic       oIsMinus,
    output logic       oIsDot,
    output logic       oIsDel,
    output logic       oIsNext,
    output logic       oIsPrev,
    output logic       oIsToggleRi,
    output logic       oIsEnt,
    output logic       oIsEsc
);

    always_comb begin
        oIsDigit    = 1'b0;
        oDigit      = '0;
        oIsMinus    = 1'b0;
        oIsDot      = 1'b0;
        oIsDel      = 1'b0;
        oIsNext     = 1'b0;
        oIsPrev     = 1'b0;
        oIsToggleRi = 1'b0;
        oIsEnt      = 1'b0;
        oIsEsc      = 1'b0;

        unique case (iKeyValue)
            5'd1:  oIsDot      = 1'b1;
            5'd2:  oIsEsc      = 1'b1;
            5'd3:  begin
                oIsDigit = 1'b1;
                oDigit   = 4'd0;
            end
            5'd4:  oIsEnt      = 1'b1;
            5'd5:  oIsToggleRi = 1'b1;
            5'd7:  begin
                oIsDigit = 1'b1;
                oDigit   = 4'd1;
            end
            5'd8:  begin
                oIsDigit = 1'b1;
                oDigit   = 4'd2;
            end
            5'd9:  begin
                oIsDigit = 1'b1;
                oDigit   = 4'd3;
            end
            5'd10: oIsPrev     = 1'b1;
            5'd11: oIsMinus    = 1'b1;
            5'd12: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd4;
            end
            5'd13: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd5;
            end
            5'd14: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd6;
            end
            5'd15: oIsNext     = 1'b1;
            5'd17: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd7;
            end
            5'd18: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd8;
            end
            5'd19: begin
                oIsDigit = 1'b1;
                oDigit   = 4'd9;
            end
            5'd20: oIsDel      = 1'b1;
            default: begin
            end
        endcase
    end

endmodule
