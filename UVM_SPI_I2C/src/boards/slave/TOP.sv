/*
[MODULE_INFO_START]
Name: TOP
Role: Basys 3 top-level wrapper for the Serial Slave project
Summary:
  - Routes PMOD JA/JB pins into either the SPI or I2C slave subsystem depending on SW[15]
  - Mirrors register 0x01 writes onto LED[6:0] and returns register 0x02 read data from SW[14:8]
  - Observes the I2C JB bus through open-drain SCL/SDA lines with pull-ups
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module TOP (
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

  SerialSlaveCore  uCore (
    .iClk100Mhz(iClk100Mhz),
    .iRst(iRst),
    .iSw(iSw),
    .oLed(oLed),
    .iJaCs(iJaCs),
    .iJaMosi(iJaMosi),
    .oJaMiso(oJaMiso),
    .iJaSclk(iJaSclk),
    .ioJbScl(ioJbScl),
    .ioJbSda(ioJbSda)
  );
endmodule
