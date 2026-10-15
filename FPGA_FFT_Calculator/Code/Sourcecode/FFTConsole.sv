`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFTConsole
// description: User console wrapper for FFT sample entry, FFT run control, and result display.
// [MODULE_INFO_END]
module FFTConsole #(
    parameter int P_NUM_SAMPLES = 8
) (
    input  logic               iClk,
    input  logic               iRstn,

    input  logic               iKeyValid,
    input  logic               iIsDigit,
    input  logic [3:0]         iDigit,
    input  logic               iIsMinus,
    input  logic               iIsDot,
    input  logic               iIsDel,
    input  logic               iIsNext,
    input  logic               iIsPrev,
    input  logic               iIsToggleRi,
    input  logic               iIsEnt,
    input  logic               iIsEsc,

    output logic               oFFTStart,
    input  logic               iFFTBusy,
    input  logic               iFFTDone,

    output logic signed [20:0] oSample0,
    output logic signed [20:0] oSample1,
    output logic signed [20:0] oSample2,
    output logic signed [20:0] oSample3,
    output logic signed [20:0] oSample4,
    output logic signed [20:0] oSample5,
    output logic signed [20:0] oSample6,
    output logic signed [20:0] oSample7,

    input  logic signed [31:0] iBin0Re,
    input  logic signed [31:0] iBin0Im,
    input  logic signed [31:0] iBin1Re,
    input  logic signed [31:0] iBin1Im,
    input  logic signed [31:0] iBin2Re,
    input  logic signed [31:0] iBin2Im,
    input  logic signed [31:0] iBin3Re,
    input  logic signed [31:0] iBin3Im,
    input  logic signed [31:0] iBin4Re,
    input  logic signed [31:0] iBin4Im,
    input  logic signed [31:0] iBin5Re,
    input  logic signed [31:0] iBin5Im,
    input  logic signed [31:0] iBin6Re,
    input  logic signed [31:0] iBin6Im,
    input  logic signed [31:0] iBin7Re,
    input  logic signed [31:0] iBin7Im,

    output logic [31:0]        oDisplayBcd,
    output logic [7:0]         oDotMask,
    output logic [7:0]         oIndex,
    output logic               oFFT,
    output logic               oReIm
);

    logic        InputEnable;
    logic        InputCommit;
    logic [31:0] InputDisplayBcd;
    logic [7:0]  InputDotMask;
    logic [7:0]  InputIndex;

    logic        ResultEnable;
    logic        ResultInit;
    logic [31:0] ResultDisplayBcd;
    logic [7:0]  ResultDotMask;
    logic [7:0]  ResultIndex;
    logic        ResultReIm;

    FFTConsoleCtrl uFFTConsoleCtrl (
        .iClk              (iClk),
        .iRstn             (iRstn),
        .iKeyValid         (iKeyValid),
        .iIsEnt            (iIsEnt),
        .iIsEsc            (iIsEsc),
        .iFFTBusy          (iFFTBusy),
        .iFFTDone          (iFFTDone),
        .iInputDisplayBcd  (InputDisplayBcd),
        .iInputDotMask     (InputDotMask),
        .iInputIndex       (InputIndex),
        .iResultDisplayBcd (ResultDisplayBcd),
        .iResultDotMask    (ResultDotMask),
        .iResultIndex      (ResultIndex),
        .iResultReIm       (ResultReIm),
        .oInputEnable      (InputEnable),
        .oInputCommit      (InputCommit),
        .oResultEnable     (ResultEnable),
        .oResultInit       (ResultInit),
        .oFFTStart         (oFFTStart),
        .oFFT              (oFFT),
        .oReIm             (oReIm),
        .oDisplayBcd       (oDisplayBcd),
        .oDotMask          (oDotMask),
        .oIndex            (oIndex)
    );

    FFTSampleEntry #(
        .P_NUM_SAMPLES(P_NUM_SAMPLES)
    ) uFFTSampleEntry (
        .iClk        (iClk),
        .iRstn       (iRstn),
        .iEnable     (InputEnable),
        .iCommit     (InputCommit),
        .iKeyValid   (iKeyValid),
        .iIsDigit    (iIsDigit),
        .iDigit      (iDigit),
        .iIsMinus    (iIsMinus),
        .iIsDot      (iIsDot),
        .iIsDel      (iIsDel),
        .iIsNext     (iIsNext),
        .iIsPrev     (iIsPrev),
        .iIsEsc      (iIsEsc),
        .oSample0    (oSample0),
        .oSample1    (oSample1),
        .oSample2    (oSample2),
        .oSample3    (oSample3),
        .oSample4    (oSample4),
        .oSample5    (oSample5),
        .oSample6    (oSample6),
        .oSample7    (oSample7),
        .oDisplayBcd (InputDisplayBcd),
        .oDotMask    (InputDotMask),
        .oIndex      (InputIndex)
    );

    FFTResultDisplay uFFTResultDisplay (
        .iClk        (iClk),
        .iRstn       (iRstn),
        .iEnable     (ResultEnable),
        .iInit       (ResultInit),
        .iKeyValid   (iKeyValid),
        .iIsNext     (iIsNext),
        .iIsPrev     (iIsPrev),
        .iIsToggleRi (iIsToggleRi),
        .iBin0Re     (iBin0Re),
        .iBin0Im     (iBin0Im),
        .iBin1Re     (iBin1Re),
        .iBin1Im     (iBin1Im),
        .iBin2Re     (iBin2Re),
        .iBin2Im     (iBin2Im),
        .iBin3Re     (iBin3Re),
        .iBin3Im     (iBin3Im),
        .iBin4Re     (iBin4Re),
        .iBin4Im     (iBin4Im),
        .iBin5Re     (iBin5Re),
        .iBin5Im     (iBin5Im),
        .iBin6Re     (iBin6Re),
        .iBin6Im     (iBin6Im),
        .iBin7Re     (iBin7Re),
        .iBin7Im     (iBin7Im),
        .oDisplayBcd (ResultDisplayBcd),
        .oDotMask    (ResultDotMask),
        .oIndex      (ResultIndex),
        .oReIm       (ResultReIm)
    );

endmodule
