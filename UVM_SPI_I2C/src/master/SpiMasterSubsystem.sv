/*
[MODULE_INFO_START]
Name: SpiMasterSubsystem
Role: Complete SPI master transaction engine for the Master project
Summary:
  - Integrates the SPI divider, input synchronizer, datapath, controller, and pin adapter
  - Exposes an abstract register transaction interface to the top-level sequencer
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SpiMasterSubsystem #(
  parameter int unsigned P_DIV = 100
) (
  input  logic       iClk,
  input  logic       iRst,
  input  logic       iTxnStart,
  input  logic       iTxnRw,
  input  logic [7:0] iTxnRegAddr,
  input  logic [7:0] iTxnWrData,
  input  logic       iJaMiso,
  output logic       oTxnBusy,
  output logic       oTxnDone,
  output logic [7:0] oTxnRdData,
  output logic       oJaCs,
  output logic       oJaMosi,
  output logic       oJaSclk
);

  logic SpiTick;
  logic SpiMisoSync;
  logic SpiDivEnable;
  logic SpiLoadFrame;
  logic SpiSampleRx;
  logic SpiShiftTx;
  logic SpiCaptureFrame;
  logic SpiBitsDone;
  logic SpiMosiBit;
  logic SpiCsActive;
  logic SpiSclkLevel;

  SpiMasterClockDivider #(
    .P_DIV(P_DIV)
  ) uSpiMasterClockDivider (
    .iClk   (iClk),
    .iRst   (iRst),
    .iEnable(SpiDivEnable),
    .oTick  (SpiTick)
  );

  SpiMasterInputSync uSpiMasterInputSync (
    .iClk    (iClk),
    .iRst    (iRst),
    .iMiso   (iJaMiso),
    .oMisoSync(SpiMisoSync)
  );

  SpiMasterDatapath uSpiMasterDatapath (
    .iClk        (iClk),
    .iRst        (iRst),
    .iLoadFrame  (SpiLoadFrame),
    .iSampleRx   (SpiSampleRx),
    .iShiftTx    (SpiShiftTx),
    .iCaptureFrame(SpiCaptureFrame),
    .iMisoSync   (SpiMisoSync),
    .iTxnRw      (iTxnRw),
    .iTxnRegAddr (iTxnRegAddr),
    .iTxnWrData  (iTxnWrData),
    .oMosiBit    (SpiMosiBit),
    .oBitsDone   (SpiBitsDone),
    .oRxData     (oTxnRdData)
  );

  SpiMasterCtrl uSpiMasterCtrl (
    .iClk        (iClk),
    .iRst        (iRst),
    .iTxnStart   (iTxnStart),
    .iTick       (SpiTick),
    .iBitsDone   (SpiBitsDone),
    .oDivEnable  (SpiDivEnable),
    .oCsActive   (SpiCsActive),
    .oSclkLevel  (SpiSclkLevel),
    .oLoadFrame  (SpiLoadFrame),
    .oSampleRx   (SpiSampleRx),
    .oShiftTx    (SpiShiftTx),
    .oCaptureFrame(SpiCaptureFrame),
    .oBusy       (oTxnBusy),
    .oDone       (oTxnDone)
  );

  SpiMasterIo uSpiMasterIo (
    .iCsActive (SpiCsActive),
    .iSclkLevel(SpiSclkLevel),
    .iMosiBit  (SpiMosiBit),
    .oJaCs     (oJaCs),
    .oJaMosi   (oJaMosi),
    .oJaSclk   (oJaSclk)
  );

endmodule
