/*
[MODULE_INFO_START]
Name: Window3x3Case9
Role: Build 3x3 pixel windows across raster positions with border handling.
Summary:
  - Uses a raster address generator and BRAM read queue to collect neighboring pixels.
  - Emits packed 3x3 RGB888 windows through a valid/ready interface.
StateDescription:
  - PLAN: Select required BRAM reads and reuse shifted window pixels.
  - EXEC: Issue queued reads and capture returned pixels.
  - EMIT: Present one completed 3x3 window to the downstream filter.
[MODULE_INFO_END]
*/

// ============================================================================
// 모듈명 : Window3x3Case9
// 기능   : 3x3 윈도우를 9 케이스로 처리
// ============================================================================
module Window3x3Case9 #(
  parameter P_IMG_WIDTH  = 480,
  parameter P_IMG_HEIGHT  = 272,
  parameter P_ROW_WIDTH  = 9,
  parameter P_COL_WIDTH  = 9,
  parameter P_ADDR_WIDTH = 17,
  parameter P_PIX_WIDTH  = 24
)(
  input logic                  iClk,
  input logic                  iRstn,     // System Reset (active-low)

  // BRAM (InputMemory) 인터페이스
  output logic  [P_ADDR_WIDTH-1:0]     oBramAddr,
  output logic                   oBramEn,
  input logic [P_PIX_WIDTH-1:0]      iBramData,

  // CNN 인터페이스 (Producer)
  input logic                  iReady,   // Consumer(Conv3x3) is ready
  output logic                   oValid,   // Data(oData) is valid
  output logic  [P_PIX_WIDTH*9-1:0]    oData,    // 3x3 window pixel data
  
  output logic                   oFrameDone
);

  // ------------------------------
  // 래스터 스캔 주소 생성기
  // ------------------------------
  logic [P_ROW_WIDTH-1:0] Row;
  logic [P_COL_WIDTH-1:0] Col;
  logic RowStart, RowEnd, FirstRow, LastRow;
  logic [P_ADDR_WIDTH-1:0] LinearAddr;
  logic              FrameDonePulse;
  logic               StepEn;

  RasterAddrGen #(
    .P_IMG_WIDTH(P_IMG_WIDTH), .P_IMG_HEIGHT(P_IMG_HEIGHT),
    .P_ROW_WIDTH(P_ROW_WIDTH), .P_COL_WIDTH(P_COL_WIDTH), .P_ADDR_WIDTH(P_ADDR_WIDTH)
  ) uRasterAddrGen (
    .iClk(iClk), .iRstn(iRstn), .iStepEn(StepEn),
    .oRow(Row), .oCol(Col),
    .oRowStart(RowStart), .oRowEnd(RowEnd),
    .oFirstRow(FirstRow), .oLastRow(LastRow),
    .oLinearAddr(LinearAddr),
    .oFrameDonePulse(FrameDonePulse)
  );

  // ------------------------------
  // 3x3 윈도우 레지스터 (Pixel00, Pixel01, ... Pixel22)
  // ------------------------------
  logic [P_PIX_WIDTH-1:0] Pixel00, Pixel01, Pixel02, Pixel10, Pixel11, Pixel12, Pixel20, Pixel21, Pixel22;
  
  // Conv3x3 모듈의 언패킹 순서에 맞게 역순으로 패킹 {Pixel22, Pixel21, ..., Pixel01, Pixel00}
  assign oData = {Pixel22, Pixel21, Pixel20, Pixel12, Pixel11, Pixel10, Pixel02, Pixel01, Pixel00};

  // ------------------------------
  // FSM (Finite State Machine)
  // ------------------------------
  typedef enum logic [1:0] {
    PLAN = 2'd0,
    EXEC = 2'd1,
    EMIT = 2'd2
  } state_e;

  state_e State, State_d;

  logic [1:0] RowCase;
  logic [1:0] ColCase;

  assign RowCase = FirstRow ? 2'd0 : (LastRow ? 2'd2 : 2'd1);
  assign ColCase = RowStart ? 2'd0 : (RowEnd ? 2'd2 : 2'd1);

  // ------------------------------
  // BRAM 읽기 작업 큐 (최대 6개)
  // ------------------------------
  logic [2:0]        OpCnt;
  logic [2:0]        OpIdx;
  logic [3:0]        OpRid  [0:5]; // rid: 1=Pixel00, 2=Pixel01, 3=Pixel02, 4=Pixel10, 5=Pixel11, 6=Pixel12, 7=Pixel20, 8=Pixel21, 9=Pixel22
  logic [P_ADDR_WIDTH-1:0] OpAddr [0:5];

  // ------------------------------
  // BRAM 읽기 2-스테이지 파이프라인
  // ------------------------------
  logic        RdEnPipe [0:1];
  logic [3:0]  RdIdPipe [0:1];

  // ------------------------------
  // FSM 상태 전이 로직 (조합 논리)
  // ------------------------------
  always_comb begin
    State_d = State;
    unique case (State)
      PLAN: 
        State_d = EXEC;
      EXEC: 
        State_d = ((OpIdx >= OpCnt) && !RdEnPipe[1]) ? EMIT : EXEC;
      EMIT: 
        State_d = (iReady ? PLAN : EMIT);
      default: 
        State_d = PLAN;
    endcase
  end

  // ------------------------------
  // FSM 동작 로직 (순차 논리)
  // ------------------------------
  integer idxOp;
  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      State     <= PLAN;
      {Pixel00, Pixel01, Pixel02, Pixel10, Pixel11, Pixel12, Pixel20, Pixel21, Pixel22} <= {9*P_PIX_WIDTH{1'b0}};
      OpCnt       <= 0;
      OpIdx    <= 0;
      for (idxOp=0; idxOp<6; idxOp=idxOp+1) begin
        OpRid [idxOp] <= 4'd0;
        OpAddr[idxOp] <= {P_ADDR_WIDTH{1'b0}};
      end
      oBramEn   <= 1'b0;
      oBramAddr <= {P_ADDR_WIDTH{1'b0}};
      RdEnPipe[0] <= 1'b0; RdEnPipe[1] <= 1'b0;
      RdIdPipe[0] <= 4'd0; RdIdPipe[1] <= 4'd0;
      oValid   <= 1'b0;
      oFrameDone<= 1'b0;
      StepEn   <= 1'b0;
    end else begin

        State     <= State_d;
        oFrameDone<= FrameDonePulse;
        oValid   <= 1'b0; // 기본적으로 0, EMIT에서만 1이 됨
        oBramEn   <= 1'b0; // 기본적으로 0, EXEC에서만 1이 됨
        StepEn   <= 1'b0; // 기본적으로 0, 필요할 때 1로 설정

        case (State)
          PLAN: begin
            OpCnt     <= 0;
            OpIdx  <= 0;
            RdEnPipe[0] <= 1'b0; RdEnPipe[1] <= 1'b0;
            RdIdPipe[0] <= 4'd0; RdIdPipe[1] <= 4'd0;

            if (ColCase != 2'd0) begin
              Pixel00 <= Pixel01; Pixel01 <= Pixel02;
              Pixel10 <= Pixel11; Pixel11 <= Pixel12;
              Pixel20 <= Pixel21; Pixel21 <= Pixel22;
            end

            // rid: 1=Pixel00, 2=Pixel01, 3=Pixel02, 4=Pixel10, 5=Pixel11, 6=Pixel12, 7=Pixel20, 8=Pixel21, 9=Pixel22
            if (RowCase==2'd0 && ColCase==2'd0) begin // TOP-LEFT
              Pixel00 <= 0; Pixel01 <= 0; Pixel02 <= 0; Pixel10 <= 0; Pixel20 <= 0;
              OpRid[0] <= 4'd5; OpAddr[0] <= Row*P_IMG_WIDTH + Col;         // Pixel11
              OpRid[1] <= 4'd6; OpAddr[1] <= Row*P_IMG_WIDTH + (Col+1);     // Pixel12
              OpRid[2] <= 4'd8; OpAddr[2] <= (Row+1)*P_IMG_WIDTH + Col;     // Pixel21
              OpRid[3] <= 4'd9; OpAddr[3] <= (Row+1)*P_IMG_WIDTH + (Col+1); // Pixel22
              OpCnt <= 3'd4;
            end else
            if (RowCase==2'd0 && ColCase==2'd1) begin // TOP-MID
              Pixel02 <= 0;
              OpRid[0] <= 4'd6; OpAddr[0] <= Row*P_IMG_WIDTH + (Col+1);     // Pixel12
              OpRid[1] <= 4'd9; OpAddr[1] <= (Row+1)*P_IMG_WIDTH + (Col+1); // Pixel22
              OpCnt <= 3'd2;
            end else
            if (RowCase==2'd0 && ColCase==2'd2) begin // TOP-RIGHT
              Pixel02 <= 0; Pixel12 <= 0; Pixel22 <= 0;
              OpCnt <= 3'd0;
            end else
            if (RowCase==2'd1 && ColCase==2'd0) begin // MID-LEFT
              Pixel00 <= 0; Pixel10 <= 0; Pixel20 <= 0;
              OpRid[0] <= 4'd2; OpAddr[0] <= (Row-1)*P_IMG_WIDTH + Col;     // Pixel01
              OpRid[1] <= 4'd3; OpAddr[1] <= (Row-1)*P_IMG_WIDTH + (Col+1); // Pixel02
              OpRid[2] <= 4'd5; OpAddr[2] <=  Row   *P_IMG_WIDTH + Col;     // Pixel11
              OpRid[3] <= 4'd6; OpAddr[3] <=  Row   *P_IMG_WIDTH + (Col+1); // Pixel12
              OpRid[4] <= 4'd8; OpAddr[4] <= (Row+1)*P_IMG_WIDTH + Col;     // Pixel21
              OpRid[5] <= 4'd9; OpAddr[5] <= (Row+1)*P_IMG_WIDTH + (Col+1); // Pixel22
              OpCnt <= 3'd6;
            end else
            if (RowCase==2'd1 && ColCase==2'd1) begin // MID-MID
              OpRid[0] <= 4'd3; OpAddr[0] <= (Row-1)*P_IMG_WIDTH + (Col+1); // Pixel02
              OpRid[1] <= 4'd6; OpAddr[1] <=  Row   *P_IMG_WIDTH + (Col+1); // Pixel12
              OpRid[2] <= 4'd9; OpAddr[2] <= (Row+1)*P_IMG_WIDTH + (Col+1); // Pixel22
              OpCnt <= 3'd3;
            end else
            if (RowCase==2'd1 && ColCase==2'd2) begin // MID-RIGHT
              Pixel02 <= 0; Pixel12 <= 0; Pixel22 <= 0;
              OpCnt <= 3'd0;
            end else
            if (RowCase==2'd2 && ColCase==2'd0) begin // BOTTOM-LEFT
              Pixel00 <= 0; Pixel10 <= 0; Pixel20 <= 0; Pixel21 <= 0; Pixel22 <= 0;
              OpRid[0] <= 4'd2; OpAddr[0] <= (Row-1)*P_IMG_WIDTH + Col;     // Pixel01
              OpRid[1] <= 4'd3; OpAddr[1] <= (Row-1)*P_IMG_WIDTH + (Col+1); // Pixel02
              OpRid[2] <= 4'd5; OpAddr[2] <=  Row   *P_IMG_WIDTH + Col;     // Pixel11
              OpRid[3] <= 4'd6; OpAddr[3] <=  Row   *P_IMG_WIDTH + (Col+1); // Pixel12
              OpCnt <= 3'd4;
            end else
            if (RowCase==2'd2 && ColCase==2'd1) begin // BOTTOM-MID
              Pixel22 <= 0;
              OpRid[0] <= 4'd3; OpAddr[0] <= (Row-1)*P_IMG_WIDTH + (Col+1); // Pixel02
              OpRid[1] <= 4'd6; OpAddr[1] <=  Row   *P_IMG_WIDTH + (Col+1); // Pixel12
              OpCnt <= 3'd2;
            end else begin // BOTTOM-RIGHT
              Pixel02 <= 0; Pixel12 <= 0; Pixel22 <= 0;
              OpCnt <= 3'd0;
            end
          end

          EXEC: begin
            oBramEn <= 1'b0;

            // 지난 사이클에 발행한 READ 요청의 데이터를 이번 사이클에 수신
            if (RdEnPipe[1]) begin
              case (RdIdPipe[1])
                4'd1: Pixel00 <= iBramData; 4'd2: Pixel01 <= iBramData; 4'd3: Pixel02 <= iBramData;
                4'd4: Pixel10 <= iBramData; 4'd5: Pixel11 <= iBramData; 4'd6: Pixel12 <= iBramData;
                4'd7: Pixel20 <= iBramData; 4'd8: Pixel21 <= iBramData; 4'd9: Pixel22 <= iBramData;
                default: ;
              endcase
            end

            // 이번 사이클에 새로운 READ 요청 발행
            if (OpIdx < OpCnt) begin
              oBramEn     <= 1'b1;
              oBramAddr   <= OpAddr[OpIdx];
              RdIdPipe[0] <= OpRid[OpIdx];
              RdEnPipe[0] <= 1'b1;
              OpIdx      <= OpIdx + 3'd1;
            end else begin
              RdEnPipe[0] <= 1'b0;
            end

            // 파이프라인 쉬프트
            RdEnPipe[1] <= RdEnPipe[0];
            RdIdPipe[1] <= RdIdPipe[0];
		  
            // 모든 READ 요청이 발행되었고, 마지막 데이터 수신을 기다리는 사이클이면 다음 좌표로 이동 준비
            if ((OpIdx >= OpCnt) && !RdEnPipe[1]) begin
              StepEn <= 1'b1;
            end
          end

          EMIT: begin
            if (iReady) begin
              oValid <= 1'b1;
            end
          end
          default: ;
        endcase
      
    end
  end

endmodule
