/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab5_AhbIfBlk.v
  - Description      : 2ea read reg & 1ea write reg w/ AHB Interface
  - Owner            : Inchul.song
  - Revision history : 1) 2025.06.30 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab5_AhbIfBlk (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // AHB interface
  input            iHSEL,
  input  [1:0]     iHTRANS,
  input            iHWRITE,
  input  [31:0]    iHADDR,
  input            iHREADYin,

  input  [31:0]    iHWDATA,

  output [31:0]    oHRDATA,
  output [1:0]     oHRESP,
  output           oHREADY,


  // Write register output
  output [31:0]    oInA,               // rApbInAData out
  output [31:0]    oInB,               // rApbInBData out


  // Read register input
  input  [31:0]    iOutC               // wApbOutCData in

  );



  // wire & reg declaration
  reg              rHSEL;
  reg  [1:0]       rHTRANS;
  reg              rHWRITE;
  reg  [31:0]      rHADDR;

  wire             wWrEnInA;           // rAhbInA write enable
  reg  [31:0]      rAhbInA;            // Write register A

  wire             wWrEnInB;           // rAhbInB write eanble
  reg  [31:0]      rAhbInB;            // Write register B

  wire             wRdSelOutC;         // Read register C selection 



  // Address phase latch with iHREADYin
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rHSEL   <= 1'h0;
      rHTRANS <= 2'h0;
      rHWRITE <= 1'h0;
      rHADDR  <= 32'h0;
    end
    else if (iHREADYin == 1'b1)
    begin
      rHSEL   <= iHSEL;
      rHTRANS <= iHTRANS[1:0];
      rHWRITE <= iHWRITE;
      rHADDR  <= iHADDR[31:0];
    end

  end



  // Data phase operation for each register's access enable
  // AHB register A write enable
  assign wWrEnInA =  (   (rHSEL        == 1'b1)
                      && (rHTRANS[1:0] == 2'b10|| rHTRANS[1:0] == 2'b11)  // Nonseq || Seq
		      && (rHWRITE      == 1'b1)                           // Write
		      && (rHADDR[31:0] == 32'h00000000)                   // Reg A address
                      && (iHREADYin    == 1'b1) ) ? 1'b1 : 1'b0;          // Valid at 1'b1

  // AHB register B write enable
  assign wWrEnInB =  (   (rHSEL        == 1'b1)
                      && (rHTRANS[1:0] == 2'b10|| rHTRANS[1:0] == 2'b11)  // Nonseq || Seq
		      && (rHWRITE      == 1'b1)                           // Write
		      && (rHADDR[31:0] == 32'h00000004)                   // Reg B address
                      && (iHREADYin    == 1'b1) ) ? 1'b1 : 1'b0;          // Valid at 1'b1



  // AHB register C read selection
  assign wRdSelOutC = (   (rHSEL        == 1'b1)
                      && (rHTRANS[1:0] == 2'b10|| rHTRANS[1:0] == 2'b11)  // Nonseq || Seq
		      && (rHWRITE      == 1'b0)                           // Read
		      && (rHADDR[31:0] == 32'h00000008)                   // Reg C address
                      && (iHREADYin    == 1'b1) ) ? 1'b1 : 1'b0;          // Valid at 1'b1



  // AHB register A & B write function
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rAhbInA <= 32'h0;
      rAhbInB <= 32'h0;
    end

    // rApbInAData register write
    else if (wWrEnInA == 1'b1)
    begin
      rAhbInA <= iHWDATA[31:0]; 
    end

    // rApbInBData register write
    else if (wWrEnInB == 1'b1)
    begin
      rAhbInB <= iHWDATA[31:0]; 
    end

  end


  // AHB register C read selection function
  assign oHRDATA = (wRdSelOutC == 1'b1) ? iOutC[31:0] : 32'h0; 


  // oHREADY & oHRESP[1:0] function
  assign oHRESP  = 2'b00;                                                 // Okay response
  assign oHREADY = 1'b1;                                                  // No wait state


  // Output mapping
  assign oInA    = rAhbInA[31:0];
  assign oInB    = rAhbInB[31:0];


endmodule
