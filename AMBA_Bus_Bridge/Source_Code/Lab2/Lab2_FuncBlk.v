/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab2_FuncBlk.v
  - Description      : Add & delay function
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.26 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab2_FuncBlk (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // Input from FstApbIfBlk.v
  input  [31:0]    iInA,
  input  [31:0]    iInB,


  // output to FstApbIfBlk.v
  output [31:0]    oOutC

  );


  // wire & reg declaration
  wire [31:0]      wOutC;
  reg  [31:0]      rOutC;              // wOutC 1clk delay


  // Add function
  assign wOutC = 32'( iInA[31:0] + iInB[31:0] );


  // APB read function
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      rOutC <= 32'h0;
    else
      rOutC <= wOutC[31:0];

  end


  // Output mapping
  assign oOutC = rOutC[31:0];


endmodule
