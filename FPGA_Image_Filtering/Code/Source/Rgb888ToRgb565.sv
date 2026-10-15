/*
[MODULE_INFO_START]
Name: Rgb888ToRgb565
Role: Convert RGB888 filtered pixels into RGB565 output memory writes.
Summary:
  - Tracks raster coordinates for output memory addressing.
  - Converts accepted RGB888 pixels to RGB565 data.
[MODULE_INFO_END]
*/

/********************************************************************************
*
* Module: Rgb888ToRgb565
*
* Description: RGB888 to RGB565 변환 및 주소 생성을 수행.
*
*
********************************************************************************/
module Rgb888ToRgb565 (
    //==================================================================
    // Port Declarations
    //==================================================================
    // --- System Signals ---
    input logic          iClk,           // 시스템 클럭 (e.g., 100MHz)
    input logic          iRstn,         // 시스템 리셋 (active-low)

    // --- Handshake Interface with Convolution Module (Consumer) ---
    output logic         oReady,        // 본 모듈이 데이터를 받을 준비가 되었음을 알림
    input logic          iValid,        // Convolution 모듈로부터 유효한 데이터가 왔음을 알림
    input logic [23:0]   iData,         // 24비트 RGB888 픽셀 데이터

    // --- Output Interface to OutBuf BRAM ---
    output logic         oMemEn,         // Memory Port Enable (to BRAM 'ena')
    output logic         oMemWe,         // Memory Write Enable (to BRAM 'wea')
    output logic [16:0]  oMemAddr,       // Memory Address (to BRAM 'addra')
    output logic [15:0]  oMemWrData          // Memory Write Data (to BRAM 'dina')
);

    //==================================================================
    // Parameters & Internal Signals
    //==================================================================
    parameter P_IMAGE_WIDTH = 480;
    parameter P_IMAGE_HEIGHT = 272;

    logic [$clog2(P_IMAGE_WIDTH)-1:0]   XCnt;
    logic [$clog2(P_IMAGE_HEIGHT)-1:0]  YCnt;

    // 데이터 전송(Transaction)은 valid와 ready 신호가 모두 High일 때만 발생
    logic TransferValid;

    assign TransferValid = iValid && oReady;

    //==================================================================
    // Sequential Logic: Coordinate Counter
    //==================================================================
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            XCnt <= 0;
            YCnt <= 0;
        end else begin
            if (TransferValid) begin
                if (XCnt == P_IMAGE_WIDTH - 1 && YCnt == P_IMAGE_HEIGHT - 1) begin
                    XCnt <= 0;
                    YCnt <= 0;
                end else if (XCnt == P_IMAGE_WIDTH - 1) begin
                    XCnt <= 0;
                    YCnt <= YCnt + 1;
                end else begin
                    XCnt <= XCnt + 1;
                end
            end
        end
    end
    
    //==================================================================
    // Combinational Logic: Output Generation
    //==================================================================
    // --- Handshake & Control Signal ---
    // oReady는 항상 1로 설정. 이 모듈은 항상 데이터를 즉시 처리할 수 있음.
    assign oReady = 1'b1;

    // BRAM 제어 신호 생성
    // 데이터 전송이 유효할 때 BRAM 포트를 활성화하고 쓰기 동작을 수행.
    // 현재는 쓰기 동작만 있으므로 oMemEn과 oMemWe는 동일하게 동작.
    assign oMemEn = TransferValid;
    assign oMemWe = TransferValid;
    
    // --- Address & Data Conversion ---
    // 현재 (x,y) 좌표를 OutBuf의 1차원 메모리 주소로 변환
    assign oMemAddr = (YCnt * P_IMAGE_WIDTH) + XCnt;
    
    // 24비트 RGB888 데이터를 16비트 RGB565로 변환.
    // iData: {R[23:16], G[15:8], B[7:0]}
    // oMemWrData: {R[15:11], G[10:5], B[4:0]} (16 bits)
    assign oMemWrData = { iData[23:19], iData[15:10], iData[7:3] };

endmodule
