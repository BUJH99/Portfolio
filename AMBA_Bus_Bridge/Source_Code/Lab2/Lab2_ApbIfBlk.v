/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab2_ApbIfBlk.v
  - Description      : 2ea read reg & 1ea write reg w/ APB Interface
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.26 : Initial release
                       2) 2025.06.25 : add oPready
*******************************************************************/

`timescale 1ns/10ps

module Lab2_ApbIfBlk (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // APB interface
  input            iPsel,
  input            iPenable,
  input            iPwrite,
  input  [15:0]    iPaddr,

  input  [31:0]    iPwdata,
  output [31:0]    oPrdata,
  output           oPready,


  // Write register output
  output [31:0]    oInA,               // rApbInAData out
  output [31:0]    oInB,               // rApbInBData out


  // Read register input
  input  [31:0]    iOutC               // wApbOutCData in

  );


  // wire & reg declaration
  wire             wWrEnInA;           // rApbInAData write enable
  reg  [31:0]      rApbInAData;        // Register

  wire             wWrEnInB;           // rApbInBData write eanble
  reg  [31:0]      rApbInBData;        // Register

  wire             wRdEnOutC;          // wApbOutCData read enable 

  reg  [31:0]      rPrdata;            // APB read register


  // Register write enable
  assign wWrEnInA =  (   (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr   == 16'h0000) ) ? 1'b1 : 1'b0; 

  assign wWrEnInB =  (   (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b1)
		       & (iPaddr   == 16'h0004) ) ? 1'b1 : 1'b0;


  // Register read enable
  assign wRdEnOutC = (   (iPsel    == 1'b1)
                       & (iPenable == 1'b0)
		       & (iPwrite  == 1'b0)
		       & (iPaddr   == 16'h000C) ) ? 1'b1 : 1'b0;


  // APB write function
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rApbInAData <= 32'h0;
      rApbInBData <= 32'h0;
    end

    // rApbInAData register write
    else if (wWrEnInA == 1'b1)
    begin
      rApbInAData <= iPwdata[31:0]; 
    end

    // rApbInBData register write
    else if (wWrEnInB == 1'b1)
    begin
      rApbInBData <= iPwdata[31:0]; 
    end

  end


  // APB read function
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rPrdata <= 32'h0;
    end

    else if (wRdEnOutC == 1'b1)
    begin
      rPrdata <= iOutC[31:0];
    end

  end


  // Output mapping
  assign oInA    = rApbInAData[31:0];
  assign oInB    = rApbInBData[31:0];

  assign oPrdata = rPrdata[31:0];
  assign oPready = (iPsel == 1'b1 && iPenable == 1'b1) ? 1'b1 : 1'b0;


endmodule
