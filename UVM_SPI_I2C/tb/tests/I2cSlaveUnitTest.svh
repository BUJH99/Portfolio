class I2cSlaveUnitTest extends SerialBaseTest;
  `uvm_component_utils(I2cSlaveUnitTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "i2c_unit"; endfunction
  virtual function int requiredTopology(); return 2; endfunction
endclass
