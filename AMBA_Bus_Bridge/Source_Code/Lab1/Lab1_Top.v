/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab1_Top.v
  - Description      : Add function
  - Owner            : Inchul.song
  - Revision history : 1) 2025.06.24 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab1_Top (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // Input
  input            iInEnable,          // Input enable
  input  [31:0]    iInA,
  input  [31:0]    iInB,


  // output to FstApbIfBlk.v
  input            iOutEnable,        // Output enable
  output [31:0]    oOutC

  );


  // wire & reg declaration
  reg  [31:0]      rInA;
  reg  [31:0]      rInB;


  wire [31:0]      wOutC;
  reg  [31:0]      rOutC;



  // Input signals latech
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rInA <= 32'h0;
      rInB <= 32'h0;
    end
    else if (iInEnable == 1'b1)
    begin
      rInA <= iInA[31:0];
      rInB <= iInB[31:0];
    end

  end



  // Add function
//assign wOutC = {1'b0, rInA[31:0]} + {1'b0, rInB[31:0]};
  assign wOutC = 32'( rInA[31:0] + rInB[31:0] );



  // Output signal latch
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      rOutC <= 32'h0;
    else if (iOutEnable == 1'b1)
      rOutC <= wOutC[31:0];

  end


  // Output mapping
  assign oOutC = rOutC[31:0];


endmodule
