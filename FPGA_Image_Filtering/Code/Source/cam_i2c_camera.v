`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 10:10:10
// Design Name: 
// Module Name: cam_i2c_camera
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


module cam_i2c_rom(
    input   clk_i,
    input   sw1_i,
    input   [7:0]   i2c_rom_addr_i,
    output  reg [31:0]  i2c_rom_data_o,
    output  i2c_rom_final_o
    );
    
    reg     sig_i2c_rom_final;
    
    always @(posedge clk_i) begin
        if (sw1_i == 1'b1) begin
            case (i2c_rom_addr_i)
                8'h00: begin
                    i2c_rom_data_o <= 32'h78310311;
                    sig_i2c_rom_final <= 0;
                end
                8'h01: i2c_rom_data_o <= 32'h7830_0882;
                8'h02: i2c_rom_data_o <= 32'h7830_0842;
                8'h03: i2c_rom_data_o <= 32'h7831_0303;
                8'h04: i2c_rom_data_o <= 32'h7830_17FF;
                8'h05: i2c_rom_data_o <= 32'h7830_18FF;
                8'h06: i2c_rom_data_o <= 32'h7830_341A;
                8'h07: i2c_rom_data_o <= 32'h7830_3713;
                8'h08: i2c_rom_data_o <= 32'h7831_0801;
                8'h09: i2c_rom_data_o <= 32'h7836_3036;
                8'h0A: i2c_rom_data_o <= 32'h7836_310E;
                8'h0B: i2c_rom_data_o <= 32'h7836_32e2;
                8'h0C: i2c_rom_data_o <= 32'h7836_3312;
                8'h0D: i2c_rom_data_o <= 32'h7836_21e0;
                8'h0E: i2c_rom_data_o <= 32'h7837_04a0;
                8'h0F: i2c_rom_data_o <= 32'h7837_035a;
                8'h10: i2c_rom_data_o <= 32'h7837_1578;
                8'h11: i2c_rom_data_o <= 32'h78371701;
                8'h12: i2c_rom_data_o <= 32'h78370b60;
                8'h13: i2c_rom_data_o <= 32'h7837_051a;
                8'h14: i2c_rom_data_o <= 32'h7839_0502;
                8'h15: i2c_rom_data_o <= 32'h7839_0610;
                8'h16: i2c_rom_data_o <= 32'h7839_010a;
                8'h17: i2c_rom_data_o <= 32'h7837_3112;
                8'h18: i2c_rom_data_o <= 32'h7836_0008;
                8'h19: i2c_rom_data_o <= 32'h7836_0133;
                8'h1A: i2c_rom_data_o <= 32'h7830_2d60;
                8'h1B: i2c_rom_data_o <= 32'h7836_2052;
                8'h1C: i2c_rom_data_o <= 32'h7837_1b20;
                8'h1D: i2c_rom_data_o <= 32'h7847_1c50;
                8'h1E: i2c_rom_data_o <= 32'h783a_1343;
                8'h1F: i2c_rom_data_o <= 32'h783a_1800;
                8'h20: i2c_rom_data_o <= 32'h783a_197c;
                8'h21: i2c_rom_data_o <= 32'h7836_3513;
                8'h22: i2c_rom_data_o <= 32'h7836_3603;
                8'h23: i2c_rom_data_o <= 32'h7836_3440;
                8'h24: i2c_rom_data_o <= 32'h7836_2201;
                8'h25: i2c_rom_data_o <= 32'h783c_0134;
                8'h26: i2c_rom_data_o <= 32'h783c_0428;
                8'h27: i2c_rom_data_o <= 32'h783c_0598;
                8'h28: i2c_rom_data_o <= 32'h783c_0600;
                8'h29: i2c_rom_data_o <= 32'h783c_0707;
                8'h2A: i2c_rom_data_o <= 32'h783c_0800;
                8'h2B: i2c_rom_data_o <= 32'h783c_091c;
                8'h2C: i2c_rom_data_o <= 32'h783c_0a9c;
                8'h2D: i2c_rom_data_o <= 32'h783c_0b40;
                8'h2E: i2c_rom_data_o <= 32'h7838_1000;
                8'h2F: i2c_rom_data_o <= 32'h7838_1110;
                8'h30: i2c_rom_data_o <= 32'h7838_1200;
                8'h31: i2c_rom_data_o <= 32'h7837_0864;
                8'h32: i2c_rom_data_o <= 32'h7840_0102;
                8'h33: i2c_rom_data_o <= 32'h7840_051a;
                8'h34: i2c_rom_data_o <= 32'h7830_0000;
                8'h35: i2c_rom_data_o <= 32'h7830_04ff;
                8'h36: i2c_rom_data_o <= 32'h7830_0e58;
                8'h37: i2c_rom_data_o <= 32'h7830_2e00;
                8'h38: i2c_rom_data_o <= 32'h7843_0030;
                8'h39: i2c_rom_data_o <= 32'h7850_1f00;
                8'h3A: i2c_rom_data_o <= 32'h7844_0e00;
                8'h3B: i2c_rom_data_o <= 32'h7850_00a7;
                8'h3C: i2c_rom_data_o <= 32'h7830_0802;
                8'h3D: i2c_rom_data_o <= 32'h783c_0708;
                8'h3E: i2c_rom_data_o <= 32'h7838_2041;
                8'h3F: i2c_rom_data_o <= 32'h7838_2107;
                8'h40: i2c_rom_data_o <= 32'h7838_1431;
                8'h41: i2c_rom_data_o <= 32'h7838_1531;
                8'h42: i2c_rom_data_o <= 32'h7838_0000;
                8'h43: i2c_rom_data_o <= 32'h7838_0100;
                8'h44: i2c_rom_data_o <= 32'h7838_0200;
                8'h45: i2c_rom_data_o <= 32'h7838_0304;
                8'h46: i2c_rom_data_o <= 32'h7838_040a;
                8'h47: i2c_rom_data_o <= 32'h7838_053f;
                8'h48: i2c_rom_data_o <= 32'h7838_0607;
                8'h49: i2c_rom_data_o <= 32'h7838_079b;
                8'h4A: i2c_rom_data_o <= 32'h7838_0802;
                8'h4B: i2c_rom_data_o <= 32'h7838_0980;
                8'h4C: i2c_rom_data_o <= 32'h7838_0a01;
                8'h4D: i2c_rom_data_o <= 32'h7838_0be0;
                8'h4E: i2c_rom_data_o <= 32'h7838_0c07;
                8'h4F: i2c_rom_data_o <= 32'h7838_0d68;
                8'h50: i2c_rom_data_o <= 32'h7838_0e03;
                8'h51: i2c_rom_data_o <= 32'h7838_0fd8;
                8'h52: i2c_rom_data_o <= 32'h7838_1306;
                8'h53: i2c_rom_data_o <= 32'h7836_1800;
                8'h54: i2c_rom_data_o <= 32'h7836_1229;
                8'h55: i2c_rom_data_o <= 32'h7837_0952;
                8'h56: i2c_rom_data_o <= 32'h7837_0c03;
                8'h57: i2c_rom_data_o <= 32'h783_a020b;
                8'h58: i2c_rom_data_o <= 32'h783a_0388;
                8'h59: i2c_rom_data_o <= 32'h783a_140b;
                8'h5A: i2c_rom_data_o <= 32'h783a_1588;
                8'h5B: i2c_rom_data_o <= 32'h7840_0402;
                8'h5C: i2c_rom_data_o <= 32'h7830_021c;
                8'h5D: i2c_rom_data_o <= 32'h7830_06c3;
                8'h5E: i2c_rom_data_o <= 32'h7847_1303;
                8'h5F: i2c_rom_data_o <= 32'h7844_0704;
                8'h60: i2c_rom_data_o <= 32'h7846_0b35;
                8'h61: i2c_rom_data_o <= 32'h7846_0c22;
                8'h62: i2c_rom_data_o <= 32'h7848_3722;
                8'h63: i2c_rom_data_o <= 32'h7838_2402;
                8'h64: i2c_rom_data_o <= 32'h7850_01a3;
                8'h65: i2c_rom_data_o <= 32'h7830_341a;
                8'h66: i2c_rom_data_o <= 32'h7830_3511;
                8'h67: i2c_rom_data_o <= 32'h7830_3646;
                8'h68: i2c_rom_data_o <= 32'h7830_3713;
                8'h69: i2c_rom_data_o <= 32'h7835_0300;
                8'h6A: i2c_rom_data_o <= 32'h7850_1F01;
                8'h6B: i2c_rom_data_o <= 32'h7850_202A;
                8'h6C: i2c_rom_data_o <= 32'h7843_0061;
                8'h6D: i2c_rom_data_o <= 32'h7838_2002;
                8'h6E: begin
                    i2c_rom_data_o <= 32'h7838_2102;
                    sig_i2c_rom_final <= 1'b1;
                end
                default: i2c_rom_data_o <= 32'h0000_0000;
            endcase
        end else begin
            case (i2c_rom_addr_i)
                8'h00: begin
                    i2c_rom_data_o <= 32'h0040_0011;
                    sig_i2c_rom_final <= 1'b0;
                end
                8'h01: i2c_rom_data_o <= 32'h0040_0118;
                8'h02: i2c_rom_data_o <= 32'h0040_0118;
                8'h03: i2c_rom_data_o <= 32'h0040_0118;
                8'h04: i2c_rom_data_o <= 32'h0040_0118;
                8'h05: i2c_rom_data_o <= 32'h0040_0118;
                8'h06: i2c_rom_data_o <= 32'h0040_0118;
                8'h07: i2c_rom_data_o <= 32'h0040_0118;
                8'h08: i2c_rom_data_o <= 32'h0040_0118;
                8'h09: i2c_rom_data_o <= 32'h0040_0118;
                8'h0A: i2c_rom_data_o <= 32'h0040_0118;
                8'h0B: begin
                    i2c_rom_data_o <= 32'h0040_0118;
                    sig_i2c_rom_final <= 1'b1;
                end
                default: i2c_rom_data_o <= 32'h0000_0000;
            endcase
        end
    end
    
    assign i2c_rom_final_o = sig_i2c_rom_final;
endmodule
