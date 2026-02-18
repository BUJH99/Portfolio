// ============================================================================
// Module : rgb565_to_rgb888
// 기능   : RGB565(16bit)를 RGB888(24bit)로 변환하여 메모리로 출력
//          - 입력: clk, rst_n, i_en, i_addr, i_data(RGB565)
//          - 출력: oMemEn, oMemWe, oMemAddr, oMemData(RGB888)
// ============================================================================
module rgb565_to_rgb888 #(
    parameter ADDR_W = 17   // 주소 비트 폭 (필요에 따라 변경)
)(
    input  wire                 clk,
    input  wire                 rst_n,     // Active-Low Reset
    input  wire                 i_en,      // 입력 데이터 유효 신호
    input  wire [ADDR_W-1:0]    i_addr,    // 입력 주소
    input  wire [15:0]          i_data,    // 입력 RGB565 데이터

    output reg                  oMemEn,    // 메모리 Enable
    output reg                  oMemWe,    // 메모리 Write Enable
    output reg  [ADDR_W-1:0]    oMemAddr,  // 출력 주소 (입력 주소 패스)
    output reg  [23:0]          oMemData   // 출력 RGB888 데이터
);

    // RGB565 분리
    wire [4:0] r5 = i_data[15:11];
    wire [5:0] g6 = i_data[10:5];
    wire [4:0] b5 = i_data[4:0];

    // 5/6bit -> 8bit 확장 (상위비트 반복 방식)
    wire [7:0] r8 = {r5, r5[4:2]};   // 5bit -> 8bit
    wire [7:0] g8 = {g6, g6[5:4]};   // 6bit -> 8bit
    wire [7:0] b8 = {b5, b5[4:2]};   // 5bit -> 8bit

    wire [23:0] rgb888 = {r8, g8, b8};

    // 동기 로직: i_en이 1일 때만 출력 업데이트
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            oMemEn   <= 1'b0;
            oMemWe   <= 1'b0;
            oMemAddr <= {ADDR_W{1'b0}};
            oMemData <= 24'd0;
        end else begin
            // Enable / Write Enable은 i_en 그대로 전달
            oMemEn <= i_en;
            oMemWe <= i_en;

            if (i_en) begin
                // 주소는 그대로 패스
                oMemAddr <= i_addr;
                // 데이터는 RGB565 -> RGB888 변환 후 전달
                oMemData <= rgb888;
            end
            // i_en == 0일 때는 주소/데이터는 그대로 유지해도 되고,
            // 필요하다면 아래처럼 0으로 클리어해도 됩니다.
            // else begin
            //     oMemAddr <= oMemAddr;
            //     oMemData <= oMemData;
            // end
        end
    end

endmodule
