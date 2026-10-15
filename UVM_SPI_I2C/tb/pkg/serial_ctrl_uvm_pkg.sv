`timescale 1ns/1ps
package serial_ctrl_uvm_pkg;
  import uvm_pkg::*;
  import serial_tb_types_pkg::*;
  `include "uvm_macros.svh"
  `include "tb/agents/ctrl/SerialCtrlItem.svh"
  `include "tb/agents/ctrl/SerialCtrlDriver.svh"
  `include "tb/agents/ctrl/SerialCtrlMonitor.svh"
  `include "tb/agents/ctrl/SerialCtrlAgent.svh"
endpackage
