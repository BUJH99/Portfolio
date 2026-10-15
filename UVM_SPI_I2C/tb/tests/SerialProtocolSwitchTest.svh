class SerialProtocolSwitchTest extends SerialBaseTest;
  `uvm_component_utils(SerialProtocolSwitchTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "switch"; endfunction
  virtual function int requiredTopology(); return 0; endfunction
endclass
