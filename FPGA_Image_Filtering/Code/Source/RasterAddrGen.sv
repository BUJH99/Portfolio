/*
[MODULE_INFO_START]
Name: RasterAddrGen
Role: Generate raster row, column, linear address, and frame boundary flags.
Summary:
  - Advances one pixel position per step enable.
  - Wraps row, column, and address at frame boundaries.
[MODULE_INFO_END]
*/

// ============================================================================
// 모듈명 : RasterAddrGen 
// ============================================================================
module RasterAddrGen #(
  parameter P_IMG_WIDTH  = 480,
  parameter P_IMG_HEIGHT  = 272,
  parameter P_ROW_WIDTH  = 9,
  parameter P_COL_WIDTH  = 9,
  parameter P_ADDR_WIDTH = 17
)(
  input logic                   iClk,
  input logic                   iRstn,
  input logic                   iStepEn,        // 1클럭 펄스: 한 칸 전진

  output logic  [P_ROW_WIDTH-1:0]       oRow,
  output logic  [P_COL_WIDTH-1:0]       oCol,

  output logic                   oRowStart,
  output logic                   oRowEnd,
  output logic                   oFirstRow,
  output logic                   oLastRow,

  output logic  [P_ADDR_WIDTH-1:0]      oLinearAddr,    // 행우선 선형 주소
  output logic                    oFrameDonePulse
);

  assign oRowStart = (oCol == {P_COL_WIDTH{1'b0}});
  assign oRowEnd   = (oCol == (P_IMG_WIDTH[P_COL_WIDTH-1:0]-1));
  assign oFirstRow    = (oRow == {P_ROW_WIDTH{1'b0}});
  assign oLastRow     = (oRow == (P_IMG_HEIGHT[P_ROW_WIDTH-1:0]-1));

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      oRow <= {P_ROW_WIDTH{1'b0}};
      oCol <= {P_COL_WIDTH{1'b0}};
      oLinearAddr <= {P_ADDR_WIDTH{1'b0}};
      oFrameDonePulse <= 1'b0;
    end else begin
      oFrameDonePulse <= 1'b0;

      // CE & iStepEn 동시 유효일 때만 전진
      if (iStepEn) begin
        if (!oRowEnd) begin
          oCol         <= oCol + {{(P_COL_WIDTH-1){1'b0}},1'b1};
          oLinearAddr <= oLinearAddr + {{(P_ADDR_WIDTH-1){1'b0}},1'b1};
        end else if (!oLastRow) begin
          oRow         <= oRow + {{(P_ROW_WIDTH-1){1'b0}},1'b1};
          oCol         <= {P_COL_WIDTH{1'b0}};
          oLinearAddr <= ( (oRow + {{(P_ROW_WIDTH-1){1'b0}},1'b1}) * P_IMG_WIDTH );
        end else begin
          // 마지막 픽셀 → 프레임 종료
          oFrameDonePulse <= 1'b1;
          oRow         <= {P_ROW_WIDTH{1'b0}};
          oCol         <= {P_COL_WIDTH{1'b0}};
          oLinearAddr <= {P_ADDR_WIDTH{1'b0}};
        end
      end
    end
  end
endmodule
