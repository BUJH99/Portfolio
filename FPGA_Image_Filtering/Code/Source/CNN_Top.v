`timescale 1ns / 1ps

module CNN_Top (
    //==================================================================
    // System Interface
    //==================================================================
    input  wire          iClk,          // 100MHz System Clock
    input  wire          iRst_n,        // Active Low Reset

    inout  wire                 CAM_SCCB_SCL,
    inout  wire                 CAM_SCCB_SDA,
    input  wire                 CAM_PCLK,
    input  wire  [7:0]          CAM_DATA,
    output wire                 CAM_RESETn,
    input  wire                 CAM_HSYNC,
    input  wire                 CAM_VSYNC,
    output wire                 CAM_PWDN,
    output wire                 CAM_MCLK,
    // 00: Sharpen, 01: Edge Enhance, 10/11: Bypass
    input  wire [1:0]    iMode,
    //==================================================================
    // TFT-LCD Interface
    //==================================================================
    output wire          oLcdClk,       // LCD Pixel Clock
    output wire          oLcdHSync,
    output wire          oLcdVSync,
    output wire          oLcdDe,        
    output wire          oLcdBacklight, 
    output wire [4:0]    oLcdR,
    output wire [5:0]    oLcdG,
    output wire [4:0]    oLcdB
);

    //==================================================================
    // LCD Backlight On
    //==================================================================
    assign oLcdBacklight = 1'b1;


    //==================================================================
    // Internal Wires
    //==================================================================
    wire w_en_clk;
    wire clk_campower;
    
    wire cam_wr_en_w;
    wire [16:0] cam_wr_addr_w;
    wire [15:0] cam_wr_data_w;
    
    wire w_inbuf_en_a;
    wire w_inbuf_we_a;
    wire [16:0] w_inbuf_addr_a;
    wire [23:0] w_inbuf_wdata_a;
    
    // InBuf Interface
    wire [16:0] w_inbuf_addr;
    wire        w_inbuf_en;
    wire [23:0] w_inbuf_dout;

    // Window -> Conv Interface
    wire [215:0] w_win_data;
    wire         w_win_valid;
    wire         w_win_ready;

    // Conv -> PixelConv Interface
    wire [23:0]  w_conv_data;
    wire         w_conv_valid;
    wire         w_conv_ready;

    // PixelConv -> OutBuf Interface
    wire        w_outbuf_en_a;
    wire        w_outbuf_we_a;
    wire [16:0] w_outbuf_addr_a;
    wire [15:0] w_outbuf_wdata_a;

    // OutBuf -> LCD Interface
    wire [16:0] w_outbuf_addr_b;
    wire [15:0] w_outbuf_rdata_b;


    //==================================================================
    // 1. Clock Enable Generator
    //==================================================================
    clock_enable_generator u_clk_gen (
        .iClk       (iClk),
        .iRst_n     (iRst_n),
        .o_wEnClk   (w_en_clk)
    );
    
    clk_gen2    CLK_GEN_MAIN(
        .clk_i                      (iClk         ),
        .count_i                    (16'h0001       ),
        .clk_o                      (CAM_MCLK       )
    );//25MHz


    clk_gen2    I2C_RESET(
        .clk_i                      (CAM_MCLK       ),
        .count_i                    (16'h0064       ),
        .clk_o                      (clk_campower   )
    );
    
    cam_i2c CAM_SETUP_SCCB(
        .clk_i                      (clk_campower   ),
        .sw                         (1'b1           ),
        .cam_rst_no                 (CAM_RESETn     ),
        .cam_pwdn                   (CAM_PWDN       ),
        .cam_scl                    (CAM_SCCB_SCL   ),
        .cam_sda                    (CAM_SCCB_SDA   )      
    );
    
    camera_to_ram CAMEARA_TO_RAM(
        .clk_i                      (CAM_PCLK       ),
        .sw_i                       (1'b1           ),
        .cam_vsync_i                (CAM_VSYNC      ),
        .cam_hsync_i                (CAM_HSYNC      ),
        .cam_data_i                 (CAM_DATA       ),
        .ram_wr_en_o                (cam_wr_en_w    ),
        .ram_wr_addr_o              (cam_wr_addr_w  ),
        .ram_wr_data_o              (cam_wr_data_w  )
    );
    
    rgb565_to_rgb888 u_pix_convRGB888(
        .clk(CAM_PCLK),
        .rst_n(iRst_n),
        .i_en(cam_wr_en_w),
        .i_addr(cam_wr_addr_w),
        .i_data(cam_wr_data_w),
        
        .oMemEn(w_inbuf_en_a),
        .oMemWe(w_inbuf_we_a),
        .oMemAddr(w_inbuf_addr_a),
        .oMemData(w_inbuf_wdata_a)
    );
    
    //==================================================================
    // 2. Input Memory (InBuf)
    //==================================================================
    InputMemory_RGB888 u_in_buf (
        // Port A: Write (from CNN)
        .clka   (CAM_PCLK),
        .ena    (w_inbuf_en_a),
        .wea    (w_inbuf_we_a), 
        .addra  (w_inbuf_addr_a),
        .dina   (w_inbuf_wdata_a),
        
        // Port B: Read (to LCD)
        .clkb   (iClk),
        .enb    (w_inbuf_en),             // Read Enable Always ON
        .addrb  (w_inbuf_addr),
        .doutb  (w_inbuf_dout)
        // .web, .dinb 포트는 IP 설정상 존재하지 않으므로 제거함
    );

    //==================================================================
    // 3. 3x3 Pixel Window Generator
    //==================================================================
    window3x3_case9 #(
        .IMG_W(480), .IMG_H(272)
    ) u_window (
        .iClk       (iClk),
        .iRst_n     (iRst_n),
        .bram_addr  (w_inbuf_addr),
        .bram_en    (w_inbuf_en),
        .bram_dout  (w_inbuf_dout),
        .o_ready    (w_win_ready),
        .o_valid    (w_win_valid),
        .o_data     (w_win_data),
        .frame_done ()
    );

    //==================================================================
    // 4. Convolution & ReLU
    //==================================================================
    Conv3x3_ReLU_param #(
        .PIX_BITS(24)
    ) u_conv (
        .iClk       (iClk),
        .iRst_n     (iRst_n),
        .mode       (iMode),
        .i_data     (w_win_data),
        .i_valid    (w_win_valid),
        .i_ready    (w_win_ready),
        .o_data     (w_conv_data),
        .o_valid    (w_conv_valid),
        .o_ready    (w_conv_ready)
    );

    //==================================================================
    // 5. Pixel Conversion
    //==================================================================
    pixel_conversion u_pix_conv (
        .iClk       (iClk),
        .iRst_n     (iRst_n),
        .i_ready    (w_conv_ready),
        .i_valid    (w_conv_valid),
        .i_data     (w_conv_data),
        .oMemEn     (w_outbuf_en_a),
        .oMemWe     (w_outbuf_we_a),
        .oMemAddr   (w_outbuf_addr_a),
        .oMemWd     (w_outbuf_wdata_a)
    );

    //==================================================================
    // 6. Output Memory (OutBuf) - [수정된 부분]
    //==================================================================
    // Port B의 dinb, web 포트를 제거했습니다. (Simple Dual Port RAM)
    OutputMemory_RGB565 u_out_buf (
        // Port A: Write (from CNN)
        .clka   (iClk),
        .ena    (w_outbuf_en_a),
        .wea    (w_outbuf_we_a),
        .addra  (w_outbuf_addr_a),
        .dina   (w_outbuf_wdata_a),
        
        // Port B: Read (to LCD)
        .clkb   (iClk),
        .enb    (1'b1),             // Read Enable Always ON
        .addrb  (w_outbuf_addr_b),
        .doutb  (w_outbuf_rdata_b)
        // .web, .dinb 포트는 IP 설정상 존재하지 않으므로 제거함
    );

    //==================================================================
    // 7. Memory to TFT-LCD Controller
    //==================================================================
    Mem_To_TFT_LCD u_lcd_ctrl (
        .iClk       (iClk),
        .iRst_n     (iRst_n),
        .i_wEnClk   (w_en_clk),
        .oMemAddr   (w_outbuf_addr_b),
        .iMemData   (w_outbuf_rdata_b),
        .oLcdClk    (oLcdClk),
        .oLcdHSync  (oLcdHSync),
        .oLcdVSync  (oLcdVSync),
        .oLcdDe     (oLcdDe),
        .oLcdR      (oLcdR),
        .oLcdG      (oLcdG),
        .oLcdB      (oLcdB)
    );

endmodule