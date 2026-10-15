/*
[MODULE_INFO_START]
Name: CamI2cRom
Role: Provide camera initialization command words for the SCCB/I2C command sequencer.
Summary:
  - Selects OV5640 or CIS_2M command tables from the camera select input.
  - Raises a done flag on the final ROM entry.
[MODULE_INFO_END]
*/

`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 10:10:10
// Design Name: 
// Module Name: CamI2cRom
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


module CamI2cRom(
    input   logic iClk,
    input   logic iCamSel,
    input   logic [7:0]   iRomAddr,
    output logic [31:0]  oRomData,
    output  logic oRomDone
    );
    
    logic     RomDone;
    
    always_ff @(posedge iClk) begin
        if (iCamSel == 1'b1) begin
            case (iRomAddr)
                8'h00: begin
                    oRomData <= 32'h78310311;
                    RomDone <= 0;
                end
                8'h01: oRomData <= 32'h7830_0882;
                8'h02: oRomData <= 32'h7830_0842;
                8'h03: oRomData <= 32'h7831_0303;
                8'h04: oRomData <= 32'h7830_17FF;
                8'h05: oRomData <= 32'h7830_18FF;
                8'h06: oRomData <= 32'h7830_341A;
                8'h07: oRomData <= 32'h7830_3713;
                8'h08: oRomData <= 32'h7831_0801;
                8'h09: oRomData <= 32'h7836_3036;
                8'h0A: oRomData <= 32'h7836_310E;
                8'h0B: oRomData <= 32'h7836_32e2;
                8'h0C: oRomData <= 32'h7836_3312;
                8'h0D: oRomData <= 32'h7836_21e0;
                8'h0E: oRomData <= 32'h7837_04a0;
                8'h0F: oRomData <= 32'h7837_035a;
                8'h10: oRomData <= 32'h7837_1578;
                8'h11: oRomData <= 32'h78371701;
                8'h12: oRomData <= 32'h78370b60;
                8'h13: oRomData <= 32'h7837_051a;
                8'h14: oRomData <= 32'h7839_0502;
                8'h15: oRomData <= 32'h7839_0610;
                8'h16: oRomData <= 32'h7839_010a;
                8'h17: oRomData <= 32'h7837_3112;
                8'h18: oRomData <= 32'h7836_0008;
                8'h19: oRomData <= 32'h7836_0133;
                8'h1A: oRomData <= 32'h7830_2d60;
                8'h1B: oRomData <= 32'h7836_2052;
                8'h1C: oRomData <= 32'h7837_1b20;
                8'h1D: oRomData <= 32'h7847_1c50;
                8'h1E: oRomData <= 32'h783a_1343;
                8'h1F: oRomData <= 32'h783a_1800;
                8'h20: oRomData <= 32'h783a_197c;
                8'h21: oRomData <= 32'h7836_3513;
                8'h22: oRomData <= 32'h7836_3603;
                8'h23: oRomData <= 32'h7836_3440;
                8'h24: oRomData <= 32'h7836_2201;
                8'h25: oRomData <= 32'h783c_0134;
                8'h26: oRomData <= 32'h783c_0428;
                8'h27: oRomData <= 32'h783c_0598;
                8'h28: oRomData <= 32'h783c_0600;
                8'h29: oRomData <= 32'h783c_0707;
                8'h2A: oRomData <= 32'h783c_0800;
                8'h2B: oRomData <= 32'h783c_091c;
                8'h2C: oRomData <= 32'h783c_0a9c;
                8'h2D: oRomData <= 32'h783c_0b40;
                8'h2E: oRomData <= 32'h7838_1000;
                8'h2F: oRomData <= 32'h7838_1110;
                8'h30: oRomData <= 32'h7838_1200;
                8'h31: oRomData <= 32'h7837_0864;
                8'h32: oRomData <= 32'h7840_0102;
                8'h33: oRomData <= 32'h7840_051a;
                8'h34: oRomData <= 32'h7830_0000;
                8'h35: oRomData <= 32'h7830_04ff;
                8'h36: oRomData <= 32'h7830_0e58;
                8'h37: oRomData <= 32'h7830_2e00;
                8'h38: oRomData <= 32'h7843_0030;
                8'h39: oRomData <= 32'h7850_1f00;
                8'h3A: oRomData <= 32'h7844_0e00;
                8'h3B: oRomData <= 32'h7850_00a7;
                8'h3C: oRomData <= 32'h7830_0802;
                8'h3D: oRomData <= 32'h783c_0708;
                8'h3E: oRomData <= 32'h7838_2041;
                8'h3F: oRomData <= 32'h7838_2107;
                8'h40: oRomData <= 32'h7838_1431;
                8'h41: oRomData <= 32'h7838_1531;
                8'h42: oRomData <= 32'h7838_0000;
                8'h43: oRomData <= 32'h7838_0100;
                8'h44: oRomData <= 32'h7838_0200;
                8'h45: oRomData <= 32'h7838_0304;
                8'h46: oRomData <= 32'h7838_040a;
                8'h47: oRomData <= 32'h7838_053f;
                8'h48: oRomData <= 32'h7838_0607;
                8'h49: oRomData <= 32'h7838_079b;
                8'h4A: oRomData <= 32'h7838_0802;
                8'h4B: oRomData <= 32'h7838_0980;
                8'h4C: oRomData <= 32'h7838_0a01;
                8'h4D: oRomData <= 32'h7838_0be0;
                8'h4E: oRomData <= 32'h7838_0c07;
                8'h4F: oRomData <= 32'h7838_0d68;
                8'h50: oRomData <= 32'h7838_0e03;
                8'h51: oRomData <= 32'h7838_0fd8;
                8'h52: oRomData <= 32'h7838_1306;
                8'h53: oRomData <= 32'h7836_1800;
                8'h54: oRomData <= 32'h7836_1229;
                8'h55: oRomData <= 32'h7837_0952;
                8'h56: oRomData <= 32'h7837_0c03;
                8'h57: oRomData <= 32'h783_a020b;
                8'h58: oRomData <= 32'h783a_0388;
                8'h59: oRomData <= 32'h783a_140b;
                8'h5A: oRomData <= 32'h783a_1588;
                8'h5B: oRomData <= 32'h7840_0402;
                8'h5C: oRomData <= 32'h7830_021c;
                8'h5D: oRomData <= 32'h7830_06c3;
                8'h5E: oRomData <= 32'h7847_1303;
                8'h5F: oRomData <= 32'h7844_0704;
                8'h60: oRomData <= 32'h7846_0b35;
                8'h61: oRomData <= 32'h7846_0c22;
                8'h62: oRomData <= 32'h7848_3722;
                8'h63: oRomData <= 32'h7838_2402;
                8'h64: oRomData <= 32'h7850_01a3;
                8'h65: oRomData <= 32'h7830_341a;
                8'h66: oRomData <= 32'h7830_3511;
                8'h67: oRomData <= 32'h7830_3646;
                8'h68: oRomData <= 32'h7830_3713;
                8'h69: oRomData <= 32'h7835_0300;
                8'h6A: oRomData <= 32'h7850_1F01;
                8'h6B: oRomData <= 32'h7850_202A;
                8'h6C: oRomData <= 32'h7843_0061;
                8'h6D: oRomData <= 32'h7838_2002;
                8'h6E: begin
                    oRomData <= 32'h7838_2102;
                    RomDone <= 1'b1;
                end
                default: oRomData <= 32'h0000_0000;
            endcase
        end else begin
            case (iRomAddr)
                8'h00: begin
                    oRomData <= 32'h0040_0011;
                    RomDone <= 1'b0;
                end
                8'h01: oRomData <= 32'h0040_0118;
                8'h02: oRomData <= 32'h0040_0118;
                8'h03: oRomData <= 32'h0040_0118;
                8'h04: oRomData <= 32'h0040_0118;
                8'h05: oRomData <= 32'h0040_0118;
                8'h06: oRomData <= 32'h0040_0118;
                8'h07: oRomData <= 32'h0040_0118;
                8'h08: oRomData <= 32'h0040_0118;
                8'h09: oRomData <= 32'h0040_0118;
                8'h0A: oRomData <= 32'h0040_0118;
                8'h0B: begin
                    oRomData <= 32'h0040_0118;
                    RomDone <= 1'b1;
                end
                default: oRomData <= 32'h0000_0000;
            endcase
        end
    end
    
    assign oRomDone = RomDone;
endmodule
