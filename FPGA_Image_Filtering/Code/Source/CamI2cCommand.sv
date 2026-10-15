/*
[MODULE_INFO_START]
Name: CamI2cCommand
Role: Serialize camera configuration command words onto SCCB/I2C pins.
Summary:
  - Captures command words and drives SCL/SDA timing sequences.
  - Selects command length for OV5640 or CIS_2M transfers.
StateDescription:
  - IDLE: Wait for a command enable and hold the bus idle.
  - OV5640: Shift an OV5640 command transaction.
  - CIS_2M: Shift a CIS_2M command transaction.
[MODULE_INFO_END]
*/

`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 10:10:10
// Design Name: 
// Module Name: CamI2cCommand
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


module CamI2cCommand(
    input logic iClk,
    input   logic iCamSel,
    input   logic iCmdEn,
    input   logic [31:0]  iCmdData,
    output  logic oCmdDone,
    inout  wire ioI2cScl,
    inout  wire ioI2cSda 
    );
    
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        OV5640 = 2'b01,
        CIS_2M = 2'b10
    } state_e;
    
    state_e         State = IDLE;
    
    logic     [31:0]  CmdData;
    logic             I2cScl;
    logic             I2cSda;
    logic     [7:0]   Cnt;
    logic             CmdDone;
    
    always_ff @(posedge iClk) begin
        case (State)
            IDLE: begin
                I2cScl <= 1;
                I2cSda <= 1;
                
                if (iCmdEn == 1) begin
                    CmdData <= iCmdData;
                    if (iCamSel == 1) begin
                        State <= OV5640;
                    end else begin
                        State <= CIS_2M;
                    end
                end
            end
            
            OV5640: begin
                if (Cnt == 113) begin
                    Cnt <= 0;
                    State <= IDLE;
                end else begin
                    Cnt <= Cnt + 1;
                end
                
                case (Cnt)
                    8'h00: begin
                        I2cScl <= 1;
                        I2cSda <= 1;
                    end
                    8'h01: begin
                        I2cScl <= 1;
                        I2cSda <= 0;
                    end
                    8'h02: begin
                        I2cScl <= 0;
                        I2cSda <= 0;
                    end
                    8'h03: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[31];
                    end
                    8'h04: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[31];
                    end
                    8'h05: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[31];
                    end
                    8'h06: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[30];
                    end
                    8'h07: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[30];
                    end
                    8'h08: begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[30];
                    end
                    8'h09: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[29];
                    end
                    8'h0A: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[29];
                    end
                    8'h0B: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[29];
                    end
                    8'h0C: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[28];
                    end
                    8'h0D: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[28];
                    end
                    8'h0E: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[28];
                    end
                    8'h0F: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[27];
                    end
                    8'h10: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[27];
                    end
                    8'h11: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[27];
                    end
                    8'h12: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[26];
                    end
                    8'h13: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[26];
                    end
                    8'h14: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[26];
                    end
                    8'h15: begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[25];
                    end
                    8'h16: begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[25];
                    end
                    8'h17  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[25];
                    end
                    8'h18  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[24];
                    end
                    8'h19  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[24];
                    end
                    8'h1A  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[24];
                    end
                    8'h1B  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h1C  : begin
                        I2cScl <= 1;
                        I2cSda <= 1'bz;
                    end
                    8'h1D  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h1E  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[23];
                    end
                    8'h1F  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[23];
                    end
                    8'h20  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[23];
                    end
                    8'h21  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[22];
                    end
                    8'h22  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[22];
                    end
                    8'h23  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[22];
                    end
                    8'h24  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[21];
                    end
                    8'h25  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[21];
                    end
                    8'h26  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[21];
                    end
                    8'h27  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[20];
                    end
                    8'h28  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[20];
                    end
                    8'h29  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[20];
                    end
                    8'h2A  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[19];
                    end
                    8'h2B  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[19];
                    end
                    8'h2C  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[19];
                    end
                    8'h2D  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[18];
                    end
                    8'h2E  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[18];
                    end
                    8'h2F  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[18];
                    end
                    8'h30  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[17];
                    end
                    8'h31  : begin
                    I2cScl <= 1;
                    I2cSda <= CmdData[17];
                    end
                    8'h32  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[17];
                    end
                    8'h33  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[16];
                    end
                    8'h34  : begin
                    I2cScl <= 1;
                    I2cSda <= CmdData[16];
                    end
                    8'h35  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[16];
                    end
                    8'h36  : begin
                    I2cScl <= 0;
                    I2cSda <= 1'bZ;
                    end
                    8'h37  : begin
                    I2cScl <= 1;
                    I2cSda <= 1'bZ;
                    end
                    8'h38  : begin
                    I2cScl <= 0;
                    I2cSda <= 1'bZ;
                    end
                    8'h39  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[15];
                    end
                    8'h3A  : begin
                    I2cScl <= 1;
                    I2cSda <= CmdData[15];
                    end
                    8'h3B  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[15];
                    end
                    8'h3C  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[14];
                    end
                    8'h3D  : begin
                    I2cScl <= 1;
                    I2cSda <= CmdData[14];
                    end
                    8'h3E  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[14];
                    end
                    8'h3F  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[13];
                    end
                    8'h40  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[13];
                    end
                    8'h41  : begin
                    I2cScl <= 0;
                    I2cSda <= CmdData[13];
                    end
                    8'h42  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[12];

                    end
                    8'h43  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[12];
                    end
                    8'h44  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[12];

                    end
                    8'h45  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[11];

                    end
                    8'h46  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[11];

                    end
                    8'h47  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[11];

                    end
                    8'h48  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[10];

                    end
                    8'h49  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[10];

                    end
                    8'h4A  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[10];

                    end
                    8'h4B  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[9];

                    end
                    8'h4C  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[9];

                    end
                    8'h4D  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[9];

                    end
                    8'h4E  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[8];

                    end
                    8'h4F  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[8];

                    end
                    8'h50  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[8];

                    end
                    8'h51  : begin
                                        I2cScl <= 0;
                                        I2cSda <= 1'bZ;

                    end
                    8'h52  : begin
                                        I2cScl <= 1;
                                        I2cSda <= 1'bZ;

                    end
                    8'h53  : begin
                                        I2cScl <= 0;
                                        I2cSda <= 1'bZ;

                    end
                    8'h54  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[7];

                    end
                    8'h55  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[7];

                    end
                    8'h56  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[7];

                    end
                    8'h57  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[6];

                    end
                    8'h58  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[6];

                    end
                    8'h59  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[6];

                    end
                    8'h5A  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[5];

                    end
                    8'h5B  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[5];

                    end
                    8'h5C  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[5];

                    end
                    8'h5D  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[4];

                    end
                    8'h5E  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[4];

                    end
                    8'h5F  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[4];

                    end
                    8'h60  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[3];

                    end
                    8'h61  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[3];

                    end
                    8'h62  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[3];

                    end
                    8'h63  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[2];

                    end
                    8'h64  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[2];

                    end
                    8'h65  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[2];

                    end
                    8'h66  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[1];

                    end
                    8'h67  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[1];

                    end
                    8'h68  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[1];

                    end
                    8'h69  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[0];

                    end
                    8'h6A  : begin
                                        I2cScl <= 1;
                                        I2cSda <= CmdData[0];

                    end
                    8'h6B  : begin
                                        I2cScl <= 0;
                                        I2cSda <= CmdData[0];

                    end
                    8'h6C  : begin
                                        I2cScl <= 0;
                                        I2cSda <= 1'bZ;

                    end
                    8'h6D  : begin
                                        I2cScl <= 1;
                                        I2cSda <= 1'bZ;

                    end
                    8'h6E  : begin
                                        I2cScl <= 0;
                                        I2cSda <= 1'bZ;

                    end
                    8'h6F  : begin
                                        I2cScl <= 0;
                                        I2cSda <= 0;

                    end
                    8'h70  : begin
                                        I2cScl <= 1;
                                        I2cSda <= 0;
                                        CmdDone <= 1;

                    end
                    8'h71  : begin
                                        I2cScl <= 1;
                                        I2cSda <= 1;
                                        CmdDone <= 0;
                    end
                    default: begin
                                        I2cScl <= 1;
                                        I2cSda <= 1;
                    end
                endcase
            end
        
            CIS_2M: begin
                if (Cnt == 86) begin
                    Cnt <= 0;
                    State <= IDLE;
                end else begin
                    Cnt <= Cnt + 1;
                end

                case (Cnt)
                    8'h00  : begin
                        I2cScl <= 1;
                        I2cSda <= 1;
                    end
                    8'h01  : begin
                        I2cScl <= 1;
                        I2cSda <= 0;
                    end
                    8'h02  : begin
                        I2cScl <= 0;
                        I2cSda <= 0;
                    end
                    8'h03  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[23];
                    end
                    8'h04  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[23];
                    end
                    8'h05  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[23];
                    end
                    8'h06  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[22];
                    end
                    8'h07  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[22];
                    end
                    8'h08  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[22];
                    end
                    8'h09  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[21];
                    end
                    8'h0A  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[21];
                    end
                    8'h0B  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[21];
                    end
                    8'h0C  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[20];
                    end
                    8'h0D  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[20];
                    end
                    8'h0E  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[20];
                    end
                    8'h0F  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[19];
                    end
                    8'h10  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[19];

                    end
                    8'h11  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[19];
                    end
                    8'h12  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[18];
                    end
                    8'h13  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[18];
                    end
                    8'h14  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[18];
                    end
                    8'h15  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[17];
                    end
                    8'h16  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[17];
                    end
                    8'h17  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[17];
                    end
                    8'h18  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[16];
                    end
                    8'h19  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[16];
                    end
                    8'h1A  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[16];
                    end
                    8'h1B  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h1C  : begin
                        I2cScl <= 1;
                        I2cSda <= 1'bZ;
                    end
                    8'h1D  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h1E  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[15];
                    end
                    8'h1F  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[15];
                    end
                    8'h20  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[15];
                    end
                    8'h21  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[14];
                    end
                    8'h22  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[14];
                    end
                    8'h23  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[14];
                    end
                    8'h24  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[13];
                    end
                    8'h25  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[13];
                    end
                    8'h26  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[13];
                    end
                    8'h27  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[12];
                    end
                    8'h28  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[12];
                    end
                    8'h29  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[12];
                    end
                    8'h2A  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[11];
                    end
                    8'h2B  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[11];
                    end
                    8'h2C  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[11];
                    end
                    8'h2D  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[10];
                    end
                    8'h2E  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[10];
                    end
                    8'h2F  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[10];
                    end
                    8'h30  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[9];
                    end
                    8'h31  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[9];
                    end
                    8'h32  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[9];
                    end
                    8'h33  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[8];
                    end
                    8'h34  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[8];
                    end
                    8'h35  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[8];
                    end
                    8'h36  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h37  : begin
                        I2cScl <= 1;
                        I2cSda <= 1'bZ;
                    end
                    8'h38  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h39  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[7];
                    end
                    8'h3A  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[7];
                    end
                    8'h3B  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[7];
                    end
                    8'h3C  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[6];
                    end
                    8'h3D  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[6];
                    end
                    8'h3E  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[6];
                    end
                    8'h3F  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[5];
                    end
                    8'h40  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[5];
                    end
                    8'h41  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[5];
                    end
                    8'h42  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[4];
                    end
                    8'h43  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[4];
                    end
                    8'h44  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[4];
                    end
                    8'h45  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[3];
                    end
                    8'h46  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[3];
                    end
                    8'h47  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[3];
                    end
                    8'h48  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[2];
                    end
                    8'h49  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[2];
                    end
                    8'h4A  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[2];
                    end
                    8'h4B  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[1];
                    end
                    8'h4C  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[1];
                    end
                    8'h4D  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[1];
                    end
                    8'h4E  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[0];
                    end
                    8'h4F  : begin
                        I2cScl <= 1;
                        I2cSda <= CmdData[0];
                    end
                    8'h50  : begin
                        I2cScl <= 0;
                        I2cSda <= CmdData[0];
                    end
                    8'h51  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h52  : begin
                        I2cScl <= 1;
                        I2cSda <= 1'bZ;
                    end
                    8'h53  : begin
                        I2cScl <= 0;
                        I2cSda <= 1'bZ;
                    end
                    8'h54  : begin
                        I2cScl <= 0;
                        I2cSda <= 0;
                    end
                    8'h55  : begin
                        I2cScl <= 1;
                        I2cSda <= 0;
                        CmdDone <= 1;
                    end
                    8'h56  : begin
                        I2cScl <= 1;
                        I2cSda <= 1;
                        CmdDone <= 0;
                    end
                    default: begin
                        I2cScl <= 1;
                        I2cSda <= 1;
                    end
                endcase
            end
            // CIS_2M case end
        endcase
        //sig State case end
    end
    
    assign oCmdDone = CmdDone;
    assign ioI2cScl = I2cScl;
    assign ioI2cSda = I2cSda;
    
endmodule
