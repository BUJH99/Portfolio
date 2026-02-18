`timescale 1ns/10ps

module ApbSlave_Top (

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
  output           oPready

  );


  // wire & reg declaration
  wire             wCsn;
  wire             wWrn;
  wire  [3:0]      wAddr;

  wire  [31:0]     wWrDt;
  wire  [31:0]     wRdDt;


  /*************************************************************/
  // ApbIfBlk instantiation
  /*************************************************************/
  ApbIfBlk I_ApbIfBlk (

    // Clock & reset
    .iClk          (iClk),
    .iRsn          (iRsn),


    // APB interface
    .iPsel         (iPsel),
    .iPenable      (iPenable),
    .iPwrite       (iPwrite),
    .iPaddr        (iPaddr[15:0]),

    .iPwdata       (iPwdata[31:0]),
    .oPrdata       (oPrdata[31:0]),
    .oPready       (oPready),


    // SP-SRAM interface
    .oCsn          (wCsn),
    .oWrn          (wWrn),
    .oAddr         (wAddr[3:0]),
  
    .oWrDt         (wWrDt[31:0]),
    .iRdDt         (wRdDt[31:0])

  );



  /*************************************************************/
  // SP-SRAM instantiation
  /*************************************************************/
  SpSram16x32 I_SpSram (

  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // SP-SRAM Input & Output
  .iCsn            (wCsn),
  .iWrn            (wWrn),
  .iAddr           (wAddr[3:0]),

  .iWrDt           (wWrDt[31:0]),
  .oRdDt           (wRdDt[31:0])

  );


endmodule
