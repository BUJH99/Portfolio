`timescale 1ns/1ps
package i2c_uvm_pkg;
  import uvm_pkg::*;
  import serial_tb_types_pkg::*;
  `include "uvm_macros.svh"
  `include "tb/agents/i2c/I2cItem.svh"
  `include "tb/agents/i2c/I2cDriver.svh"
  `include "tb/agents/i2c/I2cMonitor.svh"
  `include "tb/agents/i2c/I2cAgent.svh"
endpackage
