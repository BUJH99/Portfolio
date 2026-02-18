/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab2_Top.v
  - Description      : Lab2 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.26 : Initial release
                       2) 2025.06.25 : add oPready
*******************************************************************/

`timescale 1ns/10ps

module Lab2_Top (

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
  wire [31:0]      wInA;
  wire [31:0]      wInB;

  wire [31:0]      wOutC;


  // ApbIfBlk_Lab1 instantiation
  Lab2_ApbIfBlk A_Lab2_ApbIfBlk (

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


    // Write register output
    .oInA          (wInA[31:0]),
    .oInB          (wInB[31:0]),


    // Read register input
    .iOutC         (wOutC[31:0])

  );


  // FstFuncBlk instantiation
  Lab2_FuncBlk A_Lab2_FuncBlk (

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
