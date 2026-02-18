`timescale 1ns / 1ps

//============================================================
// Testbench for CNN_Top
//  - Simulates a single 480x272 RGB565 frame coming from camera
//  - UUT converts camera stream -> BRAM -> Conv3x3 -> LCD RGB565
//============================================================
module tb_CNN_Top;

    // --------------------------------------------------------
    // Parameters (camera frame size)
    // --------------------------------------------------------
    localparam IMG_W = 480;
    localparam IMG_H = 272;

    // --------------------------------------------------------
    // DUT I/O
    // --------------------------------------------------------
    reg         iClk;
    reg         iRst_n;

    wire        CAM_SCCB_SCL;
    wire        CAM_SCCB_SDA;
    reg         CAM_PCLK;
    reg  [7:0]  CAM_DATA;
    wire        CAM_RESETn;
    reg         CAM_HSYNC;
    reg         CAM_VSYNC;
    wire        CAM_PWDN;
    wire        CAM_MCLK;

    reg  [1:0]  iMode;

    wire        oLcdClk;
    wire        oLcdHSync;
    wire        oLcdVSync;
    wire        oLcdDe;
    wire        oLcdBacklight;
    wire [4:0]  oLcdR;
    wire [5:0]  oLcdG;
    wire [4:0]  oLcdB;

    // --------------------------------------------------------
    // DUT Instance
    // --------------------------------------------------------
    CNN_Top uut (
        // System
        .iClk          (iClk),
        .iRst_n        (iRst_n),

        // Camera side
        .CAM_SCCB_SCL  (CAM_SCCB_SCL),
        .CAM_SCCB_SDA  (CAM_SCCB_SDA),
        .CAM_PCLK      (CAM_PCLK),
        .CAM_DATA      (CAM_DATA),
        .CAM_RESETn    (CAM_RESETn),
        .CAM_HSYNC     (CAM_HSYNC),
        .CAM_VSYNC     (CAM_VSYNC),
        .CAM_PWDN      (CAM_PWDN),
        .CAM_MCLK      (CAM_MCLK),

        // Mode (00: Sharpen, 01: Edge Enhance, 10/11: Bypass)
        .iMode         (iMode),

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
    //  - CAM_PCLK : ~25MHz (40ns period, just for simulation)
    // --------------------------------------------------------
    initial begin
        iClk = 1'b0;
        forever #5 iClk = ~iClk;   // 100 MHz
    end

    initial begin
        CAM_PCLK = 1'b0;
        forever #20 CAM_PCLK = ~CAM_PCLK;  // 25 MHz
    end

    // --------------------------------------------------------
    // Reset & top-level stimulus
    // --------------------------------------------------------
    initial begin
        // 초기값
        iRst_n    = 1'b0;
        CAM_VSYNC = 1'b1;   // Frame inactive (idle)
        CAM_HSYNC = 1'b0;
        CAM_DATA  = 8'h00;
        iMode     = 2'b10;  // 기본: Bypass 모드 (Conv 결과가 입력과 비슷하게 나오도록)

        // 파형 덤프 (필요시 사용)
        // $dumpfile("cnn_top_tb.vcd");
        // $dumpvars(0, tb_CNN_Top);

        // Reset 시간
        #200;
        iRst_n = 1'b1;

        // (옵션) 카메라 I2C 설정이 도는 시간을 약간 기다려도 됨
        #10;  // 100us 정도 대기 (필요 없다면 줄여도 됨)

        // 단일 프레임 전송
        $display("[%0t] Start sending camera frame", $time);
        send_frame();
        $display("[%0t] Camera frame done. Waiting for LCD output...", $time);

        // LCD 쪽이 프레임을 다 소모할 시간을 여유 있게 줌
        #50_000_000;  // 50ms 정도 (필요시 조정)

        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

    // --------------------------------------------------------
    // Task: 한 픽셀(RGB565)을 카메라 쪽으로 전송
    //  - camera_to_ram 모듈은 8bit씩 2번(PCLK 2주기)에 걸쳐
    //    High byte, Low byte 순서로 받도록 설계되어 있음.
    //  - camera_to_ram 는 posedge CAM_PCLK 에서 샘플링하므로
    //    testbench 에서는 negedge 에서 데이터를 변경해줌.
    // --------------------------------------------------------
    task send_pixel(input [15:0] pixel);
    begin
        // High byte 전송
        @(negedge CAM_PCLK);
        CAM_DATA = pixel[15:8];

        // Low byte 전송
        @(negedge CAM_PCLK);
        CAM_DATA = pixel[7:0];
    end
    endtask

    // --------------------------------------------------------
    // Task: 한 라인(가로 480픽셀)을 전송
    //  - HSYNC = 1 동안 데이터 유효
    //  - 라인 끝에서 HSYNC를 0으로 떨어뜨려서
    //    camera_to_ram 내부의 v_count 증가 조건을 만족시킴
    // --------------------------------------------------------
    task send_line(input integer line_idx);
        integer x;
        reg [15:0] pix;
    begin
        // 라인 시작
        CAM_HSYNC = 1'b1;

        for (x = 0; x < IMG_W; x = x + 1) begin
            // 간단한 패턴: y방향으로 Red, x방향으로 Green, (x+y)로 Blue
            pix[15:11] = line_idx[4:0];         // R (5bit)
            pix[10:5]  = x[5:0];                // G (6bit)
            pix[4:0]   = x + line_idx[4:0];   // B (5bit)

            send_pixel(pix);
        end

        // 라인 끝: HSYNC low + 약간의 H-blank
        @(negedge CAM_PCLK);
        CAM_HSYNC = 1'b0;
        CAM_DATA  = 8'h00;

        // H-blank 조금 더
        repeat (10) @(negedge CAM_PCLK);
    end
    endtask

    // --------------------------------------------------------
    // Task: 전체 프레임(480x272)을 전송
    //  - VSYNC = 0 동안 한 프레임
    //  - 각 라인 사이에 HSYNC falling edge가 나오므로
    //    camera_to_ram 내부 v_count 가 증가함
    // --------------------------------------------------------
    task send_frame;
        integer y;
    begin
        // Frame 시작: VSYNC active-low
        @(negedge CAM_PCLK);
        CAM_VSYNC = 1'b0;

        // 약간의 vertical front porch (옵션)
        repeat (10) @(negedge CAM_PCLK);

        // 모든 라인 전송
        for (y = 0; y < IMG_H; y = y + 1) begin
            send_line(y);
        end

        // Frame 끝: VSYNC high (idle)
        @(negedge CAM_PCLK);
        CAM_VSYNC = 1'b1;
        CAM_HSYNC = 1'b0;
        CAM_DATA  = 8'h00;

        // Vertical blanking
        repeat (100) @(negedge CAM_PCLK);
    end
    endtask

    // --------------------------------------------------------
    // (옵션) LCD 측 모니터링: 몇 개 픽셀만 출력 확인
    //  - 실제 검증에서는 waveform에서 oLcdR/G/B, oLcdHSync/VSync를
    //    확인하거나, 별도 로직으로 PPM 파일을 만드는 쪽으로
    //    확장하셔도 됩니다.
    // --------------------------------------------------------
    integer lcd_pixel_cnt;
    always @(posedge oLcdClk or negedge iRst_n) begin
        if (!iRst_n) begin
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
