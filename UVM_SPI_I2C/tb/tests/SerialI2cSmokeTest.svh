class SerialI2cSmokeTest extends SerialBaseTest;
  `uvm_component_utils(SerialI2cSmokeTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "i2c_smoke"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
