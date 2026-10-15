`timescale 1ns / 1ps

//============================================================
// Testbench for TOP
//  - Simulates a single 480x272 RGB565 frame coming from camera
//  - UUT converts camera stream -> BRAM -> Conv3x3 -> LCD RGB565
//============================================================
module tb_TOP;

    // --------------------------------------------------------
    // Parameters (camera frame size)
    // --------------------------------------------------------
    localparam IMG_W = 480;
    localparam IMG_H = 272;
    localparam TOTAL_PIXELS = IMG_W * IMG_H;
    localparam PERF_DEFAULT_PRELOAD_INPUT = 1'b1;
    localparam PERF_TIMEOUT_CYCLES = 5000000;
    localparam real SYS_CLK_HZ = 100000000.0;
    localparam real CAM_CLK_HZ = 25000000.0;

    // --------------------------------------------------------
    // DUT I/O
    // --------------------------------------------------------
    reg         iClk;
    reg         iRstn;

    wire        ioCamSccbScl;
    wire        ioCamSccbSda;
    reg         iCamPclk;
    reg  [7:0]  iCamData;
    wire        oCamResetn;
    reg         iCamHsync;
    reg         iCamVsync;
    wire        oCamPwdn;
    wire        oCamMclk;

    reg  [1:0]  iFilterMode;

    wire        oLcdClk;
    wire        oLcdHSync;
    wire        oLcdVSync;
    wire        oLcdDe;
    wire        oLcdBacklight;
    wire [4:0]  oLcdR;
    wire [5:0]  oLcdG;
    wire [4:0]  oLcdB;

    // --------------------------------------------------------
    // Performance counters
    // --------------------------------------------------------
    integer mode_arg;
    reg     perf_preload_input;
    reg     camera_frame_done;
    integer sys_cycle;
    integer cam_cycle;

    integer cam_wr_count;
    integer cam_wr_first_cycle;
    integer cam_wr_last_cycle;
    reg     cam_wr_done;

    integer inbuf_wr_count;
    integer inbuf_wr_first_cycle;
    integer inbuf_wr_last_cycle;
    reg     inbuf_wr_done;
    integer inbuf_cmd_count;
    integer inbuf_cmd_first_cycle;
    integer inbuf_cmd_last_cycle;
    reg     inbuf_cmd_done;
    reg     inbuf_cmd_probe;

    integer win_first_cycle;
    integer win_last_cycle;
    reg     win_done;
    integer out_pixel_count;
    integer first_out_cycle;
    integer last_out_cycle;
    integer outbuf_first_cycle;
    integer outbuf_last_cycle;
    integer outbuf_count;
    integer outbuf_cmd_first_cycle;
    integer outbuf_cmd_last_cycle;
    integer outbuf_cmd_count;
    reg     outbuf_cmd_done;
    reg     outbuf_cmd_probe;
    integer conv_first_cycle;
    integer conv_last_cycle;
    integer conv_count;
    reg     conv_done;
    integer lcd_active_first_cycle;
    integer lcd_active_last_cycle;
    integer lcd_active_count;
    reg     lcd_active_done;
    reg     core_done;
    integer reset_to_done_cycles;
    integer active_frame_cycles;
    integer win_valid_count;
    integer win_transfer_count;
    integer win_stall_count;
    integer conv_valid_count;
    integer conv_transfer_count;
    integer conv_stall_count;
    real    reset_to_done_ms;
    real    active_frame_ms;
    real    reset_to_done_fps;
    real    active_frame_fps;
    real    active_mpix_s;
    real    lcd_refresh_fps;
    real    lcd_active_mpix_s;
    reg     perf_done;

    task automatic print_segment;
        input string  name;
        input integer first_cycle;
        input integer last_cycle;
        input integer count;
        input real    clk_hz;
        integer span_cycles;
        real    span_ms;
        real    fps;
        real    mpix_s;
    begin
        if (count == 0) begin
            $display("%-30s : count=0 (not observed)", name);
        end else begin
            span_cycles = last_cycle - first_cycle + 1;
            span_ms     = (span_cycles * 1000.0) / clk_hz;
            fps         = clk_hz / span_cycles;
            mpix_s      = (count * clk_hz) / (span_cycles * 1000000.0);

            $display("%-30s : first=%0d last=%0d span=%0d cyc time=%.3f ms count=%0d fps=%.2f throughput=%.2f MPixel/s",
                     name, first_cycle, last_cycle, span_cycles, span_ms, count, fps, mpix_s);
        end
    end
    endtask

    task automatic print_latency;
        input string  name;
        input integer start_cycle;
        input integer end_cycle;
        input real    clk_hz;
        integer delta_cycles;
        real    delta_ms;
    begin
        if ((start_cycle == 0) && (end_cycle == 0)) begin
            $display("%-30s : not observed", name);
        end else begin
            delta_cycles = end_cycle - start_cycle + 1;
            delta_ms     = (delta_cycles * 1000.0) / clk_hz;
            $display("%-30s : %0d cycles, %.3f ms", name, delta_cycles, delta_ms);
        end
    end
    endtask

    task automatic print_perf_report;
        real cam_done_ms;
        real inbuf_done_ms;
        real out_first_ms;
        real out_done_ms;
        real lcd_first_ms;
    begin
        reset_to_done_ms = reset_to_done_cycles * 10.0 / 1000000.0;
        active_frame_ms = active_frame_cycles * 10.0 / 1000000.0;
        reset_to_done_fps = 100000000.0 / reset_to_done_cycles;
        active_frame_fps = 100000000.0 / active_frame_cycles;
        active_mpix_s = (TOTAL_PIXELS * 100.0) / active_frame_cycles;
        lcd_refresh_fps = 6250000.0 / (526.0 * 286.0);
        lcd_active_mpix_s = (TOTAL_PIXELS * lcd_refresh_fps) / 1000000.0;
        cam_done_ms = (cam_wr_last_cycle * 1000.0) / CAM_CLK_HZ;
        inbuf_done_ms = (inbuf_wr_last_cycle * 1000.0) / CAM_CLK_HZ;
        out_first_ms = (first_out_cycle * 1000.0) / SYS_CLK_HZ;
        out_done_ms = (last_out_cycle * 1000.0) / SYS_CLK_HZ;
        lcd_first_ms = (lcd_active_first_cycle * 1000.0) / SYS_CLK_HZ;

        $display("====================================");
        $display("Performance Result");
        $display("Scenario                     : %s", perf_preload_input ? "CORE_PRELOAD" : "CAMERA_STREAM");
        $display("Mode                         : %0d", iFilterMode);
        $display("Resolution                   : %0d x %0d", IMG_W, IMG_H);
        $display("Output pixels                : %0d", TOTAL_PIXELS);
        $display("First output cycle           : %0d", first_out_cycle);
        $display("Last output cycle            : %0d", last_out_cycle);
        $display("Reset-to-complete cycles     : %0d", reset_to_done_cycles);
        $display("Reset-to-complete time       : %.3f ms", reset_to_done_ms);
        $display("Reset-to-complete FPS        : %.2f FPS", reset_to_done_fps);
        $display("Output span cycles           : %0d", active_frame_cycles);
        $display("Output span time             : %.3f ms", active_frame_ms);
        $display("Output span FPS              : %.2f FPS", active_frame_fps);
        $display("Core throughput              : %.2f MPixel/s", active_mpix_s);
        $display("Window valid / transfer      : %0d / %0d", win_valid_count, win_transfer_count);
        $display("Window stall cycles          : %0d", win_stall_count);
        $display("Conv valid / transfer        : %0d / %0d", conv_valid_count, conv_transfer_count);
        $display("Conv stall cycles            : %0d", conv_stall_count);
        $display("LCD timing limit             : %.2f FPS", lcd_refresh_fps);
        $display("LCD active throughput limit  : %.2f MPixel/s", lcd_active_mpix_s);
        $display("------------------------------------");
        $display("Segment Metrics");
        print_segment("Camera RGB565 capture", cam_wr_first_cycle, cam_wr_last_cycle, cam_wr_count, CAM_CLK_HZ);
        print_segment("Input RGB888 write command", inbuf_cmd_first_cycle, inbuf_cmd_last_cycle, inbuf_cmd_count, CAM_CLK_HZ);
        print_segment("Input BRAM write commit", inbuf_wr_first_cycle, inbuf_wr_last_cycle, inbuf_wr_count, CAM_CLK_HZ);
        print_segment("3x3 window output stable", win_first_cycle, win_last_cycle, win_transfer_count, SYS_CLK_HZ);
        print_segment("Conv output stable", conv_first_cycle, conv_last_cycle, conv_count, SYS_CLK_HZ);
        print_segment("RGB565 write command", outbuf_cmd_first_cycle, outbuf_cmd_last_cycle, outbuf_cmd_count, SYS_CLK_HZ);
        print_segment("Output BRAM write commit", outbuf_first_cycle, outbuf_last_cycle, outbuf_count, SYS_CLK_HZ);
        print_segment("LCD active read", lcd_active_first_cycle, lcd_active_last_cycle, lcd_active_count, SYS_CLK_HZ);
        $display("------------------------------------");
        $display("Latency Metrics");
        print_latency("Reset to first output", 0, first_out_cycle, SYS_CLK_HZ);
        print_latency("First window to first output", win_first_cycle, first_out_cycle, SYS_CLK_HZ);
        print_latency("Conv output to BRAM commit", conv_first_cycle, first_out_cycle, SYS_CLK_HZ);
        print_latency("First output to core done", first_out_cycle, last_out_cycle, SYS_CLK_HZ);
        $display("------------------------------------");
        $display("Readiness / Overlap Checks");
        if (perf_preload_input) begin
            $display("Input ready before core start       : yes (preloaded)");
        end else if (inbuf_done_ms <= out_first_ms) begin
            $display("Input ready before first output     : yes");
        end else begin
            $display("Input ready before first output     : no  (input done %.3f ms, first output %.3f ms)", inbuf_done_ms, out_first_ms);
        end

        if (out_done_ms <= lcd_first_ms) begin
            $display("Output ready before LCD active read : yes");
        end else begin
            $display("Output ready before LCD active read : no  (output done %.3f ms, LCD first read %.3f ms)", out_done_ms, lcd_first_ms);
        end

        if (!perf_preload_input) begin
            $display("Camera capture done after reset     : %.3f ms", cam_done_ms);
        end
        $display("====================================");
    end
    endtask

    // --------------------------------------------------------
    // DUT Instance
    // --------------------------------------------------------
    TOP uut (
        // System
        .iClk          (iClk),
        .iRstn        (iRstn),

        // Camera side
        .ioCamSccbScl  (ioCamSccbScl),
        .ioCamSccbSda  (ioCamSccbSda),
        .iCamPclk      (iCamPclk),
        .iCamData      (iCamData),
        .oCamResetn    (oCamResetn),
        .iCamHsync     (iCamHsync),
        .iCamVsync     (iCamVsync),
        .oCamPwdn      (oCamPwdn),
        .oCamMclk      (oCamMclk),

        // Mode (0:bypass, 1:sharpen, 2:edge enhance, 3:emboss)
        .iFilterMode         (iFilterMode),

        // LCD side
        .oLcdClk       (oLcdClk),
        .oLcdHSync     (oLcdHSync),
        .oLcdVSync     (oLcdVSync),
        .oLcdDe        (oLcdDe),
        .oLcdBacklight (oLcdBacklight),
        .oLcdR         (oLcdR),
        .oLcdG         (oLcdG),
        .oLcdB         (oLcdB)
    );

    // --------------------------------------------------------
    // Clock generation
    //  - iClk : 100MHz (10ns period)
    //  - iCamPclk : ~25MHz (40ns period, just for simulation)
    // --------------------------------------------------------
    initial begin
        iClk = 1'b0;
        forever #5 iClk = ~iClk;   // 100 MHz
    end

    initial begin
        iCamPclk = 1'b0;
        forever #20 iCamPclk = ~iCamPclk;  // 25 MHz
    end

    // --------------------------------------------------------
    // Reset & top-level stimulus
    // --------------------------------------------------------
    initial begin
        // 초기값
        iRstn    = 1'b0;
        iCamVsync = 1'b1;   // Frame inactive (idle)
        iCamHsync = 1'b0;
        iCamData  = 8'h00;
        perf_preload_input = PERF_DEFAULT_PRELOAD_INPUT;
        if ($test$plusargs("STREAM_INPUT")) begin
            perf_preload_input = 1'b0;
        end
        if ($test$plusargs("PRELOAD_INPUT")) begin
            perf_preload_input = 1'b1;
        end

        camera_frame_done = 1'b0;

        if ($test$plusargs("MODE0")) begin
            mode_arg = 0;
        end else if ($test$plusargs("MODE2")) begin
            mode_arg = 2;
        end else if ($test$plusargs("MODE3")) begin
            mode_arg = 3;
        end else begin
            mode_arg = 1;   // 0:bypass, 1:sharpen, 2:edge enhance, 3:emboss
        end
        iFilterMode = mode_arg[1:0];

        // 파형 덤프 (필요시 사용)
        // $dumpfile("cnn_top_tb.vcd");
        // $dumpvars(0, tb_TOP);

        if (perf_preload_input) begin
            preload_input_frame();
            camera_frame_done = 1'b1;
            $display("[%0t] Performance preload enabled. MODE=%0d", $time, mode_arg[1:0]);
        end else begin
            $display("[%0t] Camera stream performance enabled. MODE=%0d", $time, mode_arg[1:0]);
        end

        // Reset 시간
        #200;
        iRstn = 1'b1;

        if (perf_preload_input) begin
            wait (perf_done == 1'b1);
            repeat (20) @(posedge iClk);
            $display("[%0t] Performance simulation finished.", $time);
            $finish;
        end

        // (옵션) 카메라 I2C 설정이 도는 시간을 약간 기다려도 됨
        #10;  // 100us 정도 대기 (필요 없다면 줄여도 됨)

        // 단일 프레임 전송
        $display("[%0t] Start sending camera frame", $time);
        send_frame();
        camera_frame_done = 1'b1;
        $display("[%0t] Camera frame done. Waiting for LCD output...", $time);

        wait (perf_done == 1'b1);
        repeat (20) @(posedge iClk);
        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

    initial begin
        wait (iRstn == 1'b1);
        repeat (PERF_TIMEOUT_CYCLES) @(posedge iClk);
        if (!perf_done) begin
            $display("ERROR: Performance timeout after %0d cycles", PERF_TIMEOUT_CYCLES);
            $finish;
        end
    end

    // --------------------------------------------------------
    // Task: 성능 측정용 입력 프레임 preload
    //  - 카메라 스트림 시간과 무관하게 PL 필터 파이프라인 처리량만 측정
    // --------------------------------------------------------
    task preload_input_frame;
        integer x;
        integer y;
        integer addr;
        reg [7:0] r_data;
        reg [7:0] g_data;
        reg [7:0] b_data;
    begin
        for (y = 0; y < IMG_H; y = y + 1) begin
            for (x = 0; x < IMG_W; x = x + 1) begin
                addr = (y * IMG_W) + x;
                r_data = y[7:0];
                g_data = x[7:0];
                b_data = (x + y) & 8'hff;
                uut.uInputMemory.mem[addr] = {r_data, g_data, b_data};
            end
        end
    end
    endtask

    // --------------------------------------------------------
    // Task: 한 픽셀(RGB565)을 카메라 쪽으로 전송
    //  - CameraToRam 모듈은 8bit씩 2번(PCLK 2주기)에 걸쳐
    //    High byte, Low byte 순서로 받도록 설계되어 있음.
    //  - CameraToRam 는 posedge iCamPclk 에서 샘플링하므로
    //    testbench 에서는 negedge 에서 데이터를 변경해줌.
    // --------------------------------------------------------
    task send_pixel(input [15:0] pixel);
    begin
        // High byte 전송
        @(negedge iCamPclk);
        iCamData = pixel[15:8];

        // Low byte 전송
        @(negedge iCamPclk);
        iCamData = pixel[7:0];
    end
    endtask

    // --------------------------------------------------------
    // Task: 한 라인(가로 480픽셀)을 전송
    //  - HSYNC = 1 동안 데이터 유효
    //  - 라인 끝에서 HSYNC를 0으로 떨어뜨려서
    //    CameraToRam 내부의 v_count 증가 조건을 만족시킴
    // --------------------------------------------------------
    task send_line(input integer line_idx);
        integer x;
        reg [15:0] pix;
    begin
        // 라인 시작
        iCamHsync = 1'b1;

        for (x = 0; x < IMG_W; x = x + 1) begin
            // 간단한 패턴: y방향으로 Red, x방향으로 Green, (x+y)로 Blue
            pix[15:11] = line_idx[4:0];         // R (5bit)
            pix[10:5]  = x[5:0];                // G (6bit)
            pix[4:0]   = x + line_idx[4:0];   // B (5bit)

            send_pixel(pix);
        end

        // 라인 끝: HSYNC low + 약간의 H-blank
        @(negedge iCamPclk);
        iCamHsync = 1'b0;
        iCamData  = 8'h00;

        // H-blank 조금 더
        repeat (10) @(negedge iCamPclk);
    end
    endtask

    // --------------------------------------------------------
    // Task: 전체 프레임(480x272)을 전송
    //  - VSYNC = 0 동안 한 프레임
    //  - 각 라인 사이에 HSYNC falling edge가 나오므로
    //    CameraToRam 내부 v_count 가 증가함
    // --------------------------------------------------------
    task send_frame;
        integer y;
    begin
        // Frame 시작: VSYNC active-low
        @(negedge iCamPclk);
        iCamVsync = 1'b0;

        // 약간의 vertical front porch (옵션)
        repeat (10) @(negedge iCamPclk);

        // 모든 라인 전송
        for (y = 0; y < IMG_H; y = y + 1) begin
            send_line(y);
        end

        // Frame 끝: VSYNC high (idle)
        @(negedge iCamPclk);
        iCamVsync = 1'b1;
        iCamHsync = 1'b0;
        iCamData  = 8'h00;

        // Vertical blanking
        repeat (100) @(negedge iCamPclk);
    end
    endtask

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            sys_cycle <= 0;
        end else begin
            sys_cycle <= sys_cycle + 1;
        end
    end

    always @(posedge iCamPclk or negedge iRstn) begin
        if (!iRstn) begin
            cam_cycle          <= 0;
            cam_wr_count       <= 0;
            cam_wr_first_cycle <= 0;
            cam_wr_last_cycle  <= 0;
            cam_wr_done        <= 1'b0;
            inbuf_cmd_count       <= 0;
            inbuf_cmd_first_cycle <= 0;
            inbuf_cmd_last_cycle  <= 0;
            inbuf_cmd_done        <= 1'b0;
            inbuf_cmd_probe       <= 1'b0;
            inbuf_wr_count       <= 0;
            inbuf_wr_first_cycle <= 0;
            inbuf_wr_last_cycle  <= 0;
            inbuf_wr_done        <= 1'b0;
        end else begin
            cam_cycle <= cam_cycle + 1;

            #1;

            if (uut.CamWrEn && !cam_wr_done) begin
                if (cam_wr_count == 0) begin
                    cam_wr_first_cycle <= cam_cycle;
                end
                cam_wr_last_cycle <= cam_cycle;
                cam_wr_count <= cam_wr_count + 1;
                if (cam_wr_count == TOTAL_PIXELS - 1) begin
                    cam_wr_done <= 1'b1;
                end
            end

            if (uut.InBufWeA && uut.InBufEnA && !inbuf_cmd_done) begin
                if (inbuf_cmd_count == 0) begin
                    inbuf_cmd_first_cycle <= cam_cycle;
                end
                inbuf_cmd_last_cycle <= cam_cycle;
                inbuf_cmd_count <= inbuf_cmd_count + 1;
                if (inbuf_cmd_count == TOTAL_PIXELS - 1) begin
                    inbuf_cmd_done <= 1'b1;
                end
            end

            if (inbuf_cmd_probe && !inbuf_wr_done) begin
                if (inbuf_wr_count == 0) begin
                    inbuf_wr_first_cycle <= cam_cycle;
                end
                inbuf_wr_last_cycle <= cam_cycle;
                inbuf_wr_count <= inbuf_wr_count + 1;
                if (inbuf_wr_count == TOTAL_PIXELS - 1) begin
                    inbuf_wr_done <= 1'b1;
                end
            end

            inbuf_cmd_probe <= uut.InBufWeA && uut.InBufEnA;
        end
    end

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            out_pixel_count     <= 0;
            first_out_cycle     <= 0;
            last_out_cycle      <= 0;
            outbuf_first_cycle  <= 0;
            outbuf_last_cycle   <= 0;
            outbuf_count        <= 0;
            outbuf_cmd_first_cycle <= 0;
            outbuf_cmd_last_cycle  <= 0;
            outbuf_cmd_count       <= 0;
            outbuf_cmd_done        <= 1'b0;
            outbuf_cmd_probe       <= 1'b0;
            conv_first_cycle    <= 0;
            conv_last_cycle     <= 0;
            conv_count          <= 0;
            conv_done           <= 1'b0;
            win_first_cycle     <= 0;
            win_last_cycle      <= 0;
            win_done            <= 1'b0;
            lcd_active_first_cycle <= 0;
            lcd_active_last_cycle  <= 0;
            lcd_active_count       <= 0;
            lcd_active_done        <= 1'b0;
            core_done           <= 1'b0;
            reset_to_done_cycles <= 0;
            active_frame_cycles <= 0;
            win_valid_count     <= 0;
            win_transfer_count  <= 0;
            win_stall_count     <= 0;
            conv_valid_count    <= 0;
            conv_transfer_count <= 0;
            conv_stall_count    <= 0;
            perf_done           <= 1'b0;
        end else begin
            #1;

            if (uut.WinValid && !win_done) begin
                win_valid_count <= win_valid_count + 1;
            end

            if (uut.WinValid && uut.WinReady && !win_done) begin
                win_transfer_count <= win_transfer_count + 1;
                if (win_transfer_count == 0) begin
                    win_first_cycle <= sys_cycle;
                end
                win_last_cycle <= sys_cycle;
                if (win_transfer_count == TOTAL_PIXELS - 1) begin
                    win_done <= 1'b1;
                end
            end

            if (uut.WinValid && !uut.WinReady && !win_done) begin
                win_stall_count <= win_stall_count + 1;
            end

            if (uut.ConvValid && !conv_done) begin
                conv_valid_count <= conv_valid_count + 1;
            end

            if (uut.ConvValid && uut.ConvReady && !conv_done) begin
                conv_transfer_count <= conv_transfer_count + 1;
                if (conv_count == 0) begin
                    conv_first_cycle <= sys_cycle;
                end
                conv_last_cycle <= sys_cycle;
                conv_count <= conv_count + 1;
                if (conv_transfer_count == TOTAL_PIXELS - 1) begin
                    conv_done <= 1'b1;
                end
            end

            if (uut.ConvValid && !uut.ConvReady && !conv_done) begin
                conv_stall_count <= conv_stall_count + 1;
            end

            if (uut.OutBufWeA && uut.OutBufEnA && !outbuf_cmd_done) begin
                if (outbuf_cmd_count == 0) begin
                    outbuf_cmd_first_cycle <= sys_cycle;
                end
                outbuf_cmd_count <= outbuf_cmd_count + 1;
                outbuf_cmd_last_cycle <= sys_cycle;
                if (outbuf_cmd_count == TOTAL_PIXELS - 1) begin
                    outbuf_cmd_done <= 1'b1;
                end
            end

            if (outbuf_cmd_probe && !core_done) begin
                if (out_pixel_count == 0) begin
                    first_out_cycle <= sys_cycle;
                    outbuf_first_cycle <= sys_cycle;
                    $display("[%0t] First committed output pixel. cycle=%0d", $time, sys_cycle);
                end

                out_pixel_count <= out_pixel_count + 1;
                outbuf_count <= outbuf_count + 1;
                outbuf_last_cycle <= sys_cycle;

                if (out_pixel_count == TOTAL_PIXELS - 1) begin
                    last_out_cycle = sys_cycle;
                    outbuf_last_cycle <= sys_cycle;
                    reset_to_done_cycles = last_out_cycle + 1;
                    active_frame_cycles = last_out_cycle - first_out_cycle + 1;
                    core_done <= 1'b1;
                end
            end

            outbuf_cmd_probe <= uut.OutBufWeA && uut.OutBufEnA;

            if (uut.LcdClkEn && uut.uMemToTftLcd.ActiveRegion && !lcd_active_done) begin
                if (lcd_active_count == 0) begin
                    lcd_active_first_cycle <= sys_cycle;
                end
                lcd_active_last_cycle <= sys_cycle;
                lcd_active_count <= lcd_active_count + 1;
                if (lcd_active_count == TOTAL_PIXELS - 1) begin
                    lcd_active_done <= 1'b1;
                end
            end

            if (!perf_done && core_done && lcd_active_done &&
                (perf_preload_input || (camera_frame_done && cam_wr_done && inbuf_wr_done))) begin
                print_perf_report();
                perf_done <= 1'b1;
            end
        end
    end

    // --------------------------------------------------------
    // (옵션) LCD 측 모니터링: 몇 개 픽셀만 출력 확인
    //  - 실제 검증에서는 waveform에서 oLcdR/G/B, oLcdHSync/VSync를
    //    확인하거나, 별도 로직으로 PPM 파일을 만드는 쪽으로
    //    확장하셔도 됩니다.
    // --------------------------------------------------------
    integer lcd_pixel_cnt;
    always @(posedge oLcdClk or negedge iRstn) begin
        if (!iRstn) begin
            lcd_pixel_cnt <= 0;
        end else begin
            // Sync가 모두 high이고, RGB가 0이 아닌 경우를 "대략" active pixel로 간주
            if (oLcdHSync && oLcdVSync &&
                (oLcdR !== 5'd0 || oLcdG !== 6'd0 || oLcdB !== 5'd0)) begin
                lcd_pixel_cnt <= lcd_pixel_cnt + 1;
                if (lcd_pixel_cnt < 10) begin
                    $display("[%0t] LCD Pixel %0d : R=%0d G=%0d B=%0d",
                             $time, lcd_pixel_cnt, oLcdR, oLcdG, oLcdB);
                end
            end
        end
    end

endmodule
