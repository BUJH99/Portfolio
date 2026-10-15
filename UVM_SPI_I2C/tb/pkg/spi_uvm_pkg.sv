`timescale 1ns/1ps
package spi_uvm_pkg;
  import uvm_pkg::*;
  import serial_tb_types_pkg::*;
  `include "uvm_macros.svh"
  `include "tb/agents/spi/SpiItem.svh"
  `include "tb/agents/spi/SpiDriver.svh"
  `include "tb/agents/spi/SpiMonitor.svh"
  `include "tb/agents/spi/SpiAgent.svh"
endpackage
