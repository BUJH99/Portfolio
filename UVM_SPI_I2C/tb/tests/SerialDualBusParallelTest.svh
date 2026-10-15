class SerialDualBusParallelTest extends SerialBaseTest;
  `uvm_component_utils(SerialDualBusParallelTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "parallel"; endfunction
  virtual function int requiredTopology(); return 3; endfunction
endclass
