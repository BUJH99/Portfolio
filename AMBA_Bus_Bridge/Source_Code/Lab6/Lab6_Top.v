/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab6_Top.v
  - Description      : Lab6 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2025.06.30 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab6_Top (

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
  output           oHREADY

  );


  // wire & reg declaration
  wire             wCsn;
  wire             wWrn;
  wire  [1:0]      wAddr;

  wire  [31:0]     wWrDt;
  wire  [31:0]     wRdDt;


  /*************************************************************/
  // Lab6_AhbIfBlk instantiation
  /*************************************************************/
  Lab6_AhbIfBlk A_Lab6_AhbIfBlk (

    // Clock & reset
    .iClk          (iClk),
    .iRsn          (iRsn),


    // AHB interface
    .iHSEL         (iHSEL),
    .iHTRANS       (iHTRANS[1:0]),
    .iHWRITE       (iHWRITE),
    .iHADDR        (iHADDR[31:0]),
    .iHREADYin     (iHREADYin),

    .iHWDATA       (iHWDATA[31:0]),

    .oHRDATA       (oHRDATA[31:0]),
    .oHRESP        (oHRESP[1:0]),
    .oHREADY       (oHREADY),


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
