/*
[MODULE_INFO_START]
Name: Rgb565ToRgb888
Role: Convert camera RGB565 pixels into RGB888 memory writes.
Summary:
  - Expands RGB565 color channels to RGB888.
  - Passes memory enable, write enable, and address through with converted data.
[MODULE_INFO_END]
*/

// ============================================================================
// Module : Rgb565ToRgb888
// 기능   : RGB565(16bit)를 RGB888(24bit)로 변환하여 메모리로 출력
//          - 입력: iClk, iRstn, iValid, iAddr, iData(RGB565)
//          - 출력: oMemEn, oMemWe, oMemAddr, oMemData(RGB888)
// ============================================================================
module Rgb565ToRgb888 #(
    parameter P_ADDR_WIDTH = 17   // 주소 비트 폭 (필요에 따라 변경)
)(
    input logic                 iClk,
    input logic                 iRstn,     // Active-Low Reset
    input logic                 iValid,      // 입력 데이터 유효 신호
    input logic [P_ADDR_WIDTH-1:0]    iAddr,    // 입력 주소
    input logic [15:0]          iData,    // 입력 RGB565 데이터

    output logic                  oMemEn,    // 메모리 Enable
    output logic                  oMemWe,    // 메모리 Write Enable
    output logic  [P_ADDR_WIDTH-1:0]    oMemAddr,  // 출력 주소 (입력 주소 패스)
    output logic  [23:0]          oMemData   // 출력 RGB888 데이터
);

    // RGB565 분리
    logic [4:0] PixelR5;
    logic [5:0] PixelG6;
    logic [4:0] PixelB5;

    // 5/6bit -> 8bit 확장 (상위비트 반복 방식)
    logic [7:0] PixelR8;
    logic [7:0] PixelG8;
    logic [7:0] PixelB8;

    logic [23:0] Rgb888Data;

    assign PixelR5 = iData[15:11];
    assign PixelG6 = iData[10:5];
    assign PixelB5 = iData[4:0];
    assign PixelR8 = {PixelR5, PixelR5[4:2]};
    assign PixelG8 = {PixelG6, PixelG6[5:4]};
    assign PixelB8 = {PixelB5, PixelB5[4:2]};
    assign Rgb888Data = {PixelR8, PixelG8, PixelB8};

    // 동기 로직: iValid이 1일 때만 출력 업데이트
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oMemEn   <= 1'b0;
            oMemWe   <= 1'b0;
            oMemAddr <= {P_ADDR_WIDTH{1'b0}};
            oMemData <= 24'd0;
        end else begin
            // Enable / Write Enable은 iValid 그대로 전달
            oMemEn <= iValid;
            oMemWe <= iValid;

            if (iValid) begin
                // 주소는 그대로 패스
                oMemAddr <= iAddr;
                // 데이터는 RGB565 -> RGB888 변환 후 전달
                oMemData <= Rgb888Data;
            end
            // iValid == 0일 때는 주소/데이터는 그대로 유지해도 되고,
            // 필요하다면 아래처럼 0으로 클리어해도 됩니다.
            // else begin
            //     oMemAddr <= oMemAddr;
            //     oMemData <= oMemData;
            // end
        end
    end

endmodule
