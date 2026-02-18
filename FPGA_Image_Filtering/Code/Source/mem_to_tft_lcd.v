/********************************************************************************
* Module: Mem_To_TFT_LCD
*
* Description: 
*   [수정됨] LCD 전체 깜빡임(Flickering) 문제 해결 버전
*   - 내부 클럭 카운터를 i_wEnClk에 동기화하여 위상 고정
*   - 데이터가 가장 안정적인 시점에 LCD Clock Edge가 발생하도록 조정
*
********************************************************************************/

module Mem_To_TFT_LCD (
    //==================================================================
    // System Signals
    //==================================================================
    input  wire          iClk,          // 100MHz
    input  wire          iRst_n,        // Reset (Active Low)
    input  wire          i_wEnClk,      // 6.25MHz Enable Pulse

    //==================================================================
    // BRAM Interface (Read Port)
    //==================================================================
    output reg  [16:0]   oMemAddr,
    input  wire [15:0]   iMemData,

    //==================================================================
    // LCD Interface
    //==================================================================
    output wire          oLcdClk,       // 6.25MHz (Phase Aligned)
    output reg           oLcdHSync,
    output reg           oLcdVSync,
    output wire          oLcdDe,        // Always 1
    output wire [4:0]    oLcdR,
    output wire [5:0]    oLcdG,
    output wire [4:0]    oLcdB
);

    //==================================================================
    // Parameters (480x272 Timing)
    //==================================================================
    localparam H_SYNC_WIDTH = 40;
    localparam H_BACK_PORCH = 4;
    localparam H_ACTIVE_LEN = 480;
    localparam H_FRONT_PORCH = 2;
    localparam H_TOTAL_LEN  = H_SYNC_WIDTH + H_BACK_PORCH + H_ACTIVE_LEN + H_FRONT_PORCH;

    localparam V_SYNC_WIDTH = 10;
    localparam V_BACK_PORCH = 2;
    localparam V_ACTIVE_LEN = 272;
    localparam V_FRONT_PORCH = 2;
    localparam V_TOTAL_LEN  = V_SYNC_WIDTH + V_BACK_PORCH + V_ACTIVE_LEN + V_FRONT_PORCH;

    localparam H_ACT_START  = H_SYNC_WIDTH + H_BACK_PORCH;
    localparam V_ACT_START  = V_SYNC_WIDTH + V_BACK_PORCH;

    //==================================================================
    // Internal Signals
    //==================================================================
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // [수정 1] 위상 동기화를 위한 카운터
    reg [3:0] r_phase_cnt;
    
    wire w_active_region;

    //==================================================================
    // Logic 1: LCD Pixel Clock Generation (Phase Locked)
    //==================================================================
    // 깜빡임 해결의 핵심:
    // i_wEnClk(데이터 업데이트 시점)와 oLcdClk의 위상을 강제로 맞춤.
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            r_phase_cnt <= 4'd0;
        end else begin
            // Enable 펄스가 올 때 카운터를 리셋하여 위상을 고정시킴
            if (i_wEnClk) begin
                r_phase_cnt <= 4'd0; 
            end else begin
                r_phase_cnt <= r_phase_cnt + 1'b1;
            end
        end
    end

    // [수정 2] 클럭 출력 위상 반전 고려
    // 데이터는 r_phase_cnt가 0일 때 업데이트됨.
    // r_phase_cnt[3]을 사용하면 count 0~7: Low, 8~15: High.
    // Rising Edge가 count 8에서 발생하므로, 데이터 변경 후 충분한 시간(80ns) 뒤에 LCD가 샘플링함.
    // 이는 Setup Time을 최대로 확보하여 깜빡임을 제거함.
    assign oLcdClk = r_phase_cnt[3]; 

    //==================================================================
    // Logic 2: Timing Counters & Sync
    //==================================================================
    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            h_count   <= 10'd0;
            v_count   <= 10'd0;
            oLcdHSync <= 1'b0;
            oLcdVSync <= 1'b0;
        end else if (i_wEnClk) begin
            // H Count
            if (h_count < H_TOTAL_LEN - 1) h_count <= h_count + 1'b1;
            else begin
                h_count <= 10'd0;
                // V Count
                if (v_count < V_TOTAL_LEN - 1) v_count <= v_count + 1'b1;
                else                           v_count <= 10'd0;
            end

            // Sync Gen (Active Low)
            oLcdHSync <= (h_count < H_SYNC_WIDTH) ? 1'b0 : 1'b1;
            oLcdVSync <= (v_count < V_SYNC_WIDTH) ? 1'b0 : 1'b1;
        end
    end

    //==================================================================
    // Logic 3: Address Gen & DE Control
    //==================================================================
    wire h_active = (h_count >= H_ACT_START) && (h_count < H_ACT_START + H_ACTIVE_LEN);
    wire v_active = (v_count >= V_ACT_START) && (v_count < V_ACT_START + V_ACTIVE_LEN);
    
    assign w_active_region = h_active && v_active;

    // 요청사항 유지: DE는 항상 1
    assign oLcdDe = 1'b1;

    always @(posedge iClk or negedge iRst_n) begin
        if (!iRst_n) begin
            oMemAddr <= 17'd0;
        end else if (i_wEnClk) begin
            if (v_count < V_SYNC_WIDTH) begin
                oMemAddr <= 17'd0;
            end 
            else if (w_active_region) begin
                oMemAddr <= oMemAddr + 1'b1;
            end
        end
    end

    //==================================================================
    // Logic 4: Data Output Mapping
    //==================================================================
    assign oLcdR = w_active_region ? iMemData[4:0] : 5'd0;
    assign oLcdG = w_active_region ? iMemData[10: 5] : 6'd0;
    assign oLcdB = w_active_region ? iMemData[15:11] : 5'd0;

endmodule