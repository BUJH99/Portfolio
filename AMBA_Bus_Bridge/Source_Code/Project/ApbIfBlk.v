`timescale 1ns/10ps



module ApbIfBlk (

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
  output [3:0]     oAddr,             // 32bit data address
  
  output [31:0]    oWrDt,
  input  [31:0]    iRdDt

  );


  // wire & reg declaration
  wire             wWrEn;              // Active at high
  wire  [3:0]      wWrAddr;            // 32bit data write address
  wire  [31:0]     wWrData;            // Write data

  wire             wRdEn;              // Active at high
  wire  [3:0]      wRdAddr;            // 32bit data read address
  wire  [31:0]     wRdData;            // Read data
  wire  		   ADDRInRANGE;		   // h8000 ~ h803C
  
  // AddrInRange
  parameter BASE_ADDR = 16'h8000;
  parameter END_ADDR  = 16'h803C;
  
  assign ADDRInRANGE = (iPaddr >= BASE_ADDR) && (iPaddr <= END_ADDR) ? 1'b1 : 1'b0; 
    
    /******************************************************************/
  // SP-SRAM write signals
  /******************************************************************/
  // Write enable (Active @ high)
  assign wWrEn =  ((iPsel == 1'b1) & (iPenable == 1'b0) & (iPwrite  == 1'b1) & (ADDRInRANGE == 1'b1 )) ? 1'b1 : 1'b0;

  // Write address (32bit data address)
  assign wWrAddr = iPaddr[5:2];

  // Write data
  assign wWrData = iPwdata[31:0];


  /******************************************************************/
  // SP-SRAM read signals
  /******************************************************************/
  // Read enable (Active @ high)
  assign wRdEn =  ((iPsel == 1'b1) & (iPenable == 1'b0) & (iPwrite  == 1'b0) & (ADDRInRANGE == 1'b1 )) ? 1'b1 : 1'b0;

  // Read address (32bit data address)
  assign wRdAddr = iPaddr[5:2];


  /******************************************************************/
  // SP-SRAM interface mapping
  /******************************************************************/

  // oCsn (0: Selected, 1: Not selected)
  assign oCsn    = (wWrEn == 1'b1 || wRdEn == 1'b1) ? 1'b0 : 1'b1;

  // oWrn (0: write, 1: read)
  assign oWrn    = (wWrEn == 1'b1 && wRdEn == 1'b0) ? 1'b0 : 1'b1;

  // oAddr[3:0]
  assign oAddr   = (wWrEn == 1'b1) ? wWrAddr[3:0] :
	               (wRdEn == 1'b1) ? wRdAddr[3:0] : 4'b0000;

  // Write data @ zero wait
  assign oWrDt   = wWrData[31:0];

  // Read data @ zero wait
  assign wRdData = iRdDt[31:0];


  /******************************************************************/
  // oPrdata, oPready mapping
  /******************************************************************/
  assign oPrdata = wRdData[31:0];
  
  assign oPready = (iPsel == 1'b1 && iPenable == 1'b1) ? 1'b1 : 1'b0;

endmodule

