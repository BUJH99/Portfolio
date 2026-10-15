/*
[MODULE_INFO_START]
Name: serial_protocol_pkg
Role: Shared package for the Serial Master and Serial Slave projects
Summary:
  - Defines protocol constants and register addresses used by the SPI/I2C communication blocks
  - Keeps transaction-related types in one place so duplicated Master/Slave projects stay protocol-compatible
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

package serial_protocol_pkg;

  localparam int unsigned LP_CLK_HZ         = 100_000_000;
  localparam int unsigned LP_POLL_CYCLES    = 1_000_000;
  localparam int unsigned LP_SPI_DIV        = 100;
  localparam int unsigned LP_I2C_DIV        = 4000;
  localparam int unsigned LP_SPI_FRAME_BITS = 16;
  localparam int unsigned LP_I2C_BYTE_BITS  = 8;

  localparam logic [7:0] LP_REG_WRITE = 8'h01;
  localparam logic [7:0] LP_REG_READ  = 8'h02;
  localparam logic [6:0] LP_I2C_DEV_ADDR = 7'h5A;

  typedef enum logic {
    PROTOCOL_SPI = 1'b0,
    PROTOCOL_I2C = 1'b1
  } protocol_e;

endpackage
