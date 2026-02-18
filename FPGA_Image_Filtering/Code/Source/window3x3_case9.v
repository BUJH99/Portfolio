// ============================================================================
// 모듈명 : window3x3_case9
// 기능   : 3x3 윈도우를 9 케이스로 처리
// ============================================================================
module window3x3_case9 #(
  parameter IMG_W  = 480,
  parameter IMG_H  = 272,
  parameter ROW_W  = 9,
  parameter COL_W  = 9,
  parameter ADDR_W = 17,
  parameter PIX_W  = 24
)(
  input  wire                  iClk,
  input  wire                  iRst_n,     // System Reset (active-low)

  // BRAM (InputMemory) 인터페이스
  output reg  [ADDR_W-1:0]     bram_addr,
  output reg                   bram_en,
  input  wire [PIX_W-1:0]      bram_dout,

  // CNN 인터페이스 (Producer)
  input  wire                  o_ready,   // Consumer(Conv3x3) is ready
  output reg                   o_valid,   // Data(o_data) is valid
  output wire  [PIX_W*9-1:0]    o_data,    // 3x3 window pixel data
  
  output reg                   frame_done
);

  // ------------------------------
  // 래스터 스캔 주소 생성기
  // ------------------------------
  wire [ROW_W-1:0] row;
  wire [COL_W-1:0] col;
  wire at_row_start, at_row_end, first_row, last_row;
  wire [ADDR_W-1:0] linear_addr;
  wire              frame_done_pulse;
  reg               step_en;

  raster_addr_gen #(
    .IMG_W(IMG_W), .IMG_H(IMG_H),
    .ROW_W(ROW_W), .COL_W(COL_W), .ADDR_W(ADDR_W)
  ) u_idx (
    .iClk(iClk), .iRst_n(iRst_n), .step_en(step_en),
    .row(row), .col(col),
    .at_row_start(at_row_start), .at_row_end(at_row_end),
    .first_row(first_row), .last_row(last_row),
    .linear_addr(linear_addr),
    .frame_done_pulse(frame_done_pulse)
  );

  // ------------------------------
  // 3x3 윈도우 레지스터 (p00, p01, ... p22)
  // ------------------------------
  reg [PIX_W-1:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
  
  // Conv3x3 모듈의 언패킹 순서에 맞게 역순으로 패킹 {p22, p21, ..., p01, p00}
  assign o_data = {p22, p21, p20, p12, p11, p10, p02, p01, p00};

  // ------------------------------
  // FSM (Finite State Machine)
  // ------------------------------
  localparam S_PLAN = 2'd0;
  localparam S_EXEC = 2'd1;
  localparam S_EMIT = 2'd2;

  reg [1:0] state, state_n;

  wire [1:0] row_case = first_row    ? 2'd0 : (last_row ? 2'd2 : 2'd1);
  wire [1:0] col_case = at_row_start ? 2'd0 : (at_row_end ? 2'd2 : 2'd1);

  // ------------------------------
  // BRAM 읽기 작업 큐 (최대 6개)
  // ------------------------------
  reg [2:0]        opN;
  reg [2:0]        op_idx;
  reg [3:0]        op_rid  [0:5]; // rid: 1=p00, 2=p01, 3=p02, 4=p10, 5=p11, 6=p12, 7=p20, 8=p21, 9=p22
  reg [ADDR_W-1:0] op_addr [0:5];

  // ------------------------------
  // BRAM 읽기 2-스테이지 파이프라인
  // ------------------------------
  reg        ren_pipe [0:1];
  reg [3:0]  rid_pipe [0:1];

  // ------------------------------
  // FSM 상태 전이 로직 (조합 논리)
  // ------------------------------
  always @(*) begin
    state_n = state;
    case (state)
      S_PLAN: 
        state_n = S_EXEC;
      S_EXEC: 
        state_n = ((op_idx >= opN) && !ren_pipe[1]) ? S_EMIT : S_EXEC;
      S_EMIT: 
        state_n = (o_ready ? S_PLAN : S_EMIT);
      default: 
        state_n = S_PLAN;
    endcase
  end

  // ------------------------------
  // FSM 동작 로직 (순차 논리)
  // ------------------------------
  integer i;
  always @(posedge iClk or negedge iRst_n) begin
    if (!iRst_n) begin
      state     <= S_PLAN;
      {p00, p01, p02, p10, p11, p12, p20, p21, p22} <= {9*PIX_W{1'b0}};
      opN       <= 0;
      op_idx    <= 0;
      for (i=0; i<6; i=i+1) begin
        op_rid [i] <= 4'd0;
        op_addr[i] <= {ADDR_W{1'b0}};
      end
      bram_en   <= 1'b0;
      bram_addr <= {ADDR_W{1'b0}};
      ren_pipe[0] <= 1'b0; ren_pipe[1] <= 1'b0;
      rid_pipe[0] <= 4'd0; rid_pipe[1] <= 4'd0;
      o_valid   <= 1'b0;
      frame_done<= 1'b0;
      step_en   <= 1'b0;
    end else begin

        state     <= state_n;
        frame_done<= frame_done_pulse;
        o_valid   <= 1'b0; // 기본적으로 0, S_EMIT에서만 1이 됨
        bram_en   <= 1'b0; // 기본적으로 0, S_EXEC에서만 1이 됨
        step_en   <= 1'b0; // 기본적으로 0, 필요할 때 1로 설정

        case (state)
          S_PLAN: begin
            opN     <= 0;
            op_idx  <= 0;
            ren_pipe[0] <= 1'b0; ren_pipe[1] <= 1'b0;
            rid_pipe[0] <= 4'd0; rid_pipe[1] <= 4'd0;

            if (col_case != 2'd0) begin
              p00 <= p01; p01 <= p02;
              p10 <= p11; p11 <= p12;
              p20 <= p21; p21 <= p22;
            end

            // rid: 1=p00, 2=p01, 3=p02, 4=p10, 5=p11, 6=p12, 7=p20, 8=p21, 9=p22
            if (row_case==2'd0 && col_case==2'd0) begin // TOP-LEFT
              p00 <= 0; p01 <= 0; p02 <= 0; p10 <= 0; p20 <= 0;
              op_rid[0] <= 4'd5; op_addr[0] <= row*IMG_W + col;         // p11
              op_rid[1] <= 4'd6; op_addr[1] <= row*IMG_W + (col+1);     // p12
              op_rid[2] <= 4'd8; op_addr[2] <= (row+1)*IMG_W + col;     // p21
              op_rid[3] <= 4'd9; op_addr[3] <= (row+1)*IMG_W + (col+1); // p22
              opN <= 3'd4;
            end else
            if (row_case==2'd0 && col_case==2'd1) begin // TOP-MID
              p02 <= 0;
              op_rid[0] <= 4'd6; op_addr[0] <= row*IMG_W + (col+1);     // p12
              op_rid[1] <= 4'd9; op_addr[1] <= (row+1)*IMG_W + (col+1); // p22
              opN <= 3'd2;
            end else
            if (row_case==2'd0 && col_case==2'd2) begin // TOP-RIGHT
              p02 <= 0; p12 <= 0; p22 <= 0;
              opN <= 3'd0;
            end else
            if (row_case==2'd1 && col_case==2'd0) begin // MID-LEFT
              p00 <= 0; p10 <= 0; p20 <= 0;
              op_rid[0] <= 4'd2; op_addr[0] <= (row-1)*IMG_W + col;     // p01
              op_rid[1] <= 4'd3; op_addr[1] <= (row-1)*IMG_W + (col+1); // p02
              op_rid[2] <= 4'd5; op_addr[2] <=  row   *IMG_W + col;     // p11
              op_rid[3] <= 4'd6; op_addr[3] <=  row   *IMG_W + (col+1); // p12
              op_rid[4] <= 4'd8; op_addr[4] <= (row+1)*IMG_W + col;     // p21
              op_rid[5] <= 4'd9; op_addr[5] <= (row+1)*IMG_W + (col+1); // p22
              opN <= 3'd6;
            end else
            if (row_case==2'd1 && col_case==2'd1) begin // MID-MID
              op_rid[0] <= 4'd3; op_addr[0] <= (row-1)*IMG_W + (col+1); // p02
              op_rid[1] <= 4'd6; op_addr[1] <=  row   *IMG_W + (col+1); // p12
              op_rid[2] <= 4'd9; op_addr[2] <= (row+1)*IMG_W + (col+1); // p22
              opN <= 3'd3;
            end else
            if (row_case==2'd1 && col_case==2'd2) begin // MID-RIGHT
              p02 <= 0; p12 <= 0; p22 <= 0;
              opN <= 3'd0;
            end else
            if (row_case==2'd2 && col_case==2'd0) begin // BOTTOM-LEFT
              p00 <= 0; p10 <= 0; p20 <= 0; p21 <= 0; p22 <= 0;
              op_rid[0] <= 4'd2; op_addr[0] <= (row-1)*IMG_W + col;     // p01
              op_rid[1] <= 4'd3; op_addr[1] <= (row-1)*IMG_W + (col+1); // p02
              op_rid[2] <= 4'd5; op_addr[2] <=  row   *IMG_W + col;     // p11
              op_rid[3] <= 4'd6; op_addr[3] <=  row   *IMG_W + (col+1); // p12
              opN <= 3'd4;
            end else
            if (row_case==2'd2 && col_case==2'd1) begin // BOTTOM-MID
              p22 <= 0;
              op_rid[0] <= 4'd3; op_addr[0] <= (row-1)*IMG_W + (col+1); // p02
              op_rid[1] <= 4'd6; op_addr[1] <=  row   *IMG_W + (col+1); // p12
              opN <= 3'd2;
            end else begin // BOTTOM-RIGHT
              p02 <= 0; p12 <= 0; p22 <= 0;
              opN <= 3'd0;
            end
          end

          S_EXEC: begin
            bram_en <= 1'b0;

            // 지난 사이클에 발행한 READ 요청의 데이터를 이번 사이클에 수신
            if (ren_pipe[1]) begin
              case (rid_pipe[1])
                4'd1: p00 <= bram_dout; 4'd2: p01 <= bram_dout; 4'd3: p02 <= bram_dout;
                4'd4: p10 <= bram_dout; 4'd5: p11 <= bram_dout; 4'd6: p12 <= bram_dout;
                4'd7: p20 <= bram_dout; 4'd8: p21 <= bram_dout; 4'd9: p22 <= bram_dout;
                default: ;
              endcase
            end

            // 이번 사이클에 새로운 READ 요청 발행
            if (op_idx < opN) begin
              bram_en     <= 1'b1;
              bram_addr   <= op_addr[op_idx];
              rid_pipe[0] <= op_rid[op_idx];
              ren_pipe[0] <= 1'b1;
              op_idx      <= op_idx + 3'd1;
            end else begin
              ren_pipe[0] <= 1'b0;
            end

            // 파이프라인 쉬프트
            ren_pipe[1] <= ren_pipe[0];
            rid_pipe[1] <= rid_pipe[0];
		  
            // 모든 READ 요청이 발행되었고, 마지막 데이터 수신을 기다리는 사이클이면 다음 좌표로 이동 준비
            if ((op_idx >= opN) && !ren_pipe[1]) begin
              step_en <= 1'b1;
            end
          end

          S_EMIT: begin
            if (o_ready) begin
              o_valid <= 1'b1;
            end
          end
          default: ;
        endcase
      
    end
  end

endmodule