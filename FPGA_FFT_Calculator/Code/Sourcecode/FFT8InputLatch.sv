`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFT8InputLatch
// description: Sign-extends and latches 21-bit real input samples into 32-bit datapath samples.
// [MODULE_INFO_END]
module FFT8InputLatch (
    input  logic               iClk,
    input  logic               iRstn,
    input  logic               iLatchEn,

    input  logic signed [20:0] iSample0,
    input  logic signed [20:0] iSample1,
    input  logic signed [20:0] iSample2,
    input  logic signed [20:0] iSample3,
    input  logic signed [20:0] iSample4,
    input  logic signed [20:0] iSample5,
    input  logic signed [20:0] iSample6,
    input  logic signed [20:0] iSample7,

    output logic signed [31:0] oSample0,
    output logic signed [31:0] oSample1,
    output logic signed [31:0] oSample2,
    output logic signed [31:0] oSample3,
    output logic signed [31:0] oSample4,
    output logic signed [31:0] oSample5,
    output logic signed [31:0] oSample6,
    output logic signed [31:0] oSample7
);

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oSample0 <= '0;
            oSample1 <= '0;
            oSample2 <= '0;
            oSample3 <= '0;
            oSample4 <= '0;
            oSample5 <= '0;
            oSample6 <= '0;
            oSample7 <= '0;
        end else if (iLatchEn) begin
            oSample0 <= {{11{iSample0[20]}}, iSample0};
            oSample1 <= {{11{iSample1[20]}}, iSample1};
            oSample2 <= {{11{iSample2[20]}}, iSample2};
            oSample3 <= {{11{iSample3[20]}}, iSample3};
            oSample4 <= {{11{iSample4[20]}}, iSample4};
            oSample5 <= {{11{iSample5[20]}}, iSample5};
            oSample6 <= {{11{iSample6[20]}}, iSample6};
            oSample7 <= {{11{iSample7[20]}}, iSample7};
        end
    end

endmodule
