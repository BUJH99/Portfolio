class SerialCoverageClosureTest extends SerialBaseTest;
  `uvm_component_utils(SerialCoverageClosureTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "coverage"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
