/*
[MODULE_INFO_START]
Name: Q78SubSat
Role: Signed Q7.8 subtractor
Summary:
  - Subtracts two Q7.8 values with saturation
[MODULE_INFO_END]
*/
`timescale 1ns/1ps
`include "SoftmaxFormat.vh"
module Q78SubSat(
    input  wire signed [`DEF_SOFTMAX_Q78_W-1:0] iDataA,
    input  wire signed [`DEF_SOFTMAX_Q78_W-1:0] iDataB,
    output reg  signed [`DEF_SOFTMAX_Q78_W-1:0] oData
);
    localparam integer LP_Q78_W      = `DEF_SOFTMAX_Q78_W;
    localparam integer LP_DIFF_W     = LP_Q78_W + 1;
    localparam signed [LP_Q78_W-1:0]  LP_Q78_MAX = 16'sd32767;
    localparam signed [LP_Q78_W-1:0]  LP_Q78_MIN = -16'sd32768;
    localparam signed [LP_DIFF_W-1:0] LP_DIFF_MAX = 17'sd32767;
    localparam signed [LP_DIFF_W-1:0] LP_DIFF_MIN = -17'sd32768;

    reg signed [LP_DIFF_W-1:0] diffValue;

    always @* begin
        diffValue = $signed(iDataA) - $signed(iDataB);
        if (diffValue > LP_DIFF_MAX)
            oData = LP_Q78_MAX;
        else if (diffValue < LP_DIFF_MIN)
            oData = LP_Q78_MIN;
        else
            oData = diffValue[LP_Q78_W-1:0];
    end
endmodule
