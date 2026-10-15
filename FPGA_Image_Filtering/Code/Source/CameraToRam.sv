/*
[MODULE_INFO_START]
Name: CameraToRam
Role: Pack camera byte stream into RGB565 RAM write transactions.
Summary:
  - Samples camera sync and data signals on the camera pixel clock.
  - Tracks active frame bounds and emits RAM write enable, address, and data.
[MODULE_INFO_END]
*/

`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/19 09:36:55
// Design Name: 
// Module Name: CameraToRam
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CameraToRam(
    input   logic iClk,
    input   logic iCamSel,
    input   logic iCamVsync,
    input   logic iCamHsync,
    input   logic [7:0]   iCamData,
    output          logic oRamWrEn,
    output  logic [16:0]  oRamWrAddr,
    output  logic [15:0]  oRamWrData
    );
    
    localparam LP_V_COUNT_MAX_REAL = 272;
    localparam LP_H_COUNT_MAX_REAL = 480;
    
//    localparam LP_V_COUNT_MAX_SIM = 272;
//    localparam LP_H_COUNT_MAX_SIM = 480;
    
    logic VCountMax;
    logic HCountMax;
    
    logic     CamVsync;
    logic     CamHsync;
    logic     [7:0]   CamData;
    
    logic     CamVsync_d1;
    logic     CamHsync_d1;
    logic     [7:0]   CamData_d1;
    
    logic     BytePhase;
    
    logic     [15:0]  VCnt;
    logic     [15:0]  HCnt;
    logic     [16:0]  AddrCnt;
    
    logic             PixelEn;
    logic             RamWrEn;
    logic     [16:0]  RamWrAddr;
    logic     [15:0]  RamWrData;
    
    assign VCountMax = LP_V_COUNT_MAX_REAL;//(simulation==0) ? LP_V_COUNT_MAX_REAL : LP_V_COUNT_MAX_SIM;
    assign HCountMax = LP_H_COUNT_MAX_REAL;//(simulation==0) ? LP_H_COUNT_MAX_REAL : LP_H_COUNT_MAX_SIM;
    
    always_ff @(posedge iClk) begin
        CamVsync <= iCamVsync;
        CamHsync <= iCamHsync;
        CamData <= iCamData;
        
        CamVsync_d1 <= CamVsync;
        CamHsync_d1 <= CamHsync;
        CamData_d1 <= CamData;
    end
    
    always_ff @(posedge iClk) begin
        if (CamVsync_d1 == 0) begin
            if (CamHsync_d1 == 1) begin
                BytePhase <= ~BytePhase;
            end else begin
                BytePhase <= BytePhase;
            end
        end else begin
            BytePhase <= 0;
        end
    end

    always_ff @(posedge iClk) begin
        if (CamVsync == 0) begin
            if ((CamHsync == 0) && (CamHsync_d1 == 1)) begin
                VCnt <= VCnt + 1;
            end else begin
                VCnt <= VCnt;
            end
        end else begin
            VCnt <= 0;
        end
    end
    
    always_ff @(posedge iClk) begin
        if (CamVsync == 0) begin
            if (CamHsync == 1) begin
                if (BytePhase == 1) begin
                    HCnt <= HCnt + 1;
                end else begin
                    HCnt <= HCnt;
                end
            end else begin
                HCnt <= 0;
            end
        end else begin
            HCnt <= 0;
        end
    end
    
    always_ff @(posedge iClk) begin
        if (CamVsync == 0) begin
            if (RamWrEn == 1) begin
                AddrCnt <= AddrCnt + 1;
            end else begin
                
            end
        end else begin
            AddrCnt <= 0;
        end
    end

    always_ff @(posedge iClk) begin
        if (CamVsync == 0) begin
            if (CamHsync == 1) begin
                if ((VCnt < LP_V_COUNT_MAX_REAL) && (HCnt < LP_H_COUNT_MAX_REAL)) begin
                    PixelEn <= 1;
                end else begin
                    PixelEn <= 0;
                end
            end else begin
                PixelEn <= PixelEn;
            end
        end else begin
            PixelEn <= 0;
        end
    end

    always_ff @(posedge iClk) begin
        if (PixelEn == 1) begin
            if (BytePhase == 0) begin
                RamWrEn <= 0;
                RamWrAddr <= 0;
                RamWrData[15:8] <= CamData_d1;
            end else if (BytePhase == 1) begin
                RamWrEn <= 1;
                RamWrAddr <= AddrCnt;
                RamWrData[7:0] <= CamData_d1;
            end
        end else begin
            RamWrEn <= 0;
            RamWrAddr <= 0;
            RamWrData <= 0;
        end
    end
    assign oRamWrEn = RamWrEn;
    assign oRamWrAddr = RamWrAddr;
    assign oRamWrData = RamWrData;

endmodule
