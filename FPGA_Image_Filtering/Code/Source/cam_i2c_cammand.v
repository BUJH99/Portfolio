`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 10:10:10
// Design Name: 
// Module Name: cam_i2c_commnd
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


module cam_i2c_command(
    input clk_i,
    input   sw_i,
    input   i2c_cmd_en_i,
    input   [31:0]  i2c_cmd_data_i,
    output  i2c_cmd_end_o,
    inout   i2c_scl_b,
    inout   i2c_sda_b 
    );
    
    localparam IDLE     = 2'b00;
    localparam OV5640   = 2'b01;
    localparam CIS_2M   = 2'b10;
    
    reg     [1:0]   sig_state = IDLE;
    
    reg     [31:0]  sig_i2c_command_data;
    reg             sig_i2c_scl;
    reg             sig_i2c_sda;
    reg     [7:0]   sig_count;
    reg             sig_i2c_command_end;
    
    always @(posedge clk_i) begin
        case (sig_state)
            IDLE: begin
                sig_i2c_scl <= 1;
                sig_i2c_sda <= 1;
                
                if (i2c_cmd_en_i == 1) begin
                    sig_i2c_command_data <= i2c_cmd_data_i;
                    if (sw_i == 1) begin
                        sig_state <= OV5640;
                    end else begin
                        sig_state <= CIS_2M;
                    end
                end
            end
            
            OV5640: begin
                if (sig_count == 113) begin
                    sig_count <= 0;
                    sig_state <= IDLE;
                end else begin
                    sig_count <= sig_count + 1;
                end
                
                case (sig_count)
                    8'h00: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1;
                    end
                    8'h01: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 0;
                    end
                    8'h02: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 0;
                    end
                    8'h03: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[31];
                    end
                    8'h04: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[31];
                    end
                    8'h05: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[31];
                    end
                    8'h06: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[30];
                    end
                    8'h07: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[30];
                    end
                    8'h08: begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[30];
                    end
                    8'h09: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[29];
                    end
                    8'h0A: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[29];
                    end
                    8'h0B: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[29];
                    end
                    8'h0C: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[28];
                    end
                    8'h0D: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[28];
                    end
                    8'h0E: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[28];
                    end
                    8'h0F: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[27];
                    end
                    8'h10: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[27];
                    end
                    8'h11: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[27];
                    end
                    8'h12: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[26];
                    end
                    8'h13: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[26];
                    end
                    8'h14: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[26];
                    end
                    8'h15: begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[25];
                    end
                    8'h16: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[25];
                    end
                    8'h17  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[25];
                    end
                    8'h18  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[24];
                    end
                    8'h19  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[24];
                    end
                    8'h1A  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[24];
                    end
                    8'h1B  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h1C  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1'bz;
                    end
                    8'h1D  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h1E  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h1F  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h20  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h21  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h22  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h23  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h24  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h25  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h26  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h27  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h28  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h29  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h2A  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[19];
                    end
                    8'h2B  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[19];
                    end
                    8'h2C  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[19];
                    end
                    8'h2D  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h2E  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h2F  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h30  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h31  : begin
                    sig_i2c_scl <= 1;
                    sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h32  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h33  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h34  : begin
                    sig_i2c_scl <= 1;
                    sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h35  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h36  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= 1'bZ;
                    end
                    8'h37  : begin
                    sig_i2c_scl <= 1;
                    sig_i2c_sda <= 1'bZ;
                    end
                    8'h38  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= 1'bZ;
                    end
                    8'h39  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h3A  : begin
                    sig_i2c_scl <= 1;
                    sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h3B  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h3C  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h3D  : begin
                    sig_i2c_scl <= 1;
                    sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h3E  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h3F  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h40  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h41  : begin
                    sig_i2c_scl <= 0;
                    sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h42  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[12];

                    end
                    8'h43  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[12];
                    end
                    8'h44  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[12];

                    end
                    8'h45  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[11];

                    end
                    8'h46  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[11];

                    end
                    8'h47  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[11];

                    end
                    8'h48  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[10];

                    end
                    8'h49  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[10];

                    end
                    8'h4A  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[10];

                    end
                    8'h4B  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[9];

                    end
                    8'h4C  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[9];

                    end
                    8'h4D  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[9];

                    end
                    8'h4E  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[8];

                    end
                    8'h4F  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[8];

                    end
                    8'h50  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[8];

                    end
                    8'h51  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h52  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h53  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h54  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[7];

                    end
                    8'h55  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[7];

                    end
                    8'h56  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[7];

                    end
                    8'h57  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[6];

                    end
                    8'h58  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[6];

                    end
                    8'h59  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[6];

                    end
                    8'h5A  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[5];

                    end
                    8'h5B  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[5];

                    end
                    8'h5C  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[5];

                    end
                    8'h5D  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[4];

                    end
                    8'h5E  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[4];

                    end
                    8'h5F  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[4];

                    end
                    8'h60  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[3];

                    end
                    8'h61  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[3];

                    end
                    8'h62  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[3];

                    end
                    8'h63  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[2];

                    end
                    8'h64  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[2];

                    end
                    8'h65  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[2];

                    end
                    8'h66  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[1];

                    end
                    8'h67  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[1];

                    end
                    8'h68  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[1];

                    end
                    8'h69  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[0];

                    end
                    8'h6A  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= sig_i2c_command_data[0];

                    end
                    8'h6B  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= sig_i2c_command_data[0];

                    end
                    8'h6C  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h6D  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h6E  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= 1'bZ;

                    end
                    8'h6F  : begin
                                        sig_i2c_scl <= 0;
                                        sig_i2c_sda <= 0;

                    end
                    8'h70  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= 0;
                                        sig_i2c_command_end <= 1;

                    end
                    8'h71  : begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= 1;
                                        sig_i2c_command_end <= 0;
                    end
                    default: begin
                                        sig_i2c_scl <= 1;
                                        sig_i2c_sda <= 1;
                    end
                endcase
            end
        
            CIS_2M: begin
                if (sig_count == 86) begin
                    sig_count <= 0;
                    sig_state <= IDLE;
                end else begin
                    sig_count <= sig_count + 1;
                end

                case (sig_count)
                    8'h00  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1;
                    end
                    8'h01  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 0;
                    end
                    8'h02  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 0;
                    end
                    8'h03  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h04  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h05  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[23];
                    end
                    8'h06  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h07  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h08  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[22];
                    end
                    8'h09  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h0A  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h0B  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[21];
                    end
                    8'h0C  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h0D  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h0E  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[20];
                    end
                    8'h0F  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[19];
                    end
                    8'h10  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[19];

                    end
                    8'h11  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[19];
                    end
                    8'h12  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h13  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h14  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[18];
                    end
                    8'h15  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h16  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h17  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[17];
                    end
                    8'h18  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h19  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h1A  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[16];
                    end
                    8'h1B  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h1C  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h1D  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h1E  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h1F  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h20  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[15];
                    end
                    8'h21  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h22  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h23  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[14];
                    end
                    8'h24  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h25  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h26  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[13];
                    end
                    8'h27  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[12];
                    end
                    8'h28  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[12];
                    end
                    8'h29  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[12];
                    end
                    8'h2A  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[11];
                    end
                    8'h2B  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[11];
                    end
                    8'h2C  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[11];
                    end
                    8'h2D  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[10];
                    end
                    8'h2E  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[10];
                    end
                    8'h2F  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[10];
                    end
                    8'h30  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[9];
                    end
                    8'h31  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[9];
                    end
                    8'h32  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[9];
                    end
                    8'h33  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[8];
                    end
                    8'h34  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[8];
                    end
                    8'h35  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[8];
                    end
                    8'h36  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h37  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h38  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h39  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[7];
                    end
                    8'h3A  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[7];
                    end
                    8'h3B  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[7];
                    end
                    8'h3C  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[6];
                    end
                    8'h3D  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[6];
                    end
                    8'h3E  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[6];
                    end
                    8'h3F  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[5];
                    end
                    8'h40  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[5];
                    end
                    8'h41  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[5];
                    end
                    8'h42  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[4];
                    end
                    8'h43  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[4];
                    end
                    8'h44  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[4];
                    end
                    8'h45  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[3];
                    end
                    8'h46  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[3];
                    end
                    8'h47  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[3];
                    end
                    8'h48  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[2];
                    end
                    8'h49  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[2];
                    end
                    8'h4A  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[2];
                    end
                    8'h4B  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[1];
                    end
                    8'h4C  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[1];
                    end
                    8'h4D  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[1];
                    end
                    8'h4E  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[0];
                    end
                    8'h4F  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= sig_i2c_command_data[0];
                    end
                    8'h50  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= sig_i2c_command_data[0];
                    end
                    8'h51  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h52  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h53  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 1'bZ;
                    end
                    8'h54  : begin
                        sig_i2c_scl <= 0;
                        sig_i2c_sda <= 0;
                    end
                    8'h55  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 0;
                        sig_i2c_command_end <= 1;
                    end
                    8'h56  : begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1;
                        sig_i2c_command_end <= 0;
                    end
                    default: begin
                        sig_i2c_scl <= 1;
                        sig_i2c_sda <= 1;
                    end
                endcase
            end
            // CIS_2M case end
        endcase
        //sig state case end
    end
    
    assign i2c_cmd_end_o = sig_i2c_command_end;
    assign i2c_scl_b = sig_i2c_scl;
    assign i2c_sda_b = sig_i2c_sda;
    
endmodule
