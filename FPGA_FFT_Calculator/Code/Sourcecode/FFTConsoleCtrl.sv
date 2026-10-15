`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFTConsoleCtrl
// description: Moore FSM controller for FFT console input, execution, and result display phases.
// [MODULE_INFO_END]
module FFTConsoleCtrl (
    input  logic        iClk,
    input  logic        iRstn,

    input  logic        iKeyValid,
    input  logic        iIsEnt,
    input  logic        iIsEsc,

    input  logic        iFFTBusy,
    input  logic        iFFTDone,

    input  logic [31:0] iInputDisplayBcd,
    input  logic [7:0]  iInputDotMask,
    input  logic [7:0]  iInputIndex,
    input  logic [31:0] iResultDisplayBcd,
    input  logic [7:0]  iResultDotMask,
    input  logic [7:0]  iResultIndex,
    input  logic        iResultReIm,

    output logic        oInputEnable,
    output logic        oInputCommit,
    output logic        oResultEnable,
    output logic        oResultInit,

    output logic        oFFTStart,
    output logic        oFFT,
    output logic        oReIm,
    output logic [31:0] oDisplayBcd,
    output logic [7:0]  oDotMask,
    output logic [7:0]  oIndex
);

    typedef enum logic [2:0] {
        INPUT,
        COMMIT_INPUT,
        START_FFT,
        WAIT_FFT,
        INIT_OUTPUT,
        OUTPUT
    } state_e;

    state_e State;
    state_e State_d;

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            State <= INPUT;
        end else begin
            State <= State_d;
        end
    end

    always_comb begin
        State_d = State;

        unique case (State)
            INPUT: begin
                if (iKeyValid && iIsEnt && !iFFTBusy) begin
                    State_d = COMMIT_INPUT;
                end
            end

            COMMIT_INPUT: begin
                State_d = START_FFT;
            end

            START_FFT: begin
                State_d = WAIT_FFT;
            end

            WAIT_FFT: begin
                if (iFFTDone) begin
                    State_d = INIT_OUTPUT;
                end
            end

            INIT_OUTPUT: begin
                State_d = OUTPUT;
            end

            OUTPUT: begin
                if (iKeyValid && iIsEsc) begin
                    State_d = INPUT;
                end
            end

            default: begin
                State_d = INPUT;
            end
        endcase
    end

    always_comb begin
        oInputEnable  = 1'b0;
        oInputCommit  = 1'b0;
        oResultEnable = 1'b0;
        oResultInit   = 1'b0;
        oFFTStart     = 1'b0;
        oFFT          = 1'b0;
        oReIm         = 1'b1;
        oDisplayBcd   = iResultDisplayBcd;
        oDotMask      = iResultDotMask;
        oIndex        = iInputIndex;

        unique case (State)
            INPUT: begin
                oInputEnable = 1'b1;
                oFFT         = 1'b1;
                oDisplayBcd  = iInputDisplayBcd;
                oDotMask     = iInputDotMask;
                oIndex       = iInputIndex;
            end

            COMMIT_INPUT: begin
                oInputCommit = 1'b1;
                oFFT         = 1'b1;
                oDisplayBcd  = iInputDisplayBcd;
                oDotMask     = iInputDotMask;
                oIndex       = iInputIndex;
            end

            START_FFT: begin
                oFFTStart = 1'b1;
            end

            WAIT_FFT: begin
            end

            INIT_OUTPUT: begin
                oResultInit = 1'b1;
                oIndex      = iResultIndex;
            end

            OUTPUT: begin
                oResultEnable = 1'b1;
                oReIm         = iResultReIm;
                oIndex        = iResultIndex;
            end

            default: begin
                oInputEnable = 1'b1;
                oFFT         = 1'b1;
                oDisplayBcd  = iInputDisplayBcd;
                oDotMask     = iInputDotMask;
                oIndex       = iInputIndex;
            end
        endcase
    end

endmodule
