/*
[MODULE_INFO_START]
Name: ClkDivider
Role: Divide an input clock by toggling an output after a programmable count.
Summary:
  - Counts input clock edges up to the requested divider count.
  - Toggles the output clock when the count terminal is reached.
[MODULE_INFO_END]
*/

`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/19 09:07:54
// Design Name: 
// Module Name: ClkDivider
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


module ClkDivider(
    input   logic iClk,
    input   logic [15:0]  iDivCount,
    output  logic oClk
    );
    
    logic     [15:0]  Cnt;
    logic             ClkOut;
    
    always_ff @(posedge iClk) begin
        if (Cnt == iDivCount) begin
            Cnt <= 0;
        end else begin
            Cnt <= Cnt + 1;
        end
    end
    
    always_ff @(posedge iClk) begin
        if (Cnt == iDivCount) begin
            ClkOut <= ~(ClkOut);
        end else begin
            
        end
    end
    
    assign oClk = ClkOut;
    
endmodule
