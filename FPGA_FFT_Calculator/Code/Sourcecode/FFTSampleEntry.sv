`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: FFTSampleEntry
// description: Edits signed decimal keypad samples and commits scaled FFT input values.
// [MODULE_INFO_END]
module FFTSampleEntry #(
    parameter int P_NUM_SAMPLES = 8
) (
    input  logic               iClk,
    input  logic               iRstn,
    input  logic               iEnable,
    input  logic               iCommit,

    input  logic               iKeyValid,
    input  logic               iIsDigit,
    input  logic [3:0]         iDigit,
    input  logic               iIsMinus,
    input  logic               iIsDot,
    input  logic               iIsDel,
    input  logic               iIsNext,
    input  logic               iIsPrev,
    input  logic               iIsEsc,

    output logic signed [20:0] oSample0,
    output logic signed [20:0] oSample1,
    output logic signed [20:0] oSample2,
    output logic signed [20:0] oSample3,
    output logic signed [20:0] oSample4,
    output logic signed [20:0] oSample5,
    output logic signed [20:0] oSample6,
    output logic signed [20:0] oSample7,

    output logic [31:0]        oDisplayBcd,
    output logic [7:0]         oDotMask,
    output logic [7:0]         oIndex
);

    logic [2:0]         CurSample;
    logic [7:0]         SampleSign;
    logic [7:0]         DpFlag;
    logic [1:0]         IntLen [0:P_NUM_SAMPLES-1];
    logic [1:0]         FracLen [0:P_NUM_SAMPLES-1];
    logic [11:0]        IntBcd [0:P_NUM_SAMPLES-1];
    logic [11:0]        FracBcd [0:P_NUM_SAMPLES-1];
    logic signed [20:0] SampleScaled [0:P_NUM_SAMPLES-1];
    logic [20:0]        SampleAbsScaled [0:P_NUM_SAMPLES-1];

    logic [7:0]  DpLocal;
    logic        SignCur;
    logic [1:0]  IntLenCur;
    logic [1:0]  FracLenCur;
    logic        DpFlagCur;
    logic [3:0]  DigitValue;
    logic [3:0]  Sym [0:7];

    integer idxSample;
    integer idxCalc;
    integer idxToken;
    integer idxSymbol;
    integer idxIntDigit;
    integer idxFracDigit;
    integer DisplayWidth;
    integer DotToken;
    integer DotSymbol;

    assign oSample0 = SampleScaled[0];
    assign oSample1 = SampleScaled[1];
    assign oSample2 = SampleScaled[2];
    assign oSample3 = SampleScaled[3];
    assign oSample4 = SampleScaled[4];
    assign oSample5 = SampleScaled[5];
    assign oSample6 = SampleScaled[6];
    assign oSample7 = SampleScaled[7];
    assign oIndex   = ~(8'b0000_0001 << CurSample);

    function automatic logic [9:0] CalcIntPart(
        input logic [11:0] Bcd,
        input logic [1:0]  Len
    );
        logic [3:0] Digit0;
        logic [3:0] Digit1;
        logic [3:0] Digit2;
        begin
            Digit0 = Bcd[11:8];
            Digit1 = Bcd[7:4];
            Digit2 = Bcd[3:0];

            unique case (Len)
                2'd0:    CalcIntPart = 10'd0;
                2'd1:    CalcIntPart = Digit0;
                2'd2:    CalcIntPart = (Digit0 * 10'd10) + Digit1;
                default: CalcIntPart = (Digit0 * 10'd100) + (Digit1 * 10'd10) + Digit2;
            endcase
        end
    endfunction

    function automatic logic [9:0] CalcFracPart(
        input logic [11:0] Bcd,
        input logic [1:0]  Len
    );
        logic [3:0] Digit0;
        logic [3:0] Digit1;
        logic [3:0] Digit2;
        begin
            Digit0 = Bcd[11:8];
            Digit1 = Bcd[7:4];
            Digit2 = Bcd[3:0];

            unique case (Len)
                2'd0:    CalcFracPart = 10'd0;
                2'd1:    CalcFracPart = Digit0 * 10'd100;
                2'd2:    CalcFracPart = (Digit0 * 10'd100) + (Digit1 * 10'd10);
                default: CalcFracPart = (Digit0 * 10'd100) + (Digit1 * 10'd10) + Digit2;
            endcase
        end
    endfunction

    function automatic logic [20:0] CalcSampleAbsScaled(
        input logic [11:0] IntBcdValue,
        input logic [11:0] FracBcdValue,
        input logic [1:0]  IntLenValue,
        input logic [1:0]  FracLenValue
    );
        logic [9:0]  IntPart;
        logic [9:0]  FracPart;
        logic [20:0] IntWide;
        logic [20:0] Scaled;
        begin
            IntPart = CalcIntPart(IntBcdValue, IntLenValue);
            FracPart = CalcFracPart(FracBcdValue, FracLenValue);
            IntWide = {11'd0, IntPart};
            Scaled = (IntWide << 10) - (IntWide << 4) - (IntWide << 3);
            CalcSampleAbsScaled = Scaled + FracPart;
        end
    endfunction

    always_comb begin
        for (idxCalc = 0; idxCalc < P_NUM_SAMPLES; idxCalc = idxCalc + 1) begin
            SampleAbsScaled[idxCalc] = CalcSampleAbsScaled(
                IntBcd[idxCalc],
                FracBcd[idxCalc],
                IntLen[idxCalc],
                FracLen[idxCalc]
            );
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            CurSample  <= '0;
            SampleSign <= '0;
            DpFlag     <= '0;

            for (idxSample = 0; idxSample < P_NUM_SAMPLES; idxSample = idxSample + 1) begin
                IntLen[idxSample]       <= '0;
                FracLen[idxSample]      <= '0;
                IntBcd[idxSample]       <= '0;
                FracBcd[idxSample]      <= '0;
                SampleScaled[idxSample] <= '0;
            end
        end else begin
            if (iEnable && iKeyValid) begin
                if (iIsDigit) begin
                    if (!DpFlag[CurSample]) begin
                        if (IntLen[CurSample] < 2'd3) begin
                            unique case (IntLen[CurSample])
                                2'd0:    IntBcd[CurSample][11:8] <= iDigit;
                                2'd1:    IntBcd[CurSample][7:4]  <= iDigit;
                                2'd2:    IntBcd[CurSample][3:0]  <= iDigit;
                                default: begin
                                end
                            endcase
                            IntLen[CurSample] <= IntLen[CurSample] + 2'd1;
                        end
                    end else begin
                        if (FracLen[CurSample] < 2'd3) begin
                            unique case (FracLen[CurSample])
                                2'd0:    FracBcd[CurSample][11:8] <= iDigit;
                                2'd1:    FracBcd[CurSample][7:4]  <= iDigit;
                                2'd2:    FracBcd[CurSample][3:0]  <= iDigit;
                                default: begin
                                end
                            endcase
                            FracLen[CurSample] <= FracLen[CurSample] + 2'd1;
                        end
                    end
                end else if (iIsMinus) begin
                    SampleSign[CurSample] <= ~SampleSign[CurSample];
                end else if (iIsDot) begin
                    DpFlag[CurSample] <= 1'b1;
                end else if (iIsDel) begin
                    if (FracLen[CurSample] > 2'd0) begin
                        unique case (FracLen[CurSample])
                            2'd1:    FracBcd[CurSample][11:8] <= 4'd0;
                            2'd2:    FracBcd[CurSample][7:4]  <= 4'd0;
                            2'd3:    FracBcd[CurSample][3:0]  <= 4'd0;
                            default: begin
                            end
                        endcase
                        FracLen[CurSample] <= FracLen[CurSample] - 2'd1;
                    end else if (DpFlag[CurSample]) begin
                        DpFlag[CurSample] <= 1'b0;
                    end else if (IntLen[CurSample] > 2'd0) begin
                        unique case (IntLen[CurSample])
                            2'd1:    IntBcd[CurSample][11:8] <= 4'd0;
                            2'd2:    IntBcd[CurSample][7:4]  <= 4'd0;
                            2'd3:    IntBcd[CurSample][3:0]  <= 4'd0;
                            default: begin
                            end
                        endcase
                        IntLen[CurSample] <= IntLen[CurSample] - 2'd1;
                    end
                end else if (iIsNext) begin
                    CurSample <= (CurSample == 3'd7) ? 3'd0 : (CurSample + 3'd1);
                end else if (iIsPrev) begin
                    CurSample <= (CurSample == 3'd0) ? 3'd7 : (CurSample - 3'd1);
                end else if (iIsEsc) begin
                    SampleSign <= '0;
                    DpFlag     <= '0;
                    CurSample  <= '0;
                    for (idxSample = 0; idxSample < P_NUM_SAMPLES; idxSample = idxSample + 1) begin
                        IntLen[idxSample]  <= '0;
                        FracLen[idxSample] <= '0;
                        IntBcd[idxSample]  <= '0;
                        FracBcd[idxSample] <= '0;
                    end
                end
            end

            if (iCommit) begin
                for (idxSample = 0; idxSample < P_NUM_SAMPLES; idxSample = idxSample + 1) begin
                    if (SampleAbsScaled[idxSample] == 21'd0) begin
                        SampleScaled[idxSample] <= '0;
                    end else if (SampleSign[idxSample]) begin
                        SampleScaled[idxSample] <= -$signed(SampleAbsScaled[idxSample]);
                    end else begin
                        SampleScaled[idxSample] <= $signed(SampleAbsScaled[idxSample]);
                    end
                end
            end
        end
    end

    always_comb begin
        oDisplayBcd  = '0;
        oDotMask     = '0;
        DpLocal      = '0;
        SignCur      = SampleSign[CurSample];
        IntLenCur    = IntLen[CurSample];
        FracLenCur   = FracLen[CurSample];
        DpFlagCur    = DpFlag[CurSample];
        DigitValue   = '0;
        DisplayWidth = IntLenCur + FracLenCur + (SignCur ? 1 : 0);
        DotToken     = 0;
        DotSymbol    = 0;
        idxSymbol    = 0;
        idxIntDigit  = 0;
        idxFracDigit = 0;

        for (idxToken = 0; idxToken < 8; idxToken = idxToken + 1) begin
            Sym[idxToken] = 4'hB;
        end

        if (DisplayWidth != 0) begin
            for (idxToken = 0; idxToken < 8; idxToken = idxToken + 1) begin
                if (idxToken < DisplayWidth) begin
                    idxSymbol = DisplayWidth - 1 - idxToken;

                    if (SignCur && (idxToken == 0)) begin
                        Sym[idxSymbol] = 4'hA;
                    end else if ((idxToken >= (SignCur ? 1 : 0)) &&
                                 (idxToken < ((SignCur ? 1 : 0) + IntLenCur))) begin
                        idxIntDigit = idxToken - (SignCur ? 1 : 0);
                        unique case (idxIntDigit)
                            0:       DigitValue = IntBcd[CurSample][11:8];
                            1:       DigitValue = IntBcd[CurSample][7:4];
                            2:       DigitValue = IntBcd[CurSample][3:0];
                            default: DigitValue = 4'd0;
                        endcase
                        Sym[idxSymbol] = DigitValue;
                    end else begin
                        idxFracDigit = idxToken - (SignCur ? 1 : 0) - IntLenCur;
                        if ((idxFracDigit >= 0) && (idxFracDigit < FracLenCur)) begin
                            unique case (idxFracDigit)
                                0:       DigitValue = FracBcd[CurSample][11:8];
                                1:       DigitValue = FracBcd[CurSample][7:4];
                                2:       DigitValue = FracBcd[CurSample][3:0];
                                default: DigitValue = 4'd0;
                            endcase
                            Sym[idxSymbol] = DigitValue;
                        end
                    end
                end
            end

            if (DpFlagCur && (IntLenCur > 2'd0)) begin
                DotToken  = (SignCur ? 1 : 0) + IntLenCur - 1;
                DotSymbol = DisplayWidth - 1 - DotToken;
                if ((DotSymbol >= 0) && (DotSymbol < 8)) begin
                    DpLocal[7 - DotSymbol] = 1'b1;
                end
            end
        end

        oDisplayBcd[31:28] = Sym[7];
        oDisplayBcd[27:24] = Sym[6];
        oDisplayBcd[23:20] = Sym[5];
        oDisplayBcd[19:16] = Sym[4];
        oDisplayBcd[15:12] = Sym[3];
        oDisplayBcd[11:8]  = Sym[2];
        oDisplayBcd[7:4]   = Sym[1];
        oDisplayBcd[3:0]   = Sym[0];
        oDotMask           = DpLocal;
    end

endmodule
