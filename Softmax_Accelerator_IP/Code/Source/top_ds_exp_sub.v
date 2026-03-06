`timescale 1ns/1ps
module top_softmax_axis_simple #(
    parameter integer C_MAX  = 1024,
    parameter integer ADDR_W = 10
)(
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Stream input (FP32)
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire [31:0]  s_axis_tdata,
    input  wire         s_axis_tlast,
    input  wire [3:0]   s_axis_tkeep,

    // AXI4-Stream output (FP32)
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire [31:0]  m_axis_tdata,
    output wire         m_axis_tlast,
    output wire [3:0]   m_axis_tkeep
);

  /**********************************************************************
   * Stage 0: 인터커넥트 / 레디 체인 (이름만 정리, 기능 동일)
   **********************************************************************/
  // downscale → exp1
  assign m_axis_tkeep = 4'hF;
  
  wire        ds_ready;
  wire        ds_valid;
  wire [15:0] ds_data;
  wire        ds_last;

  // exp1 → adder
  wire         exp_valid_o;
  wire         exp_last_o;
  wire [15:0]  exp_data_o;
  wire         add_ready_o;

  // adder → ln
  wire         add_valid_o;
  wire [15:0]  add_data_o;
  wire         ln_ready_o;

  // ln → sub
  wire         ln_valid_o;
  wire [15:0]  ln_data_i;

  // sub → exp2
  wire         sub_valid_o;
  wire [15:0]  sub_data_o;
  wire         sub_last;

  // exp2 주변 ready (★ 두 개로 분리!)
  wire         exp2_back_ready_o; // exp2.oReady → sub.ready 로 전달되는 back-pressure (exp2의 출력)
  wire         fp32_sink_ready_o; // u016_to_fp32.s_axis_tready → exp2.iReady 로 전달되는 sink ready (u016_to_fp32의 출력)

  // exp2 → u016_to_fp32
  wire         exp2_valid_o;
  wire         exp2_last_o;
  wire [15:0]  exp2_data_o;

  //========================
  // Stage1: Downscale (FP32 → Q7.8)
  //========================
  downscale_block #(.C_MAX(C_MAX), .ADDR_W(ADDR_W)) u_down (
      .clk(clk), .rst_n(rst_n),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tlast (s_axis_tlast),

      .m_axis_tvalid(ds_valid),
      .m_axis_tready(ds_ready),
      .m_axis_tdata (ds_data),
      .m_axis_tlast (ds_last)
  );

  //========================
  // Stage2: EXP #1 (Q7.8 → Q0.16)
  //========================
  exp_Block1 u_exp1 (
      .iClk  (clk),
      .iRsn  (rst_n),
      .iValid(ds_valid),
      .oReady(ds_ready),
      .iLast (ds_last),
      .iData (ds_data),
      .oValid(exp_valid_o),
      .iReady(add_ready_o),
      .oLast (exp_last_o),
      .oData (exp_data_o)
  );

  //========================
  // Stage3: ADD → LN
  //========================
  Adder_block adder (
      .iClk  (clk),
      .iRsn  (rst_n),
      .iValid(exp_valid_o),
      .oReady(add_ready_o),
      .iLast (exp_last_o),
      .iData (exp_data_o),
      .oValid(add_valid_o),
      .iReady(ln_ready_o),
      .oData (add_data_o)
  );

  ln_block ln (
      .iClk  (clk),
      .iRsn  (rst_n),
      .iValid(add_valid_o),
      .oReady(ln_ready_o),
      .iData (add_data_o),
      .oValid(ln_valid_o),
      .iReady(1'b1),
      .oData (ln_data_i)
  );

  //========================
  // Stage4: SUB (Q7.8 vec - lnSum scalar) → Q7.8
  //========================
  Sub_block #(.CNT_MAX(C_MAX)) u_sub (
      .clk  (clk),
      .rst_n(rst_n),
      .downscale_data_i       (ds_data),
      .downscale_data_valid_i (ds_valid & ds_ready), // 기존 연결 유지
      .downscale_last_i       (ds_last),
      .in_data_i      (ln_data_i),
      .in_data_valid_i(ln_valid_o),
      .ready          (exp2_back_ready_o),  // ★ exp2.oReady(출력)만 연결
      .data_o         (sub_data_o),
      .data_valid_o   (sub_valid_o),
      .last           (sub_last)
  );

  //========================
  // Stage5: EXP #2 (Q7.8 → U0.16)
  //========================
    exp_Block2 u_exp2 (
      .iClk  (clk),
      .iRsn  (rst_n),
      .iValid(sub_valid_o),
      .oReady(exp2_back_ready_o), // ★ exp2의 oReady → sub로 back-pressure
      .iLast (sub_last),
      .iData (sub_data_o),
      .oValid(exp2_valid_o),
      .iReady(fp32_sink_ready_o), // ★ u016_to_fp32에서 온 ready를 exp2의 iReady로
      .oLast (exp2_last_o),
      .oData (exp2_data_o)
  );

  //========================
  // Stage6: U0.16 → FP32 (콤비) & AXIS 출력
  //========================
  u016_to_fp32 u16tofp32 (
      .clk  (clk),
      .rst_n(rst_n),
      .s_axis_tvalid(exp2_valid_o),
      .s_axis_tready(fp32_sink_ready_o), // ★ 이 신호 하나만 u16→exp2(iReady) 경로 드라이브
      .s_axis_tdata (exp2_data_o),
      .s_axis_tlast (exp2_last_o),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready),
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tlast (m_axis_tlast)
  );

endmodule
