/*
[MODULE_INFO_START]
Name: I2cMasterSubsystem
Role: Complete I2C master transaction engine for the Master project
Summary:
  - Integrates divider, synchronizer, datapath, control FSM, and board-facing IO adapter
  - Presents a single-byte register transaction interface to the top-level sequencer
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module I2cMasterSubsystem #(
  parameter int unsigned P_DIV = 1000
) (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iTxnStart,
  input  logic       iTxnRw,
  input  logic [7:0] iTxnRegAddr,
  input  logic [7:0] iTxnWrData,
  input  logic       iSclIn,
  input  logic       iSdaIn,
  output logic       oTxnBusy,
  output logic       oTxnDone,
  output logic [7:0] oTxnRdData,
  output logic       oSclDriveLow,
  output logic       oSdaDriveLow
);

  logic Tick;
  logic SclSync;
  logic SdaSync;
  logic DivEnable;
  logic LoadTxByte;
  logic [7:0] TxByte;
  logic ClearBitCnt;
  logic TxAdvance;
  logic RxSample;
  logic CaptureAck;
  logic TxBit;
  logic LastBit;
  logic AckBit;
  logic SclLevel;
  logic SclDriveLow;
  logic SdaDriveLow;

  I2cMasterClockDivider #(
    .P_DIV(P_DIV)
  ) uI2cMasterClockDivider (
    .iClk   (iClk),
    .iRst   (iRst),
    .iEnable(DivEnable),
    .oTick  (Tick)
  );

  I2cMasterInputSync uI2cMasterInputSync (
    .iClk   (iClk),
    .iRst   (iRst),
    .iScl   (iSclIn),
    .iSda   (iSdaIn),
    .oSclSync(SclSync),
    .oSdaSync(SdaSync)
  );

  I2cMasterDatapath uI2cMasterDatapath (
    .iClk       (iClk),
    .iRst       (iRst),
    .iLoadTxByte(LoadTxByte),
    .iTxByte    (TxByte),
    .iClearBitCnt(ClearBitCnt),
    .iTxAdvance (TxAdvance),
    .iRxSample  (RxSample),
    .iCaptureAck(CaptureAck),
    .iSdaSync   (SdaSync),
    .oTxBit     (TxBit),
    .oLastBit   (LastBit),
    .oAckBit    (AckBit),
    .oRxByte    (oTxnRdData)
  );

  I2cMasterCtrl uI2cMasterCtrl (
    .iClk       (iClk),
    .iRst       (iRst),
    .iTxnStart  (iTxnStart),
    .iTxnRw     (iTxnRw),
    .iTxnRegAddr(iTxnRegAddr),
    .iTxnWrData (iTxnWrData),
    .iTick      (Tick),
    .iSclSync   (SclSync),
    .iSdaSync   (SdaSync),
    .iTxBit     (TxBit),
    .iLastBit   (LastBit),
    .iAckBit    (AckBit),
    .oDivEnable (DivEnable),
    .oBusy      (oTxnBusy),
    .oDone      (oTxnDone),
    .oSclLevel  (SclLevel),
    .oSdaDriveLow(SdaDriveLow),
    .oLoadTxByte(LoadTxByte),
    .oTxByte    (TxByte),
    .oClearBitCnt(ClearBitCnt),
    .oTxAdvance (TxAdvance),
    .oRxSample  (RxSample),
    .oCaptureAck(CaptureAck)
  );

  I2cMasterIo uI2cMasterIo (
    .iSclLevel   (SclLevel),
    .iSdaDriveLow(SdaDriveLow),
    .oSclDriveLow(SclDriveLow),
    .oSdaDriveLow(oSdaDriveLow)
  );

  assign oSclDriveLow = SclDriveLow;

endmodule
