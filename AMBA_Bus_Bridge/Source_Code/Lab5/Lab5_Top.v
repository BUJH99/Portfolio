/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab5_Top.v
  - Description      : Lab5 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2025.06.30 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Lab5_Top (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // APB interface
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
  wire [31:0]      wInA;
  wire [31:0]      wInB;

  wire [31:0]      wOutC;



  // Lab5_AhbIfBlk.v instantiation
  Lab5_AhbIfBlk A_Lab5_AhbIfBlk (

    // Clock & reset
    .iClk          (iClk),
    .iRsn          (iRsn),


    // APB interface
    .iHSEL         (iHSEL),
    .iHTRANS       (iHTRANS[1:0]),
    .iHWRITE       (iHWRITE),
    .iHADDR        (iHADDR[31:0]),
    .iHREADYin     (iHREADYin),

    .iHWDATA       (iHWDATA[31:0]),

    .oHRDATA       (oHRDATA[31:0]),
    .oHRESP        (oHRESP[1:0]),
    .oHREADY       (oHREADY),


    // Write register output
    .oInA          (wInA[31:0]),
    .oInB          (wInB[31:0]),


    // Read register input
    .iOutC         (wOutC[31:0])

  );


  // Lab5_FuncBlk.v instantiation
  Lab5_FuncBlk A_Lab5_FuncBlk (

  // Clock & reset
  .iClk            (iClk),
  .iRsn            (iRsn),


  // Input from FstApbIfBlk.v
  .iInA            (wInA[31:0]),
  .iInB            (wInB[31:0]),


  // output to FstApbIfBlk.v
  .oOutC           (wOutC[31:0])

  );


endmodule
