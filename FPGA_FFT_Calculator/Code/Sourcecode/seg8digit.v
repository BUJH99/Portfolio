//------------------------------------------------------------------------------
// 8자리 7-Segment 드라이버 (부호/소수점 지원)
//------------------------------------------------------------------------------
module seg8digit(
      input        i_rstn   ,
      input        i_clk    ,
      input        i_pls_1k ,
      input [31:0] i_bcd8d  ,   // [31:28] digit7 ... [3:0] digit0
      input [7:0]  i_dp_mask,   // 1이면 해당 digit의 dot ON

      output [7:0] o_seg_d  ,   // {dot, a~g}
      output [7:0] o_seg_com    // digit 선택
  );
  
  reg [2:0] cnt_com;
  reg [7:0] r_seg_com;
  reg [7:0] r_seg_d;
  
  wire [3:0] w_bcd_sel;
  wire [6:0] w_segb;
  wire [7:0] w_seg_com;
  wire       w_dot;
  
  // 자리 순환 카운터
  always@(posedge i_clk or negedge i_rstn) begin
      if(!i_rstn) begin
          cnt_com <= 3'd0;
      end
      else if(i_pls_1k) begin
          if(cnt_com==3'd7) begin
              cnt_com <= 3'd0;
          end
          else begin
              cnt_com <= cnt_com + 3'd1;
          end
      end
  end

  // 현재 선택된 자리의 BCD
  assign w_bcd_sel =
      (cnt_com == 3'd0) ? i_bcd8d[31:28] : // digit7 (MSD)
      (cnt_com == 3'd1) ? i_bcd8d[27:24] : // digit6
      (cnt_com == 3'd2) ? i_bcd8d[23:20] : // digit5  
      (cnt_com == 3'd3) ? i_bcd8d[19:16] : // digit4  
      (cnt_com == 3'd4) ? i_bcd8d[15:12] : // digit3  
      (cnt_com == 3'd5) ? i_bcd8d[11:08] : // digit2  
      (cnt_com == 3'd6) ? i_bcd8d[07:04] : // digit1  
                          i_bcd8d[03:00] ; // digit0            

  // BCD -> segment (a~g)
  assign w_segb =     
      (w_bcd_sel == 4'h0) ? (7'h3f) : // "0"
      (w_bcd_sel == 4'h1) ? (7'h06) : // "1"
      (w_bcd_sel == 4'h2) ? (7'h5b) : // "2"
      (w_bcd_sel == 4'h3) ? (7'h4f) : // "3"
      (w_bcd_sel == 4'h4) ? (7'h66) : // "4"
      (w_bcd_sel == 4'h5) ? (7'h6d) : // "5"
      (w_bcd_sel == 4'h6) ? (7'h7d) : // "6"
      (w_bcd_sel == 4'h7) ? (7'h07) : // "7"
      (w_bcd_sel == 4'h8) ? (7'h7f) : // "8"
      (w_bcd_sel == 4'h9) ? (7'h6f) : // "9"
      (w_bcd_sel == 4'hA) ? (7'h40) : // "-" (middle segment만 ON)
      (w_bcd_sel == 4'hB) ? (7'h00) : // blank
                            (7'h00) ; // default blank
  
  // digit 선택 (common)
  assign w_seg_com = 
      (cnt_com==3'd0) ? 8'b1000_0000 : // digit7 (MSD)
      (cnt_com==3'd1) ? 8'b0100_0000 : // digit6
      (cnt_com==3'd2) ? 8'b0010_0000 : // digit5
      (cnt_com==3'd3) ? 8'b0001_0000 : // digit4
      (cnt_com==3'd4) ? 8'b0000_1000 : // digit3
      (cnt_com==3'd5) ? 8'b0000_0100 : // digit2
      (cnt_com==3'd6) ? 8'b0000_0010 : // digit1
                        8'b0000_0001 ; // digit0

  // 소수점 마스크
  assign w_dot = i_dp_mask[cnt_com];
                                 
  always@(posedge i_clk or negedge i_rstn) begin
      if(!i_rstn) begin
          r_seg_com <= 8'h0;
          r_seg_d   <= 8'h0;
      end
      else if(i_pls_1k) begin
          r_seg_com <= w_seg_com;
          r_seg_d   <= {w_dot, w_segb};
      end
  end

  assign o_seg_com = r_seg_com;
  assign o_seg_d   = r_seg_d;
  
endmodule
