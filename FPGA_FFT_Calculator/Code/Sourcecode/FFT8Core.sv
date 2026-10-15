`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFT8Core
// description: Wrapper for 8-point real-input radix-2 DIF FFT control and datapath blocks.
// [MODULE_INFO_END]
module FFT8Core (
    input  logic               iClk,
    input  logic               iRstn,
    input  logic               iStart,

    input  logic signed [20:0] iSample0,
    input  logic signed [20:0] iSample1,
    input  logic signed [20:0] iSample2,
    input  logic signed [20:0] iSample3,
    input  logic signed [20:0] iSample4,
    input  logic signed [20:0] iSample5,
    input  logic signed [20:0] iSample6,
    input  logic signed [20:0] iSample7,

    output logic               oBusy,
    output logic               oDone,

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

    logic InputLatchEn;
    logic OutputLatchEn;

    logic signed [31:0] Sample0;
    logic signed [31:0] Sample1;
    logic signed [31:0] Sample2;
    logic signed [31:0] Sample3;
    logic signed [31:0] Sample4;
    logic signed [31:0] Sample5;
    logic signed [31:0] Sample6;
    logic signed [31:0] Sample7;

    logic signed [31:0] Stage3Re0;
    logic signed [31:0] Stage3Im0;
    logic signed [31:0] Stage3Re1;
    logic signed [31:0] Stage3Im1;
    logic signed [31:0] Stage3Re2;
    logic signed [31:0] Stage3Im2;
    logic signed [31:0] Stage3Re3;
    logic signed [31:0] Stage3Im3;
    logic signed [31:0] Stage3Re4;
    logic signed [31:0] Stage3Im4;
    logic signed [31:0] Stage3Re5;
    logic signed [31:0] Stage3Im5;
    logic signed [31:0] Stage3Re6;
    logic signed [31:0] Stage3Im6;
    logic signed [31:0] Stage3Re7;
    logic signed [31:0] Stage3Im7;

    FFT8CoreCtrl uFFT8CoreCtrl (
        .iClk           (iClk),
        .iRstn          (iRstn),
        .iStart         (iStart),
        .oInputLatchEn  (InputLatchEn),
        .oOutputLatchEn (OutputLatchEn),
        .oBusy          (oBusy),
        .oDone          (oDone)
    );

    FFT8InputLatch uFFT8InputLatch (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iLatchEn   (InputLatchEn),
        .iSample0   (iSample0),
        .iSample1   (iSample1),
        .iSample2   (iSample2),
        .iSample3   (iSample3),
        .iSample4   (iSample4),
        .iSample5   (iSample5),
        .iSample6   (iSample6),
        .iSample7   (iSample7),
        .oSample0   (Sample0),
        .oSample1   (Sample1),
        .oSample2   (Sample2),
        .oSample3   (Sample3),
        .oSample4   (Sample4),
        .oSample5   (Sample5),
        .oSample6   (Sample6),
        .oSample7   (Sample7)
    );

    FFT8DifDatapath uFFT8DifDatapath (
        .iSample0   (Sample0),
        .iSample1   (Sample1),
        .iSample2   (Sample2),
        .iSample3   (Sample3),
        .iSample4   (Sample4),
        .iSample5   (Sample5),
        .iSample6   (Sample6),
        .iSample7   (Sample7),
        .oStage3Re0 (Stage3Re0),
        .oStage3Im0 (Stage3Im0),
        .oStage3Re1 (Stage3Re1),
        .oStage3Im1 (Stage3Im1),
        .oStage3Re2 (Stage3Re2),
        .oStage3Im2 (Stage3Im2),
        .oStage3Re3 (Stage3Re3),
        .oStage3Im3 (Stage3Im3),
        .oStage3Re4 (Stage3Re4),
        .oStage3Im4 (Stage3Im4),
        .oStage3Re5 (Stage3Re5),
        .oStage3Im5 (Stage3Im5),
        .oStage3Re6 (Stage3Re6),
        .oStage3Im6 (Stage3Im6),
        .oStage3Re7 (Stage3Re7),
        .oStage3Im7 (Stage3Im7)
    );

    FFT8OutputLatch uFFT8OutputLatch (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iLatchEn   (OutputLatchEn),
        .iStage3Re0 (Stage3Re0),
        .iStage3Im0 (Stage3Im0),
        .iStage3Re1 (Stage3Re1),
        .iStage3Im1 (Stage3Im1),
        .iStage3Re2 (Stage3Re2),
        .iStage3Im2 (Stage3Im2),
        .iStage3Re3 (Stage3Re3),
        .iStage3Im3 (Stage3Im3),
        .iStage3Re4 (Stage3Re4),
        .iStage3Im4 (Stage3Im4),
        .iStage3Re5 (Stage3Re5),
        .iStage3Im5 (Stage3Im5),
        .iStage3Re6 (Stage3Re6),
        .iStage3Im6 (Stage3Im6),
        .iStage3Re7 (Stage3Re7),
        .iStage3Im7 (Stage3Im7),
        .oBin0Re    (oBin0Re),
        .oBin0Im    (oBin0Im),
        .oBin1Re    (oBin1Re),
        .oBin1Im    (oBin1Im),
        .oBin2Re    (oBin2Re),
        .oBin2Im    (oBin2Im),
        .oBin3Re    (oBin3Re),
        .oBin3Im    (oBin3Im),
        .oBin4Re    (oBin4Re),
        .oBin4Im    (oBin4Im),
        .oBin5Re    (oBin5Re),
        .oBin5Im    (oBin5Im),
        .oBin6Re    (oBin6Re),
        .oBin6Im    (oBin6Im),
        .oBin7Re    (oBin7Re),
        .oBin7Im    (oBin7Im)
    );

endmodule
