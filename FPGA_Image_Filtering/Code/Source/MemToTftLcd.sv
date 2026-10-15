/*
[MODULE_INFO_START]
Name: MemToTftLcd
Role: Generate LCD timing, read addresses, and RGB565 output mapping.
Summary:
  - Maintains LCD horizontal and vertical timing counters.
  - Emits memory read addresses and maps RGB565 data to LCD color pins.
[MODULE_INFO_END]
*/

/********************************************************************************
* Module: MemToTftLcd
*
* Description: 
*   [수정됨] LCD 전체 깜빡임(Flickering) 문제 해결 버전
*   - 내부 클럭 카운터를 iClkEn에 동기화하여 위상 고정
*   - 데이터가 가장 안정적인 시점에 LCD Clock Edge가 발생하도록 조정
*
********************************************************************************/

module MemToTftLcd (
    //==================================================================
    // System Signals
    //==================================================================
    input logic          iClk,          // 100MHz
    input logic          iRstn,        // Reset (Active Low)
    input logic          iClkEn,      // 6.25MHz Enable Pulse

    //==================================================================
    // BRAM Interface (Read Port)
    //==================================================================
    output logic  [16:0]   oMemAddr,
    input logic [15:0]   iMemData,

    //==================================================================
    // LCD Interface
    //==================================================================
    output logic          oLcdClk,       // 6.25MHz (Phase Aligned)
    output logic           oLcdHSync,
    output logic           oLcdVSync,
    output logic          oLcdDe,        // Always 1
    output logic [4:0]    oLcdR,
    output logic [5:0]    oLcdG,
    output logic [4:0]    oLcdB
);

    //==================================================================
    // Parameters (480x272 Timing)
    //==================================================================
    localparam LP_H_SYNC_WIDTH = 40;
    localparam LP_H_BACK_PORCH = 4;
    localparam LP_H_ACTIVE_LEN = 480;
    localparam LP_H_FRONT_PORCH = 2;
    localparam LP_H_TOTAL_LEN  = LP_H_SYNC_WIDTH + LP_H_BACK_PORCH + LP_H_ACTIVE_LEN + LP_H_FRONT_PORCH;

    localparam LP_V_SYNC_WIDTH = 10;
    localparam LP_V_BACK_PORCH = 2;
    localparam LP_V_ACTIVE_LEN = 272;
    localparam LP_V_FRONT_PORCH = 2;
    localparam LP_V_TOTAL_LEN  = LP_V_SYNC_WIDTH + LP_V_BACK_PORCH + LP_V_ACTIVE_LEN + LP_V_FRONT_PORCH;

    localparam LP_H_ACT_START  = LP_H_SYNC_WIDTH + LP_H_BACK_PORCH;
    localparam LP_V_ACT_START  = LP_V_SYNC_WIDTH + LP_V_BACK_PORCH;

    //==================================================================
    // Internal Signals
    //==================================================================
    logic [9:0] HCnt;
    logic [9:0] VCnt;
    
    // [수정 1] 위상 동기화를 위한 카운터
    logic [3:0] PhaseCnt;
    
    logic ActiveRegion;

    //==================================================================
    // Logic 1: LCD Pixel Clock Generation (Phase Locked)
    //==================================================================
    // 깜빡임 해결의 핵심:
    // iClkEn(데이터 업데이트 시점)와 oLcdClk의 위상을 강제로 맞춤.
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            PhaseCnt <= 4'd0;
        end else begin
            // Enable 펄스가 올 때 카운터를 리셋하여 위상을 고정시킴
            if (iClkEn) begin
                PhaseCnt <= 4'd0; 
            end else begin
                PhaseCnt <= PhaseCnt + 1'b1;
            end
        end
    end

    // [수정 2] 클럭 출력 위상 반전 고려
    // 데이터는 PhaseCnt가 0일 때 업데이트됨.
    // PhaseCnt[3]을 사용하면 count 0~7: Low, 8~15: High.
    // Rising Edge가 count 8에서 발생하므로, 데이터 변경 후 충분한 시간(80ns) 뒤에 LCD가 샘플링함.
    // 이는 Setup Time을 최대로 확보하여 깜빡임을 제거함.
    assign oLcdClk = PhaseCnt[3]; 

    //==================================================================
    // Logic 2: Timing Counters & Sync
    //==================================================================
    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            HCnt   <= 10'd0;
            VCnt   <= 10'd0;
            oLcdHSync <= 1'b0;
            oLcdVSync <= 1'b0;
        end else if (iClkEn) begin
            // H Count
            if (HCnt < LP_H_TOTAL_LEN - 1) HCnt <= HCnt + 1'b1;
            else begin
                HCnt <= 10'd0;
                // V Count
                if (VCnt < LP_V_TOTAL_LEN - 1) VCnt <= VCnt + 1'b1;
                else                           VCnt <= 10'd0;
            end

            // Sync Gen (Active Low)
            oLcdHSync <= (HCnt < LP_H_SYNC_WIDTH) ? 1'b0 : 1'b1;
            oLcdVSync <= (VCnt < LP_V_SYNC_WIDTH) ? 1'b0 : 1'b1;
        end
    end

    //==================================================================
    // Logic 3: Address Gen & DE Control
    //==================================================================
    logic HActive;
    logic VActive;
    
    assign HActive = (HCnt >= LP_H_ACT_START) && (HCnt < LP_H_ACT_START + LP_H_ACTIVE_LEN);
    assign VActive = (VCnt >= LP_V_ACT_START) && (VCnt < LP_V_ACT_START + LP_V_ACTIVE_LEN);
    assign ActiveRegion = HActive && VActive;

    // 요청사항 유지: DE는 항상 1
    assign oLcdDe = 1'b1;

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oMemAddr <= 17'd0;
        end else if (iClkEn) begin
            if (VCnt < LP_V_SYNC_WIDTH) begin
                oMemAddr <= 17'd0;
            end 
            else if (ActiveRegion) begin
                oMemAddr <= oMemAddr + 1'b1;
            end
        end
    end

    //==================================================================
    // Logic 4: Data Output Mapping
    //==================================================================
    assign oLcdR = ActiveRegion ? iMemData[4:0] : 5'd0;
    assign oLcdG = ActiveRegion ? iMemData[10: 5] : 6'd0;
    assign oLcdB = ActiveRegion ? iMemData[15:11] : 5'd0;

endmodule
