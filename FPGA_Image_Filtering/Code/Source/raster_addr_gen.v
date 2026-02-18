// ============================================================================
// 모듈명 : raster_addr_gen 
// ============================================================================
module raster_addr_gen #(
  parameter IMG_W  = 480,
  parameter IMG_H  = 272,
  parameter ROW_W  = 9,
  parameter COL_W  = 9,
  parameter ADDR_W = 17
)(
  input  wire                   iClk,
  input  wire                   iRst_n,
  input  wire                   step_en,        // 1클럭 펄스: 한 칸 전진

  output reg  [ROW_W-1:0]       row,
  output reg  [COL_W-1:0]       col,

  output wire                   at_row_start,
  output wire                   at_row_end,
  output wire                   first_row,
  output wire                   last_row,

  output reg  [ADDR_W-1:0]      linear_addr,    // 행우선 선형 주소
  output reg                    frame_done_pulse
);

  assign at_row_start = (col == {COL_W{1'b0}});
  assign at_row_end   = (col == (IMG_W[COL_W-1:0]-1));
  assign first_row    = (row == {ROW_W{1'b0}});
  assign last_row     = (row == (IMG_H[ROW_W-1:0]-1));

  always @(posedge iClk or negedge iRst_n) begin
    if (!iRst_n) begin
      row <= {ROW_W{1'b0}};
      col <= {COL_W{1'b0}};
      linear_addr <= {ADDR_W{1'b0}};
      frame_done_pulse <= 1'b0;
    end else begin
      frame_done_pulse <= 1'b0;

      // CE & step_en 동시 유효일 때만 전진
      if (step_en) begin
        if (!at_row_end) begin
          col         <= col + {{(COL_W-1){1'b0}},1'b1};
          linear_addr <= linear_addr + {{(ADDR_W-1){1'b0}},1'b1};
        end else if (!last_row) begin
          row         <= row + {{(ROW_W-1){1'b0}},1'b1};
          col         <= {COL_W{1'b0}};
          linear_addr <= ( (row + {{(ROW_W-1){1'b0}},1'b1}) * IMG_W );
        end else begin
          // 마지막 픽셀 → 프레임 종료
          frame_done_pulse <= 1'b1;
          row         <= {ROW_W{1'b0}};
          col         <= {COL_W{1'b0}};
          linear_addr <= {ADDR_W{1'b0}};
        end
      end
    end
  end
endmodule
