`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: TOP
// description: Top-level wrapper for keypad input, FFT calculation, and display output.
// [MODULE_INFO_END]
module TOP (
    input  logic       iRstn,
    input  logic       iClk,

    input  logic [4:0] iKeyIn,
    output logic [3:0] oKeyOut,

    output logic [7:0] oSegCom,
    output logic [7:0] oSegData,

    output logic [7:0] oIndex,
    output logic       oFFT,
    output logic       oReIm
);

    logic Pulse1k;

    logic       KeyValid;

    logic       IsDigit;
    logic [3:0] Digit;
    logic       IsMinus;
    logic       IsDot;
    logic       IsDel;
    logic       IsNext;
    logic       IsPrev;
    logic       IsToggleRi;
    logic       IsEnt;
    logic       IsEsc;

    logic FFTStart;
    logic FFTBusy;
    logic FFTDone;

    logic signed [20:0] Sample0;
    logic signed [20:0] Sample1;
    logic signed [20:0] Sample2;
    logic signed [20:0] Sample3;
    logic signed [20:0] Sample4;
    logic signed [20:0] Sample5;
    logic signed [20:0] Sample6;
    logic signed [20:0] Sample7;

    logic signed [31:0] Bin0Re;
    logic signed [31:0] Bin0Im;
    logic signed [31:0] Bin1Re;
    logic signed [31:0] Bin1Im;
    logic signed [31:0] Bin2Re;
    logic signed [31:0] Bin2Im;
    logic signed [31:0] Bin3Re;
    logic signed [31:0] Bin3Im;
    logic signed [31:0] Bin4Re;
    logic signed [31:0] Bin4Im;
    logic signed [31:0] Bin5Re;
    logic signed [31:0] Bin5Im;
    logic signed [31:0] Bin6Re;
    logic signed [31:0] Bin6Im;
    logic signed [31:0] Bin7Re;
    logic signed [31:0] Bin7Im;

    logic [31:0] DisplayBcd;
    logic [7:0]  DotMask;

    // InputController: ClkPulse, KeyScan, KeycodeDecoder for keypad timing/scan/decode.
    InputController uInputController (
        .iClk        (iClk),
        .iRstn       (iRstn),
        .iKeyIn      (iKeyIn),
        .oKeyOut     (oKeyOut),
        .oPulse1k    (Pulse1k),
        .oKeyValid   (KeyValid),
        .oIsDigit    (IsDigit),
        .oDigit      (Digit),
        .oIsMinus    (IsMinus),
        .oIsDot      (IsDot),
        .oIsDel      (IsDel),
        .oIsNext     (IsNext),
        .oIsPrev     (IsPrev),
        .oIsToggleRi (IsToggleRi),
        .oIsEnt      (IsEnt),
        .oIsEsc      (IsEsc)
    );

    // FFTConsole: FSM control, sample entry, result display, and BCD conversion.
    FFTConsole uFFTConsole (
        .iClk          (iClk),
        .iRstn         (iRstn),
        .iKeyValid     (KeyValid),
        .iIsDigit      (IsDigit),
        .iDigit        (Digit),
        .iIsMinus      (IsMinus),
        .iIsDot        (IsDot),
        .iIsDel        (IsDel),
        .iIsNext       (IsNext),
        .iIsPrev       (IsPrev),
        .iIsToggleRi   (IsToggleRi),
        .iIsEnt        (IsEnt),
        .iIsEsc        (IsEsc),
        .oFFTStart     (FFTStart),
        .iFFTBusy      (FFTBusy),
        .iFFTDone      (FFTDone),
        .oSample0      (Sample0),
        .oSample1      (Sample1),
        .oSample2      (Sample2),
        .oSample3      (Sample3),
        .oSample4      (Sample4),
        .oSample5      (Sample5),
        .oSample6      (Sample6),
        .oSample7      (Sample7),
        .iBin0Re       (Bin0Re),
        .iBin0Im       (Bin0Im),
        .iBin1Re       (Bin1Re),
        .iBin1Im       (Bin1Im),
        .iBin2Re       (Bin2Re),
        .iBin2Im       (Bin2Im),
        .iBin3Re       (Bin3Re),
        .iBin3Im       (Bin3Im),
        .iBin4Re       (Bin4Re),
        .iBin4Im       (Bin4Im),
        .iBin5Re       (Bin5Re),
        .iBin5Im       (Bin5Im),
        .iBin6Re       (Bin6Re),
        .iBin6Im       (Bin6Im),
        .iBin7Re       (Bin7Re),
        .iBin7Im       (Bin7Im),
        .oDisplayBcd   (DisplayBcd),
        .oDotMask      (DotMask),
        .oIndex        (oIndex),
        .oFFT          (oFFT),
        .oReIm         (oReIm)
    );

    // FFT8Core: core FSM, input/output latches, and combinational DIF FFT datapath.
    FFT8Core uFFT8Core (
        .iClk     (iClk),
        .iRstn    (iRstn),
        .iStart   (FFTStart),
        .iSample0 (Sample0),
        .iSample1 (Sample1),
        .iSample2 (Sample2),
        .iSample3 (Sample3),
        .iSample4 (Sample4),
        .iSample5 (Sample5),
        .iSample6 (Sample6),
        .iSample7 (Sample7),
        .oBusy    (FFTBusy),
        .oDone    (FFTDone),
        .oBin0Re  (Bin0Re),
        .oBin0Im  (Bin0Im),
        .oBin1Re  (Bin1Re),
        .oBin1Im  (Bin1Im),
        .oBin2Re  (Bin2Re),
        .oBin2Im  (Bin2Im),
        .oBin3Re  (Bin3Re),
        .oBin3Im  (Bin3Im),
        .oBin4Re  (Bin4Re),
        .oBin4Im  (Bin4Im),
        .oBin5Re  (Bin5Re),
        .oBin5Im  (Bin5Im),
        .oBin6Re  (Bin6Re),
        .oBin6Im  (Bin6Im),
        .oBin7Re  (Bin7Re),
        .oBin7Im  (Bin7Im)
    );

    // Seg8Digit: 1 kHz multiplexed 8-digit seven-segment display scan.
    Seg8Digit uSeg8Digit (
        .iRstn       (iRstn),
        .iClk        (iClk),
        .iPulse1k    (Pulse1k),
        .iDisplayBcd (DisplayBcd),
        .iDotMask    (DotMask),
        .oSegData    (oSegData),
        .oSegCom     (oSegCom)
    );

endmodule
