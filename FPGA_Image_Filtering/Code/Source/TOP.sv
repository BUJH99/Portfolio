/*
[MODULE_INFO_START]
Name: TOP
Role: Top-level image filtering wrapper for camera input, convolution pipeline, frame buffers, and LCD output.
Summary:
  - Wires camera SCCB setup, camera capture, RGB conversion, window generation, convolution, output conversion, memories, and LCD timing.
  - Provides direct top-level camera, LCD, clock, reset, and filter mode ports.
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module TOP (
    //==================================================================
    // System Interface
    //==================================================================
    input logic          iClk,          // 100MHz System Clock
    input logic          iRstn,        // Active Low Reset

    inout  wire                 ioCamSccbScl,
    inout  wire                 ioCamSccbSda,
    input logic                 iCamPclk,
    input logic  [7:0]          iCamData,
    output logic                 oCamResetn,
    input logic                 iCamHsync,
    input logic                 iCamVsync,
    output logic                 oCamPwdn,
    output logic                 oCamMclk,
    // 0:bypass, 1:sharpen, 2:edge enhance, 3:emboss
    input logic [1:0]    iFilterMode,
    //==================================================================
    // TFT-LCD Interface
    //==================================================================
    output logic          oLcdClk,       // LCD Pixel Clock
    output logic          oLcdHSync,
    output logic          oLcdVSync,
    output logic          oLcdDe,        
    output logic          oLcdBacklight, 
    output logic [4:0]    oLcdR,
    output logic [5:0]    oLcdG,
    output logic [4:0]    oLcdB
);

    //==================================================================
    // LCD Backlight On
    //==================================================================
    assign oLcdBacklight = 1'b1;


    //==================================================================
    // Internal Wires
    //==================================================================
    logic LcdClkEn;
    logic CamPowerClk;
    
    logic CamWrEn;
    logic [16:0] CamWrAddr;
    logic [15:0] CamWrData;
    
    logic InBufEnA;
    logic InBufWeA;
    logic [16:0] InBufAddrA;
    logic [23:0] InBufWrDataA;
    
    // InBuf Interface
    logic [16:0] InBufAddr;
    logic        InBufEn;
    logic [23:0] InBufData;

    // Window -> Conv Interface
    logic [215:0] WinData;
    logic         WinValid;
    logic         WinReady;

    // Conv -> PixelConv Interface
    logic [23:0]  ConvData;
    logic         ConvValid;
    logic         ConvReady;

    // PixelConv -> OutBuf Interface
    logic        OutBufEnA;
    logic        OutBufWeA;
    logic [16:0] OutBufAddrA;
    logic [15:0] OutBufWrDataA;

    // OutBuf -> LCD Interface
    logic [16:0] OutBufAddrB;
    logic [15:0] OutBufRdDataB;


    //==================================================================
    // 1. Clock Enable Generator
    //==================================================================
    ClockEnableGenerator uClockEnableGenerator (
        .iClk       (iClk),
        .iRstn     (iRstn),
        .oClkEn   (LcdClkEn)
    );
    
    ClkDivider    uCamMclkDivider(
        .iClk                      (iClk         ),
        .iDivCount                    (16'h0001       ),
        .oClk                      (oCamMclk       )
    );//25MHz


    ClkDivider    uI2cResetDivider(
        .iClk                      (oCamMclk       ),
        .iDivCount                    (16'h0064       ),
        .oClk                      (CamPowerClk   )
    );
    
    CamI2c uCamI2c(
        .iClk                      (CamPowerClk   ),
        .iCamSel                         (1'b1           ),
        .oCamResetn                 (oCamResetn     ),
        .oCamPwdn                   (oCamPwdn       ),
        .ioCamScl                    (ioCamSccbScl   ),
        .ioCamSda                    (ioCamSccbSda   )      
    );
    
    CameraToRam uCameraToRam(
        .iClk                      (iCamPclk       ),
        .iCamSel                       (1'b1           ),
        .iCamVsync                (iCamVsync      ),
        .iCamHsync                (iCamHsync      ),
        .iCamData                 (iCamData       ),
        .oRamWrEn                (CamWrEn    ),
        .oRamWrAddr              (CamWrAddr  ),
        .oRamWrData              (CamWrData  )
    );
    
    Rgb565ToRgb888 uRgb565ToRgb888(
        .iClk(iCamPclk),
        .iRstn(iRstn),
        .iValid(CamWrEn),
        .iAddr(CamWrAddr),
        .iData(CamWrData),
        
        .oMemEn(InBufEnA),
        .oMemWe(InBufWeA),
        .oMemAddr(InBufAddrA),
        .oMemData(InBufWrDataA)
    );
    
    //==================================================================
    // 2. Input Memory (InBuf)
    //==================================================================
    InputMemory_RGB888 uInputMemory (
        // Port A: Write (from CNN)
        .clka   (iCamPclk),
        .ena    (InBufEnA),
        .wea    (InBufWeA), 
        .addra  (InBufAddrA),
        .dina   (InBufWrDataA),
        
        // Port B: Read (to LCD)
        .clkb   (iClk),
        .enb    (InBufEn),             // Read Enable Always ON
        .addrb  (InBufAddr),
        .doutb  (InBufData)
        // .web, .dinb 포트는 IP 설정상 존재하지 않으므로 제거함
    );

    //==================================================================
    // 3. 3x3 Pixel Window Generator
    //==================================================================
    Window3x3LineBuffer #(
        .P_IMG_WIDTH(480), .P_IMG_HEIGHT(272)
    ) uWindow3x3 (
        .iClk       (iClk),
        .iRstn     (iRstn),
        .oBramAddr (InBufAddr),
        .oBramEn   (InBufEn),
        .iBramData (InBufData),
        .oValid    (WinValid),
        .oData     (WinData),
        .oFrameDone()
    );

    //==================================================================
    // 4. Convolution & ReLU
    //==================================================================
    Conv3x3ReluParam #(
        .P_PIX_BITS(24)
    ) uConv3x3Relu (
        .iClk       (iClk),
        .iRstn     (iRstn),
        .iFilterMode       (iFilterMode),
        .iData     (WinData),
        .iValid    (WinValid),
        .oReady    (WinReady),
        .oData     (ConvData),
        .oValid    (ConvValid),
        .iReady    (ConvReady)
    );

    //==================================================================
    // 5. Pixel Conversion
    //==================================================================
    Rgb888ToRgb565 uRgb888ToRgb565 (
        .iClk       (iClk),
        .iRstn     (iRstn),
        .oReady    (ConvReady),
        .iValid    (ConvValid),
        .iData     (ConvData),
        .oMemEn     (OutBufEnA),
        .oMemWe     (OutBufWeA),
        .oMemAddr   (OutBufAddrA),
        .oMemWrData     (OutBufWrDataA)
    );

    //==================================================================
    // 6. Output Memory (OutBuf) - [수정된 부분]
    //==================================================================
    // Port B의 dinb, web 포트를 제거했습니다. (Simple Dual Port RAM)
    OutputMemory_RGB565 uOutputMemory (
        // Port A: Write (from CNN)
        .clka   (iClk),
        .ena    (OutBufEnA),
        .wea    (OutBufWeA),
        .addra  (OutBufAddrA),
        .dina   (OutBufWrDataA),
        
        // Port B: Read (to LCD)
        .clkb   (iClk),
        .enb    (1'b1),             // Read Enable Always ON
        .addrb  (OutBufAddrB),
        .doutb  (OutBufRdDataB)
        // .web, .dinb 포트는 IP 설정상 존재하지 않으므로 제거함
    );

    //==================================================================
    // 7. Memory to TFT-LCD Controller
    //==================================================================
    MemToTftLcd uMemToTftLcd (
        .iClk       (iClk),
        .iRstn     (iRstn),
        .iClkEn   (LcdClkEn),
        .oMemAddr   (OutBufAddrB),
        .iMemData   (OutBufRdDataB),
        .oLcdClk    (oLcdClk),
        .oLcdHSync  (oLcdHSync),
        .oLcdVSync  (oLcdVSync),
        .oLcdDe     (oLcdDe),
        .oLcdR      (oLcdR),
        .oLcdG      (oLcdG),
        .oLcdB      (oLcdB)
    );

endmodule
