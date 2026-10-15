class SerialSpiSmokeTest extends SerialBaseTest;
  `uvm_component_utils(SerialSpiSmokeTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "spi_smoke"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
