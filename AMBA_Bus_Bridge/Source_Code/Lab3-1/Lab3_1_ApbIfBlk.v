/*******************************************************************
  - Project          : 2025 summer Internship
  - File name        : Lab3_1_ApbIfBlk.v
  - Description      : 4x32 SP-SRAM I/F with APB I/F
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
                       2) 2025.06.25 : add N-clock delay oPready
*******************************************************************/

`timescale 1ns/10ps

module Lab3_1_ApbIfBlk (

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


  // SP-SRAM interface
  output           oCsn,              // Active(Chip select)  @ Low
  output           oWrn,              // Active(Write enable) @ Low
  output [1:0]     oAddr,             // 32bit data address
  
  output [31:0]    oWrDt,
  input  [31:0]    iRdDt

  );


  // wire & reg declaration
  wire             wWrEn;              // Active at high
  wire  [1:0]      wWrAddr;            // 32bit data write address
  wire  [31:0]     wWrData;            // Write data

  wire             wRdEn;              // Active at high
  wire  [1:0]      wRdAddr;            // 32bit data read address
  wire  [31:0]     wRdData;            // Read data


  reg   [3:0]      rPreadyCnt;         // N-clock delay counter
  wire             wPready;            // N-clock delay oPready


  /******************************************************************/
  // SP-SRAM write signals
  /******************************************************************/
  // Write enable (Active @ high)
  assign wWrEn =  (   (iPsel    == 1'b1)
                    & (iPenable == 1'b0)
	            & (iPwrite  == 1'b1)
	            & (iPaddr   == 16'h4000 || iPaddr == 16'h4004
                                            || iPaddr == 16'h4008
                                            || iPaddr == 16'h400C) ) ? 1'b1 : 1'b0;

  // Write address (32bit data address)
  assign wWrAddr = iPaddr[3:2];

  // Write data
  assign wWrData = iPwdata[31:0];


  /******************************************************************/
  // SP-SRAM read signals
  /******************************************************************/
  // Read enable (Active @ high)
  assign wRdEn =  (   (iPsel    == 1'b1)
                    & (iPenable == 1'b0)
	            & (iPwrite  == 1'b0)
	            & (iPaddr   == 16'h4000 || iPaddr == 16'h4004
                                            || iPaddr == 16'h4008
                                            || iPaddr == 16'h400C) ) ? 1'b1 : 1'b0;

  // Read address (32bit data address)
  assign wRdAddr = iPaddr[3:2];


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
  assign oWrDt   =  iPwdata[31:0];

  // Read data
  assign wRdData =  iRdDt[31:0];


  /******************************************************************/
  // oPrdata mapping
  /******************************************************************/
  // oPrdata (Plz check SP-SRAM & APB I/F read timing !!!)
  assign oPrdata = wRdData[31:0];


  /******************************************************************/
  // oPready mapping
  // oPready is 1-clock delay of Lab2's
  /******************************************************************/

  // N-clock delay
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rPreadyCnt <= 4'hf;
    end
    // Setup condition
    else if (iPsel == 1'b1 && iPenable == 1'b0)
    begin
      rPreadyCnt <= 4'h0;
    end
    else
    begin

      if (rPreadyCnt == 4'hf || wPready == 1'b1)
        rPreadyCnt <= 4'hf;
      else if (rPreadyCnt < 4'hf)
        rPreadyCnt <= 4'( rPreadyCnt[3:0] + 4'h1 );

    end

  end

  // oPready condition (14-clock delay)
  assign wPready = (rPreadyCnt[3:0] == 4'he) ? 1'b1 : 1'b0;


  // oPreday mapping
  assign oPready = wPready;


endmodule
