class SerialRepeatedPayloadTest extends SerialBaseTest;
  `uvm_component_utils(SerialRepeatedPayloadTest)
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "repeated"; endfunction
  virtual function int requiredTopology(); return -1; endfunction
endclass
