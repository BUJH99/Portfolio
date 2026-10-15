/*
[MODULE_INFO_START]
Name: TOP
Role: Basys 3 top-level wrapper for the Serial Master project
Summary:
  - Polls a remote Serial_Slave board every 10ms using either SPI or I2C depending on SW[15]
  - Mirrors the remote register readback onto LED[14:8] while routing protocol pins to PMOD JA/JB
  - Drives the I2C JB bus through open-drain SCL/SDA outputs with pull-ups
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module TOP #(
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
  inout  wire         ioJbSda
);

  SerialMasterCore #(.P_CLK_HZ(P_CLK_HZ), .P_POLL_CYCLES(P_POLL_CYCLES), .P_SPI_DIV(P_SPI_DIV), .P_I2C_DIV(P_I2C_DIV)) uCore (
    .iClk100Mhz(iClk100Mhz),
    .iRst(iRst),
    .iSw(iSw),
    .oLed(oLed),
    .oJaCs(oJaCs),
    .oJaMosi(oJaMosi),
    .iJaMiso(iJaMiso),
    .oJaSclk(oJaSclk),
    .ioJbScl(ioJbScl),
    .ioJbSda(ioJbSda),
    .oBusy(),
    .oCmdLoad()
  );
endmodule
