/*
[MODULE_INFO_START]
Name: CamI2c
Role: Sequence camera reset, power-down, ROM lookup, and SCCB/I2C command execution.
Summary:
  - Initializes camera control pins and walks command ROM addresses.
  - Restarts configuration when the camera select input changes.
StateDescription:
  - INIT: Apply reset and power-down timing before configuration.
  - CMD: Start and wait for one SCCB/I2C command transfer.
  - CHK: Advance ROM address or detect the final command.
  - IDLE: Wait for camera select changes.
[MODULE_INFO_END]
*/

`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 09:37:18
// Design Name: 
// Module Name: CamI2c
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


module CamI2c(
    input   logic iClk,
    input   logic iCamSel,
    output  logic oCamResetn,
    output  logic oCamPwdn,
    inout  wire ioCamScl,
    inout  wire ioCamSda
    );
    
    typedef enum logic [1:0] {
        INIT = 2'b00,
        CMD  = 2'b01,
        CHK  = 2'b10,
        IDLE = 2'b11
    } state_e;
    
    state_e         State = INIT;
    logic     [7:0]   InitCnt = 0;
    
    logic             CamSel_d1 = 0;
    logic             CamSel_d2 = 0;
    logic             CamResetn = 0;
    logic             CamPwdn = 0;
    
    logic     [7:0]   RomAddr = 0;
    logic    [31:0]  RomData;
    logic            RomDone;
    logic             CmdEn = 0;
    logic            CmdDone;
    
    CamI2cRom uCamI2cRom(
        .iClk(iClk),
        .iCamSel(iCamSel),
        .iRomAddr(RomAddr),
        .oRomData(RomData),
        .oRomDone(RomDone)
    );
    
     CamI2cCommand uCamI2cCommand(
         .iClk(iClk),
         .iCamSel(iCamSel),
         .iCmdEn(CmdEn),
         .iCmdData(RomData),
         .oCmdDone(CmdDone),
         .ioI2cScl(ioCamScl),
         .ioI2cSda(ioCamSda)
     );
    
    always_ff @(posedge iClk) begin
        CamSel_d1 <= iCamSel;
        CamSel_d2 <= CamSel_d1;
    end
    
    always_ff @(posedge iClk) begin
        case (State)
            INIT    : begin
                if (InitCnt == 1) begin
                    CamResetn <= 0;
                    if (iCamSel == 1) begin
                        CamPwdn <= 1;
                    end else begin
                        CamPwdn <= 0;
                    end
                    InitCnt <= InitCnt + 1;
                    
                end else if (InitCnt == 50) begin
                    CamResetn <= 1;
                    if (iCamSel == 1) begin
                        CamPwdn <= 0;
                    end else begin
                        CamPwdn <= 1;
                    end
                    InitCnt <= InitCnt + 1;
                    
                end else if (InitCnt == 100) begin
                    InitCnt <= 0;
                    State <= CMD;
                end else begin
                    InitCnt <= InitCnt + 1;
                end
            end
            CMD     : begin
                if (CmdDone == 1) begin
                    CmdEn <= 0;
                    State <= CHK;
                end else begin
                    CmdEn <= 1;
                end
            end
            CHK     : begin
                if (RomDone == 1) begin
                    RomAddr <= 0;
                    State <= IDLE;
                end else begin
                    RomAddr <= RomAddr + 1;
                    State <= CMD;
                end
            end
            
            IDLE    : begin
                if ((CamSel_d1 == 1) && (CamSel_d2 == 0)) begin
                    State <= INIT;
                end else if ((CamSel_d1 == 0) && (CamSel_d2 == 1)) begin
                    State <= INIT;
                end
            end
        endcase
    end
    
    assign oCamResetn = CamResetn;
    assign oCamPwdn = CamPwdn;
    
endmodule
