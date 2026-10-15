`timescale 1ns / 1ps

// Directed pin-level smoke regression for the published sensor RTL.
// Timings use a 1 MHz clock so sensor microseconds map directly to cycles.
module TbTop;
    logic Clk = 1'b0;
    logic Rst = 1'b1;
    logic HcsrStart = 1'b0;
    logic Echo = 1'b0;
    logic Trig;
    logic [15:0] Distance;
    logic HcsrValid;
    logic DhtStart = 1'b0;
    logic DhtDriveLow = 1'b0;
    tri1 DhtData;
    logic [15:0] Temp, Humi;
    logic DhtValid;
    int unsigned DhtValidCount = 0;
    logic [13:0] Binary;
    logic [15:0] Bcd;
    logic UartRx = 1'b1;
    logic UartTx, SenderReady, RxValid;
    logic [7:0] RxData, LastRx;
    int unsigned RxCount = 0;
    logic [6:0] Seg;
    logic Dp;
    logic [3:0] DigitSel;
    logic TopTrig, TopTx;
    tri1 TopDht;

    assign DhtData = DhtDriveLow ? 1'b0 : 1'bz;
    Hcsr04Core #(.P_SYS_CLK_HZ(1_000_000), .P_WAIT_TIMEOUT_US(250)) uHcsr (
        .iClk(Clk), .iRst(Rst), .iStart(HcsrStart), .iEcho(Echo),
        .oTrig(Trig), .oDistance(Distance), .oValid(HcsrValid));
    Dht11Core #(.P_SYS_CLK_HZ(1_000_000), .P_START_LOW_US(20)) uDht (
        .iClk(Clk), .iRst(Rst), .iStart(DhtStart), .ioData(DhtData),
        .oTemp(Temp), .oHumi(Humi), .oValid(DhtValid));
    DoubleDabble uBcd (.iBin(Binary), .oBcd(Bcd));
    uart_interface #(.P_CLK_HZ(1_000_000), .P_BAUD(62_500)) uUart (
        .iClk(Clk), .iRst(Rst), .iUartRx(UartRx), .oUartTx(UartTx),
        .iSenderData(8'd0), .iSenderValid(1'b0), .oSenderReady(SenderReady),
        .oDecoderData(RxData), .oDecoderValid(RxValid));
    TOP #(.P_SYS_CLK_HZ(1_000_000), .P_UART_BAUD(62_500)) uTop (
        .iClk100m(Clk), .iRst(Rst), .iBtnU(1'b0), .iBtnD(1'b0),
        .iBtnR(1'b0), .iBtnL(1'b0), .iSw(3'd0), .oSeg(Seg), .oDp(Dp),
        .oDigitSel(DigitSel), .oHcsr04Trig(TopTrig), .iHcsr04Echo(1'b0),
        .ioDht11Data(TopDht), .iUartRx(1'b1), .oUartTx(TopTx));

    initial begin : b_clock
        forever #500 Clk = ~Clk;
    end
    initial begin : b_reset
        repeat (5) @(negedge Clk);
        Rst = 1'b0;
    end
    initial begin : b_watchdog
        #20ms;
        $fatal(1, "SENSOR_TIMEOUT");
    end
    always @(posedge Clk) begin
        if (!Rst && DhtValid) DhtValidCount++;
        if (!Rst && RxValid) begin
            LastRx = RxData;
            RxCount++;
        end
    end

    task automatic StartHcsr();
        @(negedge Clk); HcsrStart = 1'b1;
        @(negedge Clk); HcsrStart = 1'b0;
    endtask
    task automatic SendDht(input bit [39:0] payload);
        @(negedge Clk); DhtStart = 1'b1;
        @(negedge Clk); DhtStart = 1'b0;
        wait (DhtData === 1'b0);
        wait (DhtData === 1'b1);
        repeat (10) @(negedge Clk);
        DhtDriveLow = 1'b1;
        repeat (80) @(negedge Clk);
        DhtDriveLow = 1'b0;
        repeat (80) @(negedge Clk);
        for (int idx = 39; idx >= 0; idx--) begin
            DhtDriveLow = 1'b1;
            repeat (50) @(negedge Clk);
            DhtDriveLow = 1'b0;
            repeat (payload[idx] ? 70 : 26) @(negedge Clk);
        end
        DhtDriveLow = 1'b1;
        repeat (50) @(negedge Clk);
        DhtDriveLow = 1'b0;
        repeat (10) @(negedge Clk);
    endtask
    task automatic SendUart(input bit [7:0] value);
        @(negedge Clk); UartRx = 1'b0;
        repeat (16) @(negedge Clk);
        for (int idx = 0; idx < 8; idx++) begin
            UartRx = value[idx];
            repeat (16) @(negedge Clk);
        end
        UartRx = 1'b1;
        repeat (32) @(negedge Clk);
    endtask

    initial begin : b_scenarios
        int unsigned trigCycles;
        int unsigned expectedBcd;
        wait (!Rst);
        repeat (10) @(negedge Clk);
        if ($isunknown({Seg,Dp,DigitSel,TopTrig,TopTx}) || TopTx !== 1'b1)
            $fatal(1, "TOP_RESET_IDLE_FAIL");
        $display("[PASS] TOP reset and idle outputs");

        for (int value = 0; value <= 9999; value++) begin
            Binary = value;
            expectedBcd = ((value/1000)<<12) | (((value/100)%10)<<8) |
                          (((value/10)%10)<<4) | (value%10);
            #1;
            if (Bcd !== expectedBcd[15:0]) $fatal(1, "BCD_FAIL input=%0d",value);
        end
        $display("[PASS] BCD 10000 vectors");

        StartHcsr();
        trigCycles = 0;
        while (Trig) begin trigCycles++; @(negedge Clk); end
        if (trigCycles != 10) $fatal(1,"HCSR_TRIGGER_FAIL cycles=%0d",trigCycles);
        repeat (10) @(negedge Clk);
        Echo = 1'b1;
        repeat (120) @(negedge Clk);
        Echo = 1'b0;
        wait (HcsrValid); #1;
        if (Distance !== 16'd2) $fatal(1,"HCSR_DISTANCE_FAIL value=%0d",Distance);
        repeat (5) @(negedge Clk);
        StartHcsr();
        wait (HcsrValid); #1;
        if (Distance !== 16'hffff) $fatal(1,"HCSR_TIMEOUT_POLICY_FAIL");
        $display("[PASS] HC-SR04 trigger, distance and timeout");

        SendDht(40'h370017004e);
        if (DhtValidCount != 1 || Humi !== 16'h3700 || Temp !== 16'h1700)
            $fatal(1,"DHT_PAYLOAD_FAIL count=%0d humidity=%04h temp=%04h",DhtValidCount,Humi,Temp);
        SendDht(40'h370017004f);
        if (DhtValidCount != 1) $fatal(1,"DHT_CHECKSUM_FAIL");
        $display("[PASS] DHT11 40-bit payload and checksum rejection");

        SendUart(8'h55);
        if (RxCount != 1 || LastRx !== 8'h55) $fatal(1,"UART_RX_FAIL");
        SendUart(8'ha6);
        if (RxCount != 2 || LastRx !== 8'ha6) $fatal(1,"UART_RX_REPEAT_FAIL");
        $display("[PASS] UART two-byte receive");
        $display("SENSOR_SMOKE_PASS");
        $finish;
    end
endmodule
