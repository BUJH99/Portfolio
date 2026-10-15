`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFTResultDisplay
// description: Selects FFT result bins and formats signed output values for display.
// [MODULE_INFO_END]
module FFTResultDisplay (
    input  logic               iClk,
    input  logic               iRstn,
    input  logic               iEnable,
    input  logic               iInit,

    input  logic               iKeyValid,
    input  logic               iIsNext,
    input  logic               iIsPrev,
    input  logic               iIsToggleRi,

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
    output logic               oReIm
);

    logic [2:0]         CurBin;
    logic               ShowImag;
    logic signed [31:0] CurValOut;
    logic               CurSignRaw;
    logic [31:0]        CurAbsRaw;
    logic [31:0]        CurAbsSat;

    logic        BcdStart;
    logic        BcdBusy;
    logic        BcdDone;
    logic [27:0] Bcd7Value;
    logic [27:0] DispBcd7;
    logic        DispSign;
    logic        StartReqSign;
    logic        StartReqZero;

    assign CurSignRaw = CurValOut[31];
    assign CurAbsRaw  = CurSignRaw ? (~CurValOut + 32'd1) : CurValOut;
    assign CurAbsSat  = (CurAbsRaw > 32'd9_999_999) ? 32'd9_999_999 : CurAbsRaw;
    assign oIndex     = ~(8'b0000_0001 << CurBin);
    assign oReIm      = ShowImag ? 1'b0 : 1'b1;

    BinToBcd7 uBinToBcd7 (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iStart (BcdStart),
        .iValue (CurAbsSat[23:0]),
        .oBusy  (BcdBusy),
        .oDone  (BcdDone),
        .oBcd7  (Bcd7Value)
    );

    always_comb begin
        unique case (CurBin)
            3'd0:    CurValOut = ShowImag ? iBin0Im : iBin0Re;
            3'd1:    CurValOut = ShowImag ? iBin1Im : iBin1Re;
            3'd2:    CurValOut = ShowImag ? iBin2Im : iBin2Re;
            3'd3:    CurValOut = ShowImag ? iBin3Im : iBin3Re;
            3'd4:    CurValOut = ShowImag ? iBin4Im : iBin4Re;
            3'd5:    CurValOut = ShowImag ? iBin5Im : iBin5Re;
            3'd6:    CurValOut = ShowImag ? iBin6Im : iBin6Re;
            3'd7:    CurValOut = ShowImag ? iBin7Im : iBin7Re;
            default: CurValOut = '0;
        endcase
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            CurBin   <= '0;
            ShowImag <= 1'b0;
        end else begin
            if (iInit) begin
                CurBin   <= '0;
                ShowImag <= 1'b0;
            end else if (iEnable && iKeyValid) begin
                if (iIsNext) begin
                    CurBin <= (CurBin == 3'd7) ? 3'd0 : (CurBin + 3'd1);
                end else if (iIsPrev) begin
                    CurBin <= (CurBin == 3'd0) ? 3'd7 : (CurBin - 3'd1);
                end else if (iIsToggleRi) begin
                    ShowImag <= ~ShowImag;
                end
            end
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            BcdStart     <= 1'b0;
            DispBcd7     <= '0;
            DispSign     <= 1'b0;
            StartReqSign <= 1'b0;
            StartReqZero <= 1'b1;
        end else begin
            BcdStart <= 1'b0;

            if (iInit) begin
                DispBcd7     <= '0;
                DispSign     <= 1'b0;
                StartReqSign <= 1'b0;
                StartReqZero <= 1'b1;
            end else begin
                if (iEnable && !BcdBusy) begin
                    BcdStart     <= 1'b1;
                    StartReqSign <= CurSignRaw;
                    StartReqZero <= (CurAbsSat == 32'd0);
                end

                if (BcdDone) begin
                    DispBcd7 <= Bcd7Value;
                    DispSign <= StartReqSign & ~StartReqZero;
                end
            end
        end
    end

    always_comb begin
        oDisplayBcd[31:28] = DispSign ? 4'hA : 4'hB;
        oDisplayBcd[27:24] = DispBcd7[27:24];
        oDisplayBcd[23:20] = DispBcd7[23:20];
        oDisplayBcd[19:16] = DispBcd7[19:16];
        oDisplayBcd[15:12] = DispBcd7[15:12];
        oDisplayBcd[11:8]  = DispBcd7[11:8];
        oDisplayBcd[7:4]   = DispBcd7[7:4];
        oDisplayBcd[3:0]   = DispBcd7[3:0];
        oDotMask           = 8'b0001_0000;
    end

endmodule
