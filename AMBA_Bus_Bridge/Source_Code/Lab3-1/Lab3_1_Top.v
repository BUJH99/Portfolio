/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab3_1_Top.v
  - Description      : Lab3_1 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
                       2) 2025.06.25 : add 1-clock delay oPready
*******************************************************************/

`timescale 1ns/10ps

module Lab3_1_Top (

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
  wire  [1:0]      wAddr;

  wire  [31:0]     wWrDt;
  wire  [31:0]     wRdDt;


  /*************************************************************/
  // TrdApbIfBlk instantiation
  /*************************************************************/
  Lab3_1_ApbIfBlk A_Lab3_1_ApbIfBlk (

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
    .oAddr         (wAddr[1:0]),
  
    .oWrDt         (wWrDt[31:0]),
    .iRdDt         (wRdDt[31:0])

  );



  /*************************************************************/
  // SP-SRAM instantiation
  /*************************************************************/
  SpSram A_SpSram (

  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // SP-SRAM Input & Output
  .iCsn            (wCsn),
  .iWrn            (wWrn),
  .iAddr           (wAddr[1:0]),

  .iWrDt           (wWrDt[31:0]),
  .oRdDt           (wRdDt[31:0])

  );


endmodule
