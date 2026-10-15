class SerialCoverage extends uvm_component;
  `uvm_component_utils(SerialCoverage)
  int unsigned controlRequests, verified, overlapPairs, resets, switchForward, switchReverse;
  covergroup cg_serial_scenario with function sample(input bit protocolSel,input bit read,input bit overlap);
    option.per_instance=1;
    cp_protocol: coverpoint protocolSel { bins b_spi={0}; bins b_i2c={1}; }
    cp_read: coverpoint read { bins b_write={0}; bins b_read={1}; }
    cp_overlap: coverpoint overlap { bins b_serial={0}; bins b_parallel={1}; }
    cx_protocol_rw: cross cp_protocol,cp_read;
  endgroup
  function new(input string name,input uvm_component parent);
    super.new(name,parent); cg_serial_scenario=new();
  endfunction
  virtual function void sampleCompletion(input bit protocolSel,input bit read,input int unsigned overlaps);
    verified++; overlapPairs+=overlaps;
    cg_serial_scenario.sample(protocolSel,read,overlaps!=0);
  endfunction
endclass
