/*******************************************************************
  - Project          : 2025 summer Internship
  - File name        : Lab6_AhbIfBlk.v
  - Description      : 4x32 SP-SRAM I/F with AHB I/F
  - Owner            : Inchul.song
  - Revision history : 1) 2025.06.30 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab6_AhbIfBlk (

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


  // SP-SRAM interface
  output           oCsn,              // Active(Chip select)  @ Low
  output           oWrn,              // Active(Write enable) @ Low
  output [1:0]     oAddr,             // 32bit data address
  
  output [31:0]    oWrDt,
  input  [31:0]    iRdDt

  );



  // wire & reg declaration
  wire             wWrValid;
  wire             wRdValid;

  reg              rWrValid;
  reg              rRdValid;
  reg  [31:0]      rHADDR;


  wire             wWrEn;              // Active at high
  wire  [1:0]      wWrAddr;            // 32bit data write address
  wire  [31:0]     wWrData;            // Write data

  wire             wRdEn;              // Active at high
  wire  [1:0]      wRdAddr;            // 32bit data read address
  wire  [31:0]     wRdData;            // Read data


  reg   [1:0]      rHRESP;
  reg   [3:0]      rHREADY;




  /******************************************************************/
  // Valid signal making @ Each address phase
  /******************************************************************/
  // Write valid codition
  assign wWrValid = (   (iHSEL        == 1'b1)
                     && (iHTRANS[1]   == 1'b1)                            // Nonseq || Seq                         
                     && (iHWRITE      == 1'b1)                            // Write
                     && (iHADDR[31:4] == 28'h7000400) ) ? 1'b1 : 1'b0;    // SRAM access addr.


  // Read valid codition
  assign wRdValid = (   (iHSEL        == 1'b1)
                     && (iHTRANS[1]   == 1'b1)                            // Nonseq || Seq
                     && (iHWRITE      == 1'b0)                            // Read
                     && (iHADDR[31:4] == 28'h7000400) ) ? 1'b1 : 1'b0;    // SRAM access addr.



  // Each valid & iHADDR delay to Data phase
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rWrValid <= 1'b0;
      rRdValid <= 1'b0;

      rHADDR   <= 32'h0;
    end

    else if (iHREADYin == 1'b1)
    begin
      rWrValid <= wWrValid;
      rRdValid <= wRdValid;

      rHADDR   <= iHADDR[31:0];
    end

  end



  /******************************************************************/
  // SP-SRAM write signals @ data pahse
  // Zero wait during write data phase !!!
  /******************************************************************/
  // Write enable (active high)
  assign wWrEn  = (rWrValid == 1'b1 && iHREADYin == 1'b1) ? 1'b1 : 1'b0;


  // Write address (Bus(Byte) address to memory(word) address)
  assign wWrAddr = rHADDR[3:2];


  // Write data (Bus to SRAM)
  assign wWrData = iHWDATA[31:0];



  /******************************************************************/
  // SP-SRAM read signals @ data pahse
  // One wait during read data phase !!!
  /******************************************************************/
  // Read enable (active high)
  // wRdEn = 1'b1 @ iHREADYin == 1'b0 because of 1 wait read !!!
  assign wRdEn = (rRdValid == 1'b1 && iHREADYin == 1'b0) ? 1'b1 : 1'b0;


  // Read address (Bus(Byte) address to memory(word) address)
  assign wRdAddr = rHADDR[3:2];


  // Read data (SRAM to Bus)
  assign oHRDATA = wRdData[31:0];



  /******************************************************************/
  // oHRESP[1:0] & oHREADY signals making
  /******************************************************************/
  // rHRESP[1:0] & rHREADY
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rHRESP  <= 2'b00;      // Always Okay response !!!
      rHREADY <= 1'b1;       // HREADY's Reset value must be 1'b1 !!!
    end

    // Write valid condition (Zero wait write)
    else if (wWrValid == 1'b1 && iHREADYin == 1'b1)
    begin
      rHRESP  <= 2'b00;
      rHREADY <= 1'b1;
    end

    // Read valid condition (One wait write)
    else if (wRdValid == 1'b1 && iHREADYin == 1'b1)
    begin
      rHRESP  <= 2'b00;
      rHREADY <= 1'b0;
    end

    // Else condition
    else
    begin
      rHRESP  <= 2'b00;
      rHREADY <= 1'b1;
    end

  end


/** You can shrink the uppder code to the below code briefly !!!

  // rHRESP[1:0] & rHREADY
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rHRESP  <= 2'b00;      // Always Okay response !!!
      rHREADY <= 1'b1;       // HREADY's Reset value must be 1'b1 !!!
    end

    // Read valid condition (One wait write)
    else if (wRdValid == 1'b1 && iHREADYin == 1'b1)
    begin
      rHRESP  <= 2'b00;
      rHREADY <= 1'b0;
    end

    // Else condition (Write valid condition is included in this codition)
    else
    begin
      rHRESP  <= 2'b00;
      rHREADY <= 1'b1;
    end

  end

**/


  assign oHRESP  = rHRESP[1:0];
  assign oHREADY = rHREADY;



  /******************************************************************/
  // SP-SRAM interface mapping
  /******************************************************************/

  // oCsn (0: Selected, 1: Not selected)
  assign oCsn    = (wWrEn == 1'b1 || wRdEn == 1'b1) ? 1'b0 : 1'b1;

  // oWrn (0: write, 1: read)
  assign oWrn    = (wWrEn == 1'b1 && wRdEn == 1'b0) ? 1'b0 : 1'b1;

  // oAddr[1:0]
  assign oAddr   = (wWrEn == 1'b1) ? wWrAddr[1:0] :
	           (wRdEn == 1'b1) ? wRdAddr[1:0] : 2'h0;

  // Write data
  assign oWrDt   =  wWrData[31:0];

  // Read data
  assign wRdData =  iRdDt[31:0];


endmodule
