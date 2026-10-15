/*
[MODULE_INFO_START]
Name: SerialSlaveCore
Role: Basys 3 top-level wrapper for the Serial Slave project
Summary:
  - Routes PMOD JA/JB pins into either the SPI or I2C slave subsystem depending on SW[15]
  - Mirrors register 0x01 writes onto LED[6:0] and returns register 0x02 read data from SW[14:8]
  - Observes the I2C JB bus through open-drain SCL/SDA lines with pull-ups
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module SerialSlaveCore (
  input  logic        iClk100Mhz,
  input  logic        iRst,
  input  logic [15:0] iSw,
  output logic [15:0] oLed,
  input  logic        iJaCs,
  input  logic        iJaMosi,
  output logic        oJaMiso,
  input  logic        iJaSclk,
  inout  wire         ioJbScl,
  inout  wire         ioJbSda
);

  import serial_protocol_pkg::*;

  protocol_e ProtocolSelRaw;
  logic       SpiTxnValid;
  logic       SpiTxnWrite;
  logic [7:0] SpiTxnAddr;
  logic [7:0] SpiTxnWdata;
  logic       TxnValid;
  logic       TxnWrite;
  logic [7:0] TxnAddr;
  logic [7:0] TxnWdata;
  logic [7:0] ReadData;
  logic [6:0] LedData;
  logic       SelectedTxnValid;
  logic       SelectedTxnWrite;
  logic [7:0] SelectedTxnAddr;
  logic [7:0] SelectedTxnWdata;
  logic       SpiJaMiso;
  logic       SdaDriveLow;

  always_comb begin
    ProtocolSelRaw = iSw[15] ? PROTOCOL_I2C : PROTOCOL_SPI;

    if (ProtocolSelRaw == PROTOCOL_I2C) begin
      SelectedTxnValid = TxnValid;
      SelectedTxnWrite = TxnWrite;
      SelectedTxnAddr  = TxnAddr;
      SelectedTxnWdata = TxnWdata;
    end else begin
      SelectedTxnValid = SpiTxnValid;
      SelectedTxnWrite = SpiTxnWrite;
      SelectedTxnAddr  = SpiTxnAddr;
      SelectedTxnWdata = SpiTxnWdata;
    end
  end

  SlaveTransactionManager uSlaveTransactionManager (
    .iClk      (iClk100Mhz),
    .iRst      (iRst),
    .iTxnValid (SelectedTxnValid),
    .iTxnWrite (SelectedTxnWrite),
    .iTxnAddr  (SelectedTxnAddr),
    .iTxnWdata (SelectedTxnWdata),
    .iSwitchData(iSw[14:8]),
    .oReadData (ReadData),
    .oLedData  (LedData)
  );

  SpiSlaveSubsystem uSpiSlaveSubsystem (
    .iClk      (iClk100Mhz),
    .iRst      (iRst),
    .iEnable   (ProtocolSelRaw == PROTOCOL_SPI),
    .iJaCs     (iJaCs),
    .iJaMosi   (iJaMosi),
    .iJaSclk   (iJaSclk),
    .iTxnReadData(ReadData),
    .oJaMiso   (SpiJaMiso),
    .oTxnValid (SpiTxnValid),
    .oTxnWrite (SpiTxnWrite),
    .oTxnAddr  (SpiTxnAddr),
    .oTxnWdata (SpiTxnWdata)
  );

  I2cSlaveSubsystem uI2cSlaveSubsystem (
    .iClk      (iClk100Mhz),
    .iRst      (iRst),
    .iEnable   (ProtocolSelRaw == PROTOCOL_I2C),
    .iJbScl    (ioJbScl),
    .iSdaIn    (ioJbSda),
    .iTxnReadData(ReadData),
    .oSdaDriveLow(SdaDriveLow),
    .oTxnValid (TxnValid),
    .oTxnWrite (TxnWrite),
    .oTxnAddr  (TxnAddr),
    .oTxnWdata (TxnWdata)
  );

  assign oLed    = {9'h000, LedData};
  assign oJaMiso = (ProtocolSelRaw == PROTOCOL_SPI) ? SpiJaMiso : 1'b0;
  assign ioJbSda = (ProtocolSelRaw == PROTOCOL_I2C && SdaDriveLow) ? 1'b0 : 1'bz;

endmodule
