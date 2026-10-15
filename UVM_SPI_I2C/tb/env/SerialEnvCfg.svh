class SerialEnvCfg extends uvm_object;
  `uvm_object_utils(SerialEnvCfg)
  topology_e topology=LOOPBACK;
  bit negativeTest=0;
  function new(input string name="SerialEnvCfg"); super.new(name); endfunction
  virtual function bit spiActive(); return topology inside {SPI_SLAVE_UNIT,DUAL_SLAVE_UNIT}; endfunction
  virtual function bit i2cActive(); return topology inside {I2C_SLAVE_UNIT,DUAL_SLAVE_UNIT}; endfunction
endclass
