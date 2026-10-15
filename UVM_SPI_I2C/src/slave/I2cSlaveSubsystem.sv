/*
[MODULE_INFO_START]
Name: I2cSlaveSubsystem
Role: Complete I2C slave engine for the Serial Slave project
Summary:
  - Synchronizes bus inputs, detects START/STOP conditions, and decodes single-byte register accesses with repeated-start reads
  - Drives ACK/readback timing via an open-drain SDA low-enable output and emits completed write transactions to the manager layer
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module I2cSlaveSubsystem (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iEnable,
  input  logic       iJbScl,
  input  logic       iSdaIn,
  input  logic [7:0] iTxnReadData,
  output logic       oSdaDriveLow,
  output logic       oTxnValid,
  output logic       oTxnWrite,
  output logic [7:0] oTxnAddr,
  output logic [7:0] oTxnWdata
);

  logic I2cSclIn;
  logic I2cSdaIn;
  logic SclSync;
  logic SdaSync;
  logic SclRise;
  logic SclFall;
  logic StartPulse;
  logic StopPulse;
  logic StartFrame;
  logic LoadTxByte;
  logic [7:0] TxByte;
  logic ClearBitCnt;
  logic SampleRxBit;
  logic AdvanceTxBit;
  logic SdaDriveLow;
  logic [7:0] RxByte;
  logic TxBit;
  logic LastBit;

  assign I2cSclIn = iEnable ? iJbScl : 1'b1;
  assign I2cSdaIn = iEnable ? iSdaIn : 1'b1;

  I2cSlaveInputSync uI2cSlaveInputSync (
    .iClk    (iClk),
    .iRst    (iRst),
    .iScl    (I2cSclIn),
    .iSda    (I2cSdaIn),
    .oSclSync(SclSync),
    .oSdaSync(SdaSync)
  );

  I2cSlaveEdgeDetect uI2cSlaveEdgeDetect (
    .iClk      (iClk),
    .iRst      (iRst),
    .iSclSync  (SclSync),
    .iSdaSync  (SdaSync),
    .oSclRise  (SclRise),
    .oSclFall  (SclFall),
    .oStartPulse(StartPulse),
    .oStopPulse(StopPulse)
  );

  I2cSlaveDatapath uI2cSlaveDatapath (
    .iClk      (iClk),
    .iRst      (iRst),
    .iStartFrame(StartFrame),
    .iLoadTxByte(LoadTxByte),
    .iTxByte   (TxByte),
    .iClearBitCnt(ClearBitCnt),
    .iSampleRxBit(SampleRxBit),
    .iAdvanceTxBit(AdvanceTxBit),
    .iSdaSync  (SdaSync),
    .oRxByte   (RxByte),
    .oTxBit    (TxBit),
    .oLastBit  (LastBit)
  );

  I2cSlaveCtrl uI2cSlaveCtrl (
    .iClk      (iClk),
    .iRst      (iRst),
    .iStartPulse(StartPulse),
    .iStopPulse(StopPulse),
    .iSclRise  (SclRise),
    .iSclFall  (SclFall),
    .iRxByte   (RxByte),
    .iTxBit    (TxBit),
    .iLastBit  (LastBit),
    .iTxnReadData(iTxnReadData),
    .oStartFrame(StartFrame),
    .oLoadTxByte(LoadTxByte),
    .oTxByte   (TxByte),
    .oClearBitCnt(ClearBitCnt),
    .oSampleRxBit(SampleRxBit),
    .oAdvanceTxBit(AdvanceTxBit),
    .oSdaDriveLow(SdaDriveLow),
    .oTxnValid (oTxnValid),
    .oTxnWrite (oTxnWrite),
    .oTxnAddr  (oTxnAddr),
    .oTxnWdata (oTxnWdata)
  );

  I2cSlaveIo uI2cSlaveIo (
    .iEnable     (iEnable),
    .iSdaDriveLow(SdaDriveLow),
    .oSdaDriveLow(oSdaDriveLow)
  );

endmodule
