class SpiSlaveUnitTest extends SerialBaseTest;
  `uvm_component_utils(SpiSlaveUnitTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "spi_unit"; endfunction
  virtual function int requiredTopology(); return 1; endfunction
endclass
