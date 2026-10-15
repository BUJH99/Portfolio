`timescale 1ns/1ps
package serial_tb_types_pkg;
  typedef enum int {LOOPBACK, SPI_SLAVE_UNIT, I2C_SLAVE_UNIT, DUAL_SLAVE_UNIT} topology_e;
  localparam int LP_SPI_ENDPOINT = 0;
  localparam int LP_I2C_ENDPOINT = 1;
  localparam int LP_HALF_CYCLES = 20;
  localparam int LP_WAIT_CYCLES = 100000;
endpackage
