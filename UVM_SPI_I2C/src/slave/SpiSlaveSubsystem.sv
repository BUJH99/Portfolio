/*
[MODULE_INFO_START]
Name: SpiSlaveSubsystem
Role: Complete SPI slave engine for the Serial Slave project
Summary:
  - Synchronizes incoming SPI signals, detects protocol edges, and decodes 16-bit Mode-0 register transactions
  - Returns register read data on MISO and emits completed write/read transactions to the manager layer
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SpiSlaveSubsystem (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iEnable,
  input  logic       iJaCs,
  input  logic       iJaMosi,
  input  logic       iJaSclk,
  input  logic [7:0] iTxnReadData,
  output logic       oJaMiso,
  output logic       oTxnValid,
  output logic       oTxnWrite,
  output logic [7:0] oTxnAddr,
  output logic [7:0] oTxnWdata
);

  logic SpiCsIn;
  logic SpiSclkIn;
  logic SpiMosiIn;
  logic SpiCsSync;
  logic SpiSclkSync;
  logic SpiMosiSync;
  logic SpiCsRise;
  logic SpiCsFall;
  logic SpiSclkRise;
  logic SpiSclkFall;
  logic SpiStartFrame;
  logic SpiSampleMosi;
  logic SpiShiftMiso;
  logic SpiFrameDone;
  logic SpiMisoBit;

  assign SpiCsIn   = iEnable ? iJaCs   : 1'b1;
  assign SpiSclkIn = iEnable ? iJaSclk : 1'b0;
  assign SpiMosiIn = iEnable ? iJaMosi : 1'b0;

  SpiSlaveInputSync uSpiSlaveInputSync (
    .iClk    (iClk),
    .iRst    (iRst),
    .iCs     (SpiCsIn),
    .iSclk   (SpiSclkIn),
    .iMosi   (SpiMosiIn),
    .oCsSync (SpiCsSync),
    .oSclkSync(SpiSclkSync),
    .oMosiSync(SpiMosiSync)
  );

  SpiSlaveEdgeDetect uSpiSlaveEdgeDetect (
    .iClk     (iClk),
    .iRst     (iRst),
    .iCsSync  (SpiCsSync),
    .iSclkSync(SpiSclkSync),
    .oCsRise  (SpiCsRise),
    .oCsFall  (SpiCsFall),
    .oSclkRise(SpiSclkRise),
    .oSclkFall(SpiSclkFall)
  );

  SpiSlaveDatapath uSpiSlaveDatapath (
    .iClk      (iClk),
    .iRst      (iRst),
    .iStartFrame(SpiStartFrame),
    .iSampleMosi(SpiSampleMosi),
    .iShiftMiso(SpiShiftMiso),
    .iMosiSync (SpiMosiSync),
    .iReadData (iTxnReadData),
    .oMisoBit  (SpiMisoBit),
    .oHeaderReady(),
    .oTxnWrite (oTxnWrite),
    .oTxnAddr  (oTxnAddr),
    .oTxnWdata (oTxnWdata),
    .oFrameDone(SpiFrameDone)
  );

  SpiSlaveCtrl uSpiSlaveCtrl (
    .iClk      (iClk),
    .iRst      (iRst),
    .iCsFall   (SpiCsFall),
    .iCsRise   (SpiCsRise),
    .iSclkRise (SpiSclkRise),
    .iSclkFall (SpiSclkFall),
    .iFrameDone(SpiFrameDone),
    .oStartFrame(SpiStartFrame),
    .oSampleMosi(SpiSampleMosi),
    .oShiftMiso(SpiShiftMiso),
    .oTxnValid (oTxnValid),
    .oBusy     ()
  );

  SpiSlaveIo uSpiSlaveIo (
    .iEnable (iEnable),
    .iMisoBit(SpiMisoBit),
    .oJaMiso (oJaMiso)
  );

endmodule
