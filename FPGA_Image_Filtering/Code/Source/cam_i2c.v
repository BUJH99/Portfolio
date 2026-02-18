`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/18 09:37:18
// Design Name: 
// Module Name: cam_i2c
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


module cam_i2c(
    input   clk_i,
    input   sw,
    output  cam_rst_no,
    output  cam_pwdn,
    inout   cam_scl,
    inout   cam_sda
    );
    
    localparam INIT = 2'b00;
    localparam CMD  = 2'b01;
    localparam CHK  = 2'b10;
    localparam IDLE = 2'b11;
    
    reg     [1:0]   sig_state = INIT;
    reg     [7:0]   sig_initialize_count = 0;
    
    reg             sig_sw_delay_1 = 0;
    reg             sig_sw_delay_2 = 0;
    reg             sig_camera_RESETn = 0;
    reg             sig_camera_PWDN = 0;
    
    reg     [7:0]   sig_i2c_rom_addr = 0;
    wire    [31:0]  sig_i2c_rom_data;
    wire            sig_i2c_rom_final;
    reg             sig_i2c_command_en = 0;
    wire            sig_i2c_command_end;
    
    cam_i2c_rom I2C_ROM(
        .clk_i(clk_i),
        .sw1_i(sw),
        .i2c_rom_addr_i(sig_i2c_rom_addr),
        .i2c_rom_data_o(sig_i2c_rom_data),
        .i2c_rom_final_o(sig_i2c_rom_final)
    );
    
     cam_i2c_command I2C_COMMAND(
         .clk_i(clk_i),
         .sw_i(sw),
         .i2c_cmd_en_i(sig_i2c_command_en),
         .i2c_cmd_data_i(sig_i2c_rom_data),
         .i2c_cmd_end_o(sig_i2c_command_end),
         .i2c_scl_b(cam_scl),
         .i2c_sda_b(cam_sda)
     );
    
    always @(posedge clk_i) begin
        sig_sw_delay_1 <= sw;
        sig_sw_delay_2 <= sig_sw_delay_1;
    end
    
    always @(posedge clk_i) begin
        case (sig_state)
            INIT    : begin
                if (sig_initialize_count == 1) begin
                    sig_camera_RESETn <= 0;
                    if (sw == 1) begin
                        sig_camera_PWDN <= 1;
                    end else begin
                        sig_camera_PWDN <= 0;
                    end
                    sig_initialize_count <= sig_initialize_count + 1;
                    
                end else if (sig_initialize_count == 50) begin
                    sig_camera_RESETn <= 1;
                    if (sw == 1) begin
                        sig_camera_PWDN <= 0;
                    end else begin
                        sig_camera_PWDN <= 1;
                    end
                    sig_initialize_count <= sig_initialize_count + 1;
                    
                end else if (sig_initialize_count == 100) begin
                    sig_initialize_count <= 0;
                    sig_state <= CMD;
                end else begin
                    sig_initialize_count <= sig_initialize_count + 1;
                end
            end
            CMD     : begin
                if (sig_i2c_command_end == 1) begin
                    sig_i2c_command_en <= 0;
                    sig_state <= CHK;
                end else begin
                    sig_i2c_command_en <= 1;
                end
            end
            CHK     : begin
                if (sig_i2c_rom_final == 1) begin
                    sig_i2c_rom_addr <= 0;
                    sig_state <= IDLE;
                end else begin
                    sig_i2c_rom_addr <= sig_i2c_rom_addr + 1;
                    sig_state <= CMD;
                end
            end
            
            IDLE    : begin
                if ((sig_sw_delay_1 == 1) && (sig_sw_delay_2 == 0)) begin
                    sig_state <= INIT;
                end else if ((sig_sw_delay_1 == 0) && (sig_sw_delay_2 == 1)) begin
                    sig_state <= INIT;
                end
            end
        endcase
    end
    
    assign cam_rst_no = sig_camera_RESETn;
    assign cam_pwdn = sig_camera_PWDN;
    
endmodule
