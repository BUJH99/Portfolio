`timescale 1ns / 1ps

// [MODULE_INFO_START]
// module: TbTop
// description: Directed regression for TOP integration, FFT8Core vectors, and BinToBcd7 conversion.
// [MODULE_INFO_END]
module TbTop;

    localparam int LP_CLK_PERIOD_NS  = 10;
    localparam int LP_SIM_TIMEOUT_NS = 200_000;

    logic iClk;
    logic iRstn;

    logic [4:0] TopKeyIn;
    logic [3:0] TopKeyOut;
    logic [7:0] TopSegCom;
    logic [7:0] TopSegData;
    logic [7:0] TopIndex;
    logic       TopFFT;
    logic       TopReIm;

    logic               CoreStart;
    logic signed [20:0] CoreSample0;
    logic signed [20:0] CoreSample1;
    logic signed [20:0] CoreSample2;
    logic signed [20:0] CoreSample3;
    logic signed [20:0] CoreSample4;
    logic signed [20:0] CoreSample5;
    logic signed [20:0] CoreSample6;
    logic signed [20:0] CoreSample7;
    logic               CoreBusy;
    logic               CoreDone;
    logic signed [31:0] CoreBin0Re;
    logic signed [31:0] CoreBin0Im;
    logic signed [31:0] CoreBin1Re;
    logic signed [31:0] CoreBin1Im;
    logic signed [31:0] CoreBin2Re;
    logic signed [31:0] CoreBin2Im;
    logic signed [31:0] CoreBin3Re;
    logic signed [31:0] CoreBin3Im;
    logic signed [31:0] CoreBin4Re;
    logic signed [31:0] CoreBin4Im;
    logic signed [31:0] CoreBin5Re;
    logic signed [31:0] CoreBin5Im;
    logic signed [31:0] CoreBin6Re;
    logic signed [31:0] CoreBin6Im;
    logic signed [31:0] CoreBin7Re;
    logic signed [31:0] CoreBin7Im;

    logic        BcdStart;
    logic [23:0] BcdValue;
    logic        BcdBusy;
    logic        BcdDone;
    logic [27:0] Bcd7;

    int unsigned ErrorCnt;

    TOP uDutTopSmoke (
        .iRstn    (iRstn),
        .iClk     (iClk),
        .iKeyIn   (TopKeyIn),
        .oKeyOut  (TopKeyOut),
        .oSegCom  (TopSegCom),
        .oSegData (TopSegData),
        .oIndex   (TopIndex),
        .oFFT     (TopFFT),
        .oReIm    (TopReIm)
    );

    FFT8Core uDutFFT8Core (
        .iClk     (iClk),
        .iRstn    (iRstn),
        .iStart   (CoreStart),
        .iSample0 (CoreSample0),
        .iSample1 (CoreSample1),
        .iSample2 (CoreSample2),
        .iSample3 (CoreSample3),
        .iSample4 (CoreSample4),
        .iSample5 (CoreSample5),
        .iSample6 (CoreSample6),
        .iSample7 (CoreSample7),
        .oBusy    (CoreBusy),
        .oDone    (CoreDone),
        .oBin0Re  (CoreBin0Re),
        .oBin0Im  (CoreBin0Im),
        .oBin1Re  (CoreBin1Re),
        .oBin1Im  (CoreBin1Im),
        .oBin2Re  (CoreBin2Re),
        .oBin2Im  (CoreBin2Im),
        .oBin3Re  (CoreBin3Re),
        .oBin3Im  (CoreBin3Im),
        .oBin4Re  (CoreBin4Re),
        .oBin4Im  (CoreBin4Im),
        .oBin5Re  (CoreBin5Re),
        .oBin5Im  (CoreBin5Im),
        .oBin6Re  (CoreBin6Re),
        .oBin6Im  (CoreBin6Im),
        .oBin7Re  (CoreBin7Re),
        .oBin7Im  (CoreBin7Im)
    );

    BinToBcd7 uDutBinToBcd7 (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iStart (BcdStart),
        .iValue (BcdValue),
        .oBusy  (BcdBusy),
        .oDone  (BcdDone),
        .oBcd7  (Bcd7)
    );

    initial begin : bClockGen
        iClk = 1'b0;
        forever #(LP_CLK_PERIOD_NS / 2) iClk = ~iClk;
    end

    initial begin : bResetGen
        iRstn = 1'b0;
        repeat (5) @(posedge iClk);
        iRstn = 1'b1;
    end

    initial begin : bWatchdog
        #LP_SIM_TIMEOUT_NS;
        $fatal(1, "TB timeout");
    end

    initial begin : bWaveDump
        $dumpfile("TbTop.vcd");
        $dumpvars(0, TbTop);
    end

    function automatic logic signed [31:0] GetCoreRe(input int unsigned BinIdx);
        unique case (BinIdx)
            0:       GetCoreRe = CoreBin0Re;
            1:       GetCoreRe = CoreBin1Re;
            2:       GetCoreRe = CoreBin2Re;
            3:       GetCoreRe = CoreBin3Re;
            4:       GetCoreRe = CoreBin4Re;
            5:       GetCoreRe = CoreBin5Re;
            6:       GetCoreRe = CoreBin6Re;
            7:       GetCoreRe = CoreBin7Re;
            default: GetCoreRe = 'x;
        endcase
    endfunction

    function automatic logic signed [31:0] GetCoreIm(input int unsigned BinIdx);
        unique case (BinIdx)
            0:       GetCoreIm = CoreBin0Im;
            1:       GetCoreIm = CoreBin1Im;
            2:       GetCoreIm = CoreBin2Im;
            3:       GetCoreIm = CoreBin3Im;
            4:       GetCoreIm = CoreBin4Im;
            5:       GetCoreIm = CoreBin5Im;
            6:       GetCoreIm = CoreBin6Im;
            7:       GetCoreIm = CoreBin7Im;
            default: GetCoreIm = 'x;
        endcase
    endfunction

    task automatic SetCoreSamples(input int signed Sample [0:7]);
        CoreSample0 = Sample[0];
        CoreSample1 = Sample[1];
        CoreSample2 = Sample[2];
        CoreSample3 = Sample[3];
        CoreSample4 = Sample[4];
        CoreSample5 = Sample[5];
        CoreSample6 = Sample[6];
        CoreSample7 = Sample[7];
    endtask

    task automatic CheckValue(
        input string             CaseName,
        input string             SignalName,
        input logic signed [31:0] Actual,
        input logic signed [31:0] Expected
    );
        if (Actual !== Expected) begin
            ErrorCnt++;
            $error("%s %s mismatch: actual=%0d expected=%0d", CaseName, SignalName, Actual, Expected);
        end
    endtask

    task automatic CheckTopIdle();
        if (TopFFT !== 1'b1) begin
            ErrorCnt++;
            $error("TOP idle oFFT mismatch: actual=%0b expected=1", TopFFT);
        end
        if (TopReIm !== 1'b1) begin
            ErrorCnt++;
            $error("TOP idle oReIm mismatch: actual=%0b expected=1", TopReIm);
        end
        if (TopIndex !== 8'hFE) begin
            ErrorCnt++;
            $error("TOP idle oIndex mismatch: actual=0x%02h expected=0xFE", TopIndex);
        end
    endtask

    task automatic RunFFTCase(
        input string     CaseName,
        input int signed Sample [0:7],
        input int signed ExpRe  [0:7],
        input int signed ExpIm  [0:7]
    );
        int unsigned waitCycles;

        @(negedge iClk);
        SetCoreSamples(Sample);
        CoreStart = 1'b1;
        @(negedge iClk);
        CoreStart = 1'b0;

        waitCycles = 0;
        do begin
            @(posedge iClk);
            #1;
            waitCycles++;
        end while ((CoreDone !== 1'b1) && (waitCycles < 20));

        if (CoreDone !== 1'b1) begin
            ErrorCnt++;
            $error("%s did not assert CoreDone", CaseName);
        end

        for (int idxBin = 0; idxBin < 8; idxBin++) begin
            CheckValue(CaseName, $sformatf("Re[%0d]", idxBin), GetCoreRe(idxBin), ExpRe[idxBin]);
            CheckValue(CaseName, $sformatf("Im[%0d]", idxBin), GetCoreIm(idxBin), ExpIm[idxBin]);
        end

        @(posedge iClk);
    endtask

    task automatic RunBcdCase(
        input string       CaseName,
        input logic [23:0] Value,
        input logic [27:0] Expected
    );
        int unsigned waitCycles;

        @(negedge iClk);
        BcdValue = Value;
        BcdStart = 1'b1;
        @(negedge iClk);
        BcdStart = 1'b0;

        waitCycles = 0;
        do begin
            @(posedge iClk);
            #1;
            waitCycles++;
        end while ((BcdDone !== 1'b1) && (waitCycles < 40));

        if (BcdDone !== 1'b1) begin
            ErrorCnt++;
            $error("%s did not assert BcdDone", CaseName);
        end else if (Bcd7 !== Expected) begin
            ErrorCnt++;
            $error("%s BCD mismatch: actual=0x%07h expected=0x%07h", CaseName, Bcd7, Expected);
        end

        @(posedge iClk);
    endtask

    initial begin : bTest
        int signed sample [0:7];
        int signed expRe [0:7];
        int signed expIm [0:7];

        TopKeyIn    = 5'b11111;
        CoreStart   = 1'b0;
        CoreSample0 = '0;
        CoreSample1 = '0;
        CoreSample2 = '0;
        CoreSample3 = '0;
        CoreSample4 = '0;
        CoreSample5 = '0;
        CoreSample6 = '0;
        CoreSample7 = '0;
        BcdStart    = 1'b0;
        BcdValue    = '0;
        ErrorCnt    = 0;

        wait (iRstn === 1'b1);
        repeat (2) @(posedge iClk);
        #1;
        CheckTopIdle();

        foreach (sample[idx]) begin
            sample[idx] = 0;
            expRe[idx]  = 0;
            expIm[idx]  = 0;
        end
        RunFFTCase("FFT_zero", sample, expRe, expIm);

        foreach (sample[idx]) begin
            sample[idx] = 0;
            expRe[idx]  = 1000;
            expIm[idx]  = 0;
        end
        sample[0] = 1000;
        RunFFTCase("FFT_impulse_x0", sample, expRe, expIm);

        foreach (sample[idx]) begin
            sample[idx] = 1000;
            expRe[idx]  = 0;
            expIm[idx]  = 0;
        end
        expRe[0] = 8000;
        RunFFTCase("FFT_constant", sample, expRe, expIm);

        foreach (sample[idx]) begin
            sample[idx] = (idx[0] == 1'b0) ? 1000 : -1000;
            expRe[idx]  = 0;
            expIm[idx]  = 0;
        end
        expRe[4] = 8000;
        RunFFTCase("FFT_alternating", sample, expRe, expIm);

        foreach (sample[idx]) begin
            sample[idx] = 0;
            expRe[idx]  = 0;
            expIm[idx]  = 0;
        end
        sample[1] = 1000;
        expRe[0] =  1000; expIm[0] =     0;
        expRe[1] =   707; expIm[1] =  -707;
        expRe[2] =     0; expIm[2] = -1000;
        expRe[3] =  -707; expIm[3] =  -707;
        expRe[4] = -1000; expIm[4] =     0;
        expRe[5] =  -707; expIm[5] =   707;
        expRe[6] =     0; expIm[6] =  1000;
        expRe[7] =   707; expIm[7] =   707;
        RunFFTCase("FFT_impulse_x1_twiddle", sample, expRe, expIm);

        RunBcdCase("bcd_zero",    24'd0,       28'h0000000);
        RunBcdCase("bcd_one",     24'd1,       28'h0000001);
        RunBcdCase("bcd_mid",     24'd1234567, 28'h1234567);
        RunBcdCase("bcd_max_7d",  24'd9999999, 28'h9999999);

        if (ErrorCnt == 0) begin
            $display("TB_PASS");
        end else begin
            $fatal(1, "TB_FAIL errors=%0d", ErrorCnt);
        end

        $finish;
    end

endmodule
