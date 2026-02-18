/**********************************************************************
  - Project          : 2025 summer internship
  - File name        : Lab3_2_Top.v
  - Description      : Lab3_2 top file
  - Owner            : Inchul.song
  - Revision history : 1) 2024.12.27 : Initial release
                       2) 2025.06.26 : add oPready
**********************************************************************/

`timescale 1ns/10ps

module Lab3_2_Top (

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


  // Interrupt out to CPU
  output           oOutEnable

  );


  // wire & reg
  wire             wStDtCp;
  wire [9:0]       wPktWdSize;

  wire             wDtCpDone;


  wire             wWrEn_InBuf;
  wire [8:0]       wWrAddr_InBuf;
  wire [31:0]      wWrDt_InBuf;

  wire             wRdEn_OutBuf;
  wire [8:0]       wRdAddr_OutBuf;
  wire [31:0]      wRdDt_OutBuf;


  wire             wRdEn_InBuf;
  wire [8:0]       wRdAddr_InBuf;
  wire [31:0]      wRdDt_InBuf;

  wire             wWrEn_OutBuf;
  wire [8:0]       wWrAddr_OutBuf;
  wire [31:0]      wWrDt_OutBuf;



  //**************************************************//
  // Lab3_2_ApbIfBlk.v instantiation
  //**************************************************//
  Lab3_2_ApbIfBlk A_Lab3_2_ApbIfBlk (

    // Clock & reset
    .iClk               (iClk),
    .iRsn               (iRsn),


    // APB interface
    .iPsel              (iPsel),
    .iPenable           (iPenable),
    .iPwrite            (iPwrite),
    .iPaddr             (iPaddr[15:0]),

    .iPwdata            (iPwdata[31:0]),
    .oPrdata            (oPrdata[31:0]),
    .oPready            (oPready),


    // FthDataCp.v interface
    .oStDtCp            (wStDtCp),
    .oPktWdSize         (wPktWdSize[9:0]),

    .iDtCpDone          (wDtCpDone),


    // InBuf(BufWrap) write interface
    .oWrEn_InBuf        (wWrEn_InBuf),
    .oWrAddr_InBuf      (wWrAddr_InBuf[8:0]),
    .oWrDt_InBuf        (wWrDt_InBuf[31:0]),


    // OutBuf(BufWrap) read interface
    .oRdEn_OutBuf       (wRdEn_OutBuf),
    .oRdAddr_OutBuf     (wRdAddr_OutBuf[8:0]),
    .iRdDt_OutBuf       (wRdDt_OutBuf[31:0]),


    // Interrupt out to CPU
    .oOutEnable         (oOutEnable)

  );


  //**************************************************//
  // InBuf(BufWra.v) instantiation
  //**************************************************//
  BufWrap A_InBufWrap (

    // Clock & reset
    .iClk               (iClk),
    .iRsn               (iRsn),


    // Write port
    .iWrEn              (wWrEn_InBuf),
    .iWrAddr            (wWrAddr_InBuf[8:0]),
    .iWrDt              (wWrDt_InBuf[31:0]),


    // Read port
    .iRdEn              (wRdEn_InBuf),
    .iRdAddr            (wRdAddr_InBuf[8:0]),
    .oRdDt              (wRdDt_InBuf[31:0])

  );


  //**************************************************//
  // FthDataCp.v instantiation
  //**************************************************//
  Lab3_2_EndianConv A_Lab3_2_EndianConv (

    // Clock & reset
    .iClk               (iClk),
    .iRsn               (iRsn),


    // FthApbIfBlk.v interface
    .iStDtCp            (wStDtCp),
    .iPktWdSize         (wPktWdSize[9:0]),

    .oDtCpDone          (wDtCpDone),


    // InBuf(BufWrap.v) read interface
    .oRdEn_InBuf        (wRdEn_InBuf),
    .oRdAddr_InBuf      (wRdAddr_InBuf[8:0]),
    .iRdDt_InBuf        (wRdDt_InBuf[31:0]),


    // OutBuf(BufWrap.v) write interface
    .oWrEn_OutBuf       (wWrEn_OutBuf),
    .oWrAddr_OutBuf     (wWrAddr_OutBuf[8:0]),
    .oWrDt_OutBuf       (wWrDt_OutBuf[31:0])

  );


  //**************************************************//
  // OutBuf(BufWra.v) instantiation
  //**************************************************//
  BufWrap A_OutBufWrap (

    // Clock & reset
    .iClk               (iClk),
    .iRsn               (iRsn),


    // Write port
    .iWrEn              (wWrEn_OutBuf),
    .iWrAddr            (wWrAddr_OutBuf[8:0]),
    .iWrDt              (wWrDt_OutBuf[31:0]),


    // Read port
    .iRdEn              (wRdEn_OutBuf),
    .iRdAddr            (wRdAddr_OutBuf[8:0]),
    .oRdDt              (wRdDt_OutBuf[31:0])

  );


endmodule
