/*
[MODULE_INFO_START]
Name: SerialMasterCore
Role: Basys 3 top-level wrapper for the Serial Master project
Summary:
  - Polls a remote Serial_Slave board every 10ms using either SPI or I2C depending on SW[15]
  - Mirrors the remote register readback onto LED[14:8] while routing protocol pins to PMOD JA/JB
  - Drives the I2C JB bus through open-drain SCL/SDA outputs with pull-ups
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SerialMasterCore #(
  parameter int unsigned P_CLK_HZ      = 100_000_000,
  parameter int unsigned P_POLL_CYCLES = 1_000_000,
  parameter int unsigned P_SPI_DIV     = 100,
  parameter int unsigned P_I2C_DIV     = 4000
) (
  input  logic        iClk100Mhz,
  input  logic        iRst,
  input  logic [15:0] iSw,
  output logic [15:0] oLed,
  output logic        oJaCs,
  output logic        oJaMosi,
  input  logic        iJaMiso,
  output logic        oJaSclk,
  inout  wire         ioJbScl,
  inout  wire         ioJbSda,
  output logic        oBusy,
  output logic        oCmdLoad
);

  import serial_protocol_pkg::*;

  protocol_e ProtocolSelRaw;
  protocol_e ProtocolSel;
  protocol_e TxnProtocol;

  logic       Expired;
  logic       Clr;
  logic       Load;
  logic [7:0] WriteData;
  logic       SpiTxnStart;
  logic       I2cTxnStart;
  logic       TxnStart;
  logic       TxnRw;
  logic [7:0] TxnRegAddr;
  logic [7:0] TxnWrData;
  logic [6:0] LedMirror;
  logic       SpiTxnBusy;
  logic       SpiTxnDone;
  logic [7:0] SpiTxnRdData;
  logic       TxnBusy;
  logic       TxnDone;
  logic [7:0] TxnRdData;
  logic       SpiJaCs;
  logic       SpiJaMosi;
  logic       SpiJaSclk;
  logic       SclDriveLow;
  logic       SdaDriveLow;
  logic       SelectedTxnDone;
  logic [7:0] SelectedTxnRdData;

  always_comb begin
    ProtocolSelRaw = iSw[15] ? PROTOCOL_I2C : PROTOCOL_SPI;
  end

  Timer10ms #(
    .P_CYCLES(P_POLL_CYCLES)
  ) uTimer10ms (
    .iClk   (iClk100Mhz),
    .iRst   (iRst),
    .iClr   (Clr),
    .oExpired(Expired)
  );

  CommandLatch uCommandLatch (
    .iClk          (iClk100Mhz),
    .iRst          (iRst),
    .iLoad         (Load),
    .iProtocolSelRaw(ProtocolSelRaw),
    .iWriteDataRaw ({1'b0, iSw[6:0]}),
    .oProtocolSel  (ProtocolSel),
    .oWriteData    (WriteData)
  );

  MasterSequencer uMasterSequencer (
    .iClk        (iClk100Mhz),
    .iRst        (iRst),
    .iTimerExpired(Expired),
    .iProtocolSel(ProtocolSel),
    .iWriteData  (WriteData),
    .iTxnDone    (SelectedTxnDone),
    .iTxnRdData  (SelectedTxnRdData),
    .oTimerClr   (Clr),
    .oCmdLoad    (Load),
    .oTxnStart   (TxnStart),
    .oTxnRw      (TxnRw),
    .oTxnRegAddr (TxnRegAddr),
    .oTxnWrData  (TxnWrData),
    .oTxnProtocol(TxnProtocol),
    .oLedMirror  (LedMirror),
    .oBusy       (oBusy)
  );

  assign SpiTxnStart =
    TxnStart && (TxnProtocol == PROTOCOL_SPI);
  assign I2cTxnStart =
    TxnStart && (TxnProtocol == PROTOCOL_I2C);

  SpiMasterSubsystem #(
    .P_DIV(P_SPI_DIV)
  ) uSpiMasterSubsystem (
    .iClk      (iClk100Mhz),
    .iRst      (iRst),
    .iTxnStart (SpiTxnStart),
    .iTxnRw    (TxnRw),
    .iTxnRegAddr(TxnRegAddr),
    .iTxnWrData(TxnWrData),
    .iJaMiso   (iJaMiso),
    .oTxnBusy  (SpiTxnBusy),
    .oTxnDone  (SpiTxnDone),
    .oTxnRdData(SpiTxnRdData),
    .oJaCs     (SpiJaCs),
    .oJaMosi   (SpiJaMosi),
    .oJaSclk   (SpiJaSclk)
  );

  I2cMasterSubsystem #(
    .P_DIV(P_I2C_DIV)
  ) uI2cMasterSubsystem (
    .iClk      (iClk100Mhz),
    .iRst      (iRst),
    .iTxnStart (I2cTxnStart),
    .iTxnRw    (TxnRw),
    .iTxnRegAddr(TxnRegAddr),
    .iTxnWrData(TxnWrData),
    .iSclIn    (ioJbScl),
    .iSdaIn    (ioJbSda),
    .oTxnBusy  (TxnBusy),
    .oTxnDone  (TxnDone),
    .oTxnRdData(TxnRdData),
    .oSclDriveLow(SclDriveLow),
    .oSdaDriveLow(SdaDriveLow)
  );

  always_comb begin
    if (TxnProtocol == PROTOCOL_I2C) begin
      SelectedTxnDone   = TxnDone;
      SelectedTxnRdData = TxnRdData;
    end else begin
      SelectedTxnDone   = SpiTxnDone;
      SelectedTxnRdData = SpiTxnRdData;
    end
  end

  assign oCmdLoad = Load;

  assign oLed    = {1'b0, LedMirror, 8'h00};
  assign oJaCs   = (TxnProtocol == PROTOCOL_SPI) ? SpiJaCs   : 1'b1;
  assign oJaMosi = (TxnProtocol == PROTOCOL_SPI) ? SpiJaMosi : 1'b0;
  assign oJaSclk = (TxnProtocol == PROTOCOL_SPI) ? SpiJaSclk : 1'b0;
  assign ioJbScl = (TxnProtocol == PROTOCOL_I2C && SclDriveLow) ? 1'b0 : 1'bz;
  assign ioJbSda = (TxnProtocol == PROTOCOL_I2C && SdaDriveLow) ? 1'b0 : 1'bz;

endmodule
