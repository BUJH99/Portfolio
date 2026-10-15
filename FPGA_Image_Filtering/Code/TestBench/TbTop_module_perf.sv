`timescale 1ns / 1ps

/*
 * Module: TbTop
 * Role: Compare the legacy random-read window core with the two-line-buffer
 *       implementation and independently benchmark the convolution stage.
 * Notes:
 *   - Checks every line-buffer window against a zero-padded software model.
 *   - Uses independent synchronous-read memory ports for both window cores.
 *   - Measures transaction throughput at the project 100 MHz system clock.
 */
module TbTop;

    localparam integer LP_IMAGE_WIDTH      = 480;
    localparam integer LP_IMAGE_HEIGHT     = 272;
    localparam integer LP_TOTAL_PIXELS     = LP_IMAGE_WIDTH * LP_IMAGE_HEIGHT;
    localparam integer LP_MEMORY_DEPTH     = 131072;
    localparam real    LP_CLOCK_PERIOD_NS  = 10.0;
    localparam time    LP_SIM_TIMEOUT      = 15ms;

    logic         iClk;
    logic         iRstn;

    logic [16:0]  oldBramAddr;
    logic         oldBramEn;
    logic [23:0]  oldBramData;
    logic         oldReady;
    logic         oldValid;
    logic [215:0] oldData;
    logic         oldFrameDone;

    logic [16:0]  lineBramAddr;
    logic         lineBramEn;
    logic [23:0]  lineBramData;
    logic         lineValid;
    logic [215:0] lineData;
    logic         lineFrameDone;

    logic [215:0] convDataIn;
    logic         convValidIn;
    logic         convReadyIn;
    logic [23:0]  convDataOut;
    logic         convValidOut;
    logic         convReadyOut;

    logic [23:0] memory [0:LP_MEMORY_DEPTH-1];

    integer sysCycle;
    integer oldReadCount;
    integer oldTransferCount;
    integer oldFirstCycle;
    integer oldLastCycle;
    integer oldPrevCycle;
    integer oldMinInterval;
    integer oldMaxInterval;
    integer oldIntervalSum;
    integer lineReadCount;
    integer lineTransferCount;
    integer lineFirstCycle;
    integer lineLastCycle;
    integer linePrevCycle;
    integer lineMinInterval;
    integer lineMaxInterval;
    integer lineIntervalSum;
    integer convInputCount;
    integer convOutputCount;
    integer convFirstCycle;
    integer convLastCycle;
    logic   oldDone;
    logic   lineDone;
    logic   convDone;

    Window3x3Case9 #(
        .P_IMG_WIDTH  (LP_IMAGE_WIDTH),
        .P_IMG_HEIGHT (LP_IMAGE_HEIGHT)
    ) uWindow3x3Case9 (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .oBramAddr  (oldBramAddr),
        .oBramEn    (oldBramEn),
        .iBramData  (oldBramData),
        .iReady     (oldReady),
        .oValid     (oldValid),
        .oData      (oldData),
        .oFrameDone (oldFrameDone)
    );

    Window3x3LineBuffer #(
        .P_IMG_WIDTH  (LP_IMAGE_WIDTH),
        .P_IMG_HEIGHT (LP_IMAGE_HEIGHT)
    ) uWindow3x3LineBuffer (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .oBramAddr  (lineBramAddr),
        .oBramEn    (lineBramEn),
        .iBramData  (lineBramData),
        .oValid     (lineValid),
        .oData      (lineData),
        .oFrameDone (lineFrameDone)
    );

    Conv3x3ReluParam uConv3x3ReluParam (
        .iClk        (iClk),
        .iRstn       (iRstn),
        .iFilterMode (2'b01),
        .iData       (convDataIn),
        .iValid      (convValidIn),
        .oReady      (convReadyIn),
        .oData       (convDataOut),
        .oValid      (convValidOut),
        .iReady      (convReadyOut)
    );

    // Independent synchronous read ports prevent one benchmark from affecting
    // the other while preserving the input-memory latency used by TOP.
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oldBramData <= 24'd0;
        end else if (oldBramEn) begin
            oldBramData <= memory[oldBramAddr];
        end
    end

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            lineBramData <= 24'd0;
        end else if (lineBramEn) begin
            lineBramData <= memory[lineBramAddr];
        end
    end

    // Return one source pixel or zero for coordinates outside the image.
    function automatic logic [23:0] expectedPixel(
        input integer row,
        input integer col
    );
        begin
            if ((row < 0) || (row >= LP_IMAGE_HEIGHT) ||
                (col < 0) || (col >= LP_IMAGE_WIDTH)) begin
                expectedPixel = 24'd0;
            end else begin
                expectedPixel = memory[(row * LP_IMAGE_WIDTH) + col];
            end
        end
    endfunction

    // Match the DUT's {p22,p21,...,p00} packed bus convention.
    function automatic logic [215:0] expectedWindow(
        input integer row,
        input integer col
    );
        begin
            expectedWindow = {
                expectedPixel(row + 1, col + 1),
                expectedPixel(row + 1, col    ),
                expectedPixel(row + 1, col - 1),
                expectedPixel(row,     col + 1),
                expectedPixel(row,     col    ),
                expectedPixel(row,     col - 1),
                expectedPixel(row - 1, col + 1),
                expectedPixel(row - 1, col    ),
                expectedPixel(row - 1, col - 1)
            };
        end
    endfunction

    // 100 MHz project system clock.
    initial begin : generateClock
        iClk = 1'b0;
        forever #(LP_CLOCK_PERIOD_NS / 2.0) iClk = ~iClk;
    end

    // Reset is asserted asynchronously and released before all benchmarks.
    initial begin : generateReset
        iRstn = 1'b0;
        repeat (10) @(posedge iClk);
        iRstn = 1'b1;
    end

    // A deterministic RGB gradient exposes row, column, and border mistakes.
    initial begin : initializeMemory
        integer row;
        integer col;
        integer address;

        for (row = 0; row < LP_IMAGE_HEIGHT; row = row + 1) begin
            for (col = 0; col < LP_IMAGE_WIDTH; col = col + 1) begin
                address = (row * LP_IMAGE_WIDTH) + col;
                memory[address] = {row[7:0], col[7:0], (row + col) & 8'hff};
            end
        end
    end

    // Keep the standalone convolution stage saturated to measure peak II.
    initial begin : driveConvolution
        integer pixelIndex;
        logic [23:0] pixelValue;

        convDataIn   = 216'd0;
        convValidIn  = 1'b0;
        convReadyOut = 1'b1;

        wait (iRstn == 1'b1);
        @(negedge iClk);
        for (pixelIndex = 0; pixelIndex < LP_TOTAL_PIXELS;
             pixelIndex = pixelIndex + 1) begin
            pixelValue = {pixelIndex[7:0], (pixelIndex >> 1) & 8'hff,
                          (pixelIndex >> 2) & 8'hff};
            convDataIn  = {9{pixelValue}};
            convValidIn = 1'b1;
            @(negedge iClk);
        end
        convValidIn = 1'b0;
    end

    assign oldReady  = 1'b1;

    // Transaction monitor. The #1 samples registered DUT outputs after NBA.
    always @(posedge iClk or negedge iRstn) begin : monitorTransactions
        integer oldInterval;
        integer lineInterval;
        integer expectedRow;
        integer expectedCol;

        if (!iRstn) begin
            sysCycle          = 0;
            oldReadCount      = 0;
            oldTransferCount  = 0;
            oldFirstCycle     = 0;
            oldLastCycle      = 0;
            oldPrevCycle      = 0;
            oldMinInterval    = 32'h7fff_ffff;
            oldMaxInterval    = 0;
            oldIntervalSum    = 0;
            lineReadCount     = 0;
            lineTransferCount = 0;
            lineFirstCycle    = 0;
            lineLastCycle     = 0;
            linePrevCycle     = 0;
            lineMinInterval   = 32'h7fff_ffff;
            lineMaxInterval   = 0;
            lineIntervalSum   = 0;
            convInputCount    = 0;
            convOutputCount   = 0;
            convFirstCycle    = 0;
            convLastCycle     = 0;
            oldDone           = 1'b0;
            lineDone          = 1'b0;
            convDone          = 1'b0;
        end else begin
            sysCycle = sysCycle + 1;
            #1;

            if (oldBramEn && !oldDone) begin
                oldReadCount = oldReadCount + 1;
            end
            if (lineBramEn && !lineDone) begin
                lineReadCount = lineReadCount + 1;
            end

            if (oldValid && oldReady && !oldDone) begin
                if (oldTransferCount == 0) begin
                    oldFirstCycle = sysCycle;
                end else begin
                    oldInterval = sysCycle - oldPrevCycle;
                    oldIntervalSum = oldIntervalSum + oldInterval;
                    if (oldInterval < oldMinInterval) begin
                        oldMinInterval = oldInterval;
                    end
                    if (oldInterval > oldMaxInterval) begin
                        oldMaxInterval = oldInterval;
                    end
                end

                oldPrevCycle = sysCycle;
                oldLastCycle = sysCycle;
                oldTransferCount = oldTransferCount + 1;

                if (oldTransferCount == LP_TOTAL_PIXELS) begin
                    oldDone = 1'b1;
                    printWindowResult("Legacy Window", oldTransferCount,
                                      oldReadCount, oldFirstCycle, oldLastCycle,
                                      oldIntervalSum, oldMinInterval, oldMaxInterval);
                end
            end

            if (lineValid && !lineDone) begin
                expectedRow = lineTransferCount / LP_IMAGE_WIDTH;
                expectedCol = lineTransferCount % LP_IMAGE_WIDTH;
                if (lineData !== expectedWindow(expectedRow, expectedCol)) begin
                    $display("LINE_BUFFER_DATA_MISMATCH row=%0d col=%0d", expectedRow, expectedCol);
                    $display("expected=%054h", expectedWindow(expectedRow, expectedCol));
                    $display("actual  =%054h", lineData);
                    $fatal(1, "LINE_BUFFER_FUNCTIONAL_FAIL");
                end

                if (lineTransferCount == 0) begin
                    lineFirstCycle = sysCycle;
                end else begin
                    lineInterval = sysCycle - linePrevCycle;
                    lineIntervalSum = lineIntervalSum + lineInterval;
                    if (lineInterval < lineMinInterval) begin
                        lineMinInterval = lineInterval;
                    end
                    if (lineInterval > lineMaxInterval) begin
                        lineMaxInterval = lineInterval;
                    end
                end

                linePrevCycle = sysCycle;
                lineLastCycle = sysCycle;
                lineTransferCount = lineTransferCount + 1;

                if (lineTransferCount == LP_TOTAL_PIXELS) begin
                    if (!lineFrameDone) begin
                        $fatal(1, "LINE_BUFFER_FRAME_DONE_MISSING");
                    end
                    lineDone = 1'b1;
                    printWindowResult("Two-Line-Buffer Window", lineTransferCount,
                                      lineReadCount, lineFirstCycle, lineLastCycle,
                                      lineIntervalSum, lineMinInterval, lineMaxInterval);
                end
            end

            if (convValidIn && convReadyIn && !convDone) begin
                convInputCount = convInputCount + 1;
            end

            if (convValidOut && convReadyOut && !convDone) begin
                if (convOutputCount == 0) begin
                    convFirstCycle = sysCycle;
                end
                convLastCycle = sysCycle;
                convOutputCount = convOutputCount + 1;

                if (convOutputCount == LP_TOTAL_PIXELS) begin
                    convDone = 1'b1;
                    printConvolutionResult();
                end
            end

            if (oldDone && lineDone && convDone) begin
                $display("MODULE_PERF_PASS");
                $finish;
            end
        end
    end

    task automatic printWindowResult(
        input string  labelText,
        input integer transferCount,
        input integer readCount,
        input integer firstCycle,
        input integer lastCycle,
        input integer intervalSum,
        input integer minInterval,
        input integer maxInterval
    );
        integer spanCycles;
        real frameTimeMs;
        real frameRateFps;
        real throughputMpixel;
        real averageInterval;
        real readsPerPixel;
        begin
            spanCycles       = lastCycle - firstCycle + 1;
            frameTimeMs      = spanCycles * LP_CLOCK_PERIOD_NS / 1.0e6;
            frameRateFps     = 1.0e9 / (spanCycles * LP_CLOCK_PERIOD_NS);
            throughputMpixel = LP_TOTAL_PIXELS * 1.0e3 / frameTimeMs / 1.0e6;
            averageInterval  = intervalSum * 1.0 / (LP_TOTAL_PIXELS - 1);
            readsPerPixel    = readCount * 1.0 / LP_TOTAL_PIXELS;

            $display("====================================");
            $display("%s Benchmark", labelText);
            $display("Output pixels                 : %0d", transferCount);
            $display("BRAM read requests            : %0d", readCount);
            $display("Average BRAM reads/pixel      : %.3f", readsPerPixel);
            $display("Output span cycles            : %0d", spanCycles);
            $display("Frame time                    : %.6f ms", frameTimeMs);
            $display("Equivalent FPS                : %.3f FPS", frameRateFps);
            $display("Throughput                    : %.3f MPixel/s", throughputMpixel);
            $display("Average transfer interval     : %.6f cycles/pixel", averageInterval);
            $display("Min/Max transfer interval     : %0d / %0d cycles", minInterval, maxInterval);
            $display("====================================");
        end
    endtask

    task automatic printConvolutionResult();
        integer spanCycles;
        real frameTimeMs;
        real frameRateFps;
        real throughputMpixel;
        begin
            spanCycles       = convLastCycle - convFirstCycle + 1;
            frameTimeMs      = spanCycles * LP_CLOCK_PERIOD_NS / 1.0e6;
            frameRateFps     = 1.0e9 / (spanCycles * LP_CLOCK_PERIOD_NS);
            throughputMpixel = LP_TOTAL_PIXELS * 1.0e3 / frameTimeMs / 1.0e6;

            $display("====================================");
            $display("Standalone Convolution Benchmark");
            $display("Accepted input pixels         : %0d", convInputCount);
            $display("Output pixels                 : %0d", convOutputCount);
            $display("Output span cycles            : %0d", spanCycles);
            $display("Frame time                    : %.6f ms", frameTimeMs);
            $display("Equivalent FPS                : %.3f FPS", frameRateFps);
            $display("Throughput                    : %.3f MPixel/s", throughputMpixel);
            $display("Peak initiation interval      : 1 cycle/pixel");
            $display("====================================");
        end
    endtask

    // A timeout turns deadlock or an incomplete frame into a hard failure.
    initial begin : watchdog
        #(LP_SIM_TIMEOUT);
        $fatal(1, "MODULE_PERF_TIMEOUT");
    end

endmodule
