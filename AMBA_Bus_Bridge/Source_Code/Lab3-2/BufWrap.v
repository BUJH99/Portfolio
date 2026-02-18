/*******************************************************************
  - Project          : 2025 summer internship
  - File name        : BufWrap.v
  - Description      : 512x32 SPSRAM wrapper
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module BufWrap (

  // Clock & reset
  input            iClk,               // Rising edge
  input            iRsn,               // Sync. & low reset


  // Write port
  input            iWrEn,              // Write enable, active high
  input  [8:0]     iWrAddr,            // Write address
  input  [31:0]    iWrDt,              // 32bit write data


  // Read port
  input            iRdEn,              // Read enable, active high
  input  [8:0]     iRdAddr,            // Read address
  output [31:0]    oRdDt               // 32bit read data

  );



  // Wire & reg declaration
  wire             wCsn;
  wire             wWrn;
  wire [8:0]       wAddr;



  /*******************************************************/
  // SpSram interface signals
  /*******************************************************/
  // Chip select (0: Selected, 1: Not selected)
  assign wCsn    = (iWrEn == 1'b1 || iRdEn == 1'b1) ? 1'b0 : 1'b1;

  // Write enable (0: write, 1: read)
  assign wWrn    = (iWrEn == 1'b1 && iRdEn == 1'b0) ? 1'b0 : 1'b1;

  // 32bit address
  assign wAddr   = (iWrEn == 1'b1) ? iWrAddr[8:0] :
                   (iRdEn == 1'b1) ? iRdAddr[8:0] : 9'h0;



  /*******************************************************/
  // SpSram instantiation
  /*******************************************************/
  SpSram_512x32 A_SpSram_512x32 (
  // Clock & reset
    .iClk               (iClk),
    .iRsn               (iRsn),


  // SP-SRAM Input & Output
    .iCsn               (wCsn),
    .iWrn               (wWrn),
    .iAddr              (wAddr[8:0]),

    .iWrDt              (iWrDt[31:0]),
    .oRdDt              (oRdDt[31:0])
  );


endmodule
