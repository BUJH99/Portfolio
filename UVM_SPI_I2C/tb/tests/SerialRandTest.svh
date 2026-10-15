class SerialRandTest extends SerialBaseTest;
  `uvm_component_utils(SerialRandTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "random"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
