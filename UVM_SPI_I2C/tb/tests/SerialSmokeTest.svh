class SerialSmokeTest extends SerialBaseTest;
  `uvm_component_utils(SerialSmokeTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "smoke"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
