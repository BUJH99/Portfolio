`timescale 1ns/1ps
// ============================================================================
// Top: AXIS FP32 → (동시에 Q7.8 버퍼링 + Xmax 추적) → TLAST 후 (Xi - Xmax) Q7.8 출력
// ============================================================================
module downscale_block #(
    parameter integer C_MAX  = 1024,
    parameter integer ADDR_W = 10           // 2^ADDR_W >= C_MAX
)(
    input  wire                 clk,
    input  wire                 rst_n,    // active-low

    // AXIS in (FP32)
    input  wire                 s_axis_tvalid,
    output wire                 s_axis_tready,
    input  wire [31:0]          s_axis_tdata,
    input  wire                 s_axis_tlast,

    // AXIS out (Q7.8, signed)
    output wire                 m_axis_tvalid,
    input  wire                 m_axis_tready,
    output wire [15:0]          m_axis_tdata,
    output wire                 m_axis_tlast
);
    // -----------------------------
    // 변환: FP32 → Q7.8
    // -----------------------------
    wire  signed [15:0] q78_in;
    fp32_to_q78 u_fp32_to_q78 (
        .fp32(s_axis_tdata),
        .q78 (q78_in)
    );

    // -----------------------------
    // FSM: 주소/수락/배출 제어
    // READ_LAT = 1 (spram_q78 읽기 지연)
    // -----------------------------
    localparam READ_LAT = 1;

    wire we;                     // write enable
    wire [ADDR_W-1:0] waddr;     // write address
    wire re;                     // read enable
    wire [ADDR_W-1:0] raddr;     // read address
    wire in_fire;                // 입력 수락 펄스
    wire start_first;            // 벡터의 첫 샘플 수락 시 1
    wire drain_active;           // DRAIN 중
    wire [ADDR_W-1:0] vec_len;   // 수신된 실제 길이
    wire fifo_not_full;
    
    wire m_valid;
    wire m_last;
    
    wire [15:0] y;
    
    reg [15:0]  data_r;
    reg         valid_r;
    reg         last_r;

    axis_downscale_fsm #(
      .C_MAX(C_MAX), .ADDR_W(ADDR_W), .READ_LAT(1)
    ) u_fsm (
      .clk  (clk),
      .rst_n(rst_n),
    
      .s_valid(s_axis_tvalid),
      .s_last (s_axis_tlast),
      .m_ready(m_axis_tready),
    
      .s_ready   (s_axis_tready), // ★ IDLE/FILL=1, DRAIN=0
      .in_fire   (in_fire),
      .start_first(start_first),
    
      .we(we), .waddr(waddr),
      .re(re), .raddr(raddr),
      .vec_len(vec_len),
    
      .m_valid(m_valid),
      .m_last (m_last)
    );


    // -----------------------------
    // 최대값 트래커: 첫 샘플에서 초기화, 이후 갱신
    // -----------------------------
    wire signed [15:0] xmax_q78;
    max_tracker_q78 u_max (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_fire    (in_fire),      // 샘플 수락 시에만 동작
        .start_first(start_first),  // 벡터 첫 샘플에서 초기화
        .x_in       (q78_in),
        .x_max      (xmax_q78)
    );

    // -----------------------------
    // 버퍼: Q7.8 싱글포트 RAM (읽기 1클럭 지연)
    // -----------------------------
    wire signed [15:0] buf_dout;
    spram_q78 #(
        .DEPTH  (C_MAX),
        .ADDR_W (ADDR_W)
    ) u_buf (
        .clk    (clk),
        .we     (we),
        .waddr  (waddr),
        .din    (q78_in),
        .re     (re),
        .raddr  (raddr),
        .dout   (buf_dout)     // valid after 1 cycle from re
    );

    // -----------------------------
    // (Xi - Xmax) + 포화 → Q7.8
    // -----------------------------    
    q78_sub_sat u_sub (
        .xi   (data_r),
        .xmax (xmax_q78),
        .y    (m_axis_tdata)
    );
    
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n)   begin                          
         data_r <= 16'h0000;
         valid_r <= 1'b0;
         last_r <= 1'b0;
        end else begin                                    // 정상 동작 경로
            data_r <= buf_dout;
            valid_r <= m_valid;
            last_r <= m_last;
      end
    end
    
assign  m_axis_tvalid = valid_r;
assign  m_axis_tlast = last_r;

endmodule
