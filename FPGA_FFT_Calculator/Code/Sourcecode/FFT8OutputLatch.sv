`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFT8OutputLatch
// description: Latches bit-reversed FFT datapath results into natural-order output bins.
// [MODULE_INFO_END]
module FFT8OutputLatch (
    input  logic               iClk,
    input  logic               iRstn,
    input  logic               iLatchEn,

    input  logic signed [31:0] iStage3Re0,
    input  logic signed [31:0] iStage3Im0,
    input  logic signed [31:0] iStage3Re1,
    input  logic signed [31:0] iStage3Im1,
    input  logic signed [31:0] iStage3Re2,
    input  logic signed [31:0] iStage3Im2,
    input  logic signed [31:0] iStage3Re3,
    input  logic signed [31:0] iStage3Im3,
    input  logic signed [31:0] iStage3Re4,
    input  logic signed [31:0] iStage3Im4,
    input  logic signed [31:0] iStage3Re5,
    input  logic signed [31:0] iStage3Im5,
    input  logic signed [31:0] iStage3Re6,
    input  logic signed [31:0] iStage3Im6,
    input  logic signed [31:0] iStage3Re7,
    input  logic signed [31:0] iStage3Im7,

    output logic signed [31:0] oBin0Re,
    output logic signed [31:0] oBin0Im,
    output logic signed [31:0] oBin1Re,
    output logic signed [31:0] oBin1Im,
    output logic signed [31:0] oBin2Re,
    output logic signed [31:0] oBin2Im,
    output logic signed [31:0] oBin3Re,
    output logic signed [31:0] oBin3Im,
    output logic signed [31:0] oBin4Re,
    output logic signed [31:0] oBin4Im,
    output logic signed [31:0] oBin5Re,
    output logic signed [31:0] oBin5Im,
    output logic signed [31:0] oBin6Re,
    output logic signed [31:0] oBin6Im,
    output logic signed [31:0] oBin7Re,
    output logic signed [31:0] oBin7Im
);

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oBin0Re <= '0;
            oBin0Im <= '0;
            oBin1Re <= '0;
            oBin1Im <= '0;
            oBin2Re <= '0;
            oBin2Im <= '0;
            oBin3Re <= '0;
            oBin3Im <= '0;
            oBin4Re <= '0;
            oBin4Im <= '0;
            oBin5Re <= '0;
            oBin5Im <= '0;
            oBin6Re <= '0;
            oBin6Im <= '0;
            oBin7Re <= '0;
            oBin7Im <= '0;
        end else if (iLatchEn) begin
            oBin0Re <= iStage3Re0;
            oBin0Im <= iStage3Im0;
            oBin1Re <= iStage3Re4;
            oBin1Im <= iStage3Im4;
            oBin2Re <= iStage3Re2;
            oBin2Im <= iStage3Im2;
            oBin3Re <= iStage3Re6;
            oBin3Im <= iStage3Im6;
            oBin4Re <= iStage3Re1;
            oBin4Im <= iStage3Im1;
            oBin5Re <= iStage3Re5;
            oBin5Im <= iStage3Im5;
            oBin6Re <= iStage3Re3;
            oBin6Im <= iStage3Im3;
            oBin7Re <= iStage3Re7;
            oBin7Im <= iStage3Im7;
        end
    end

endmodule
