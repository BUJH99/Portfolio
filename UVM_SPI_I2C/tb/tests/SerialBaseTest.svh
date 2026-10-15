class SerialBaseTest extends uvm_test;
  `uvm_component_utils(SerialBaseTest)
  SerialEnv env;
  SerialEnvCfg cfg;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function string scenario(); return "smoke"; endfunction
  virtual function int requiredTopology(); return LOOPBACK; endfunction
  virtual function void build_phase(input uvm_phase phase);
    int topology;
    super.build_phase(phase);
    if(!uvm_config_db#(int)::get(this,"","topology",topology)) `uvm_fatal("NO_TOPOLOGY","Static topology missing")
    if(topology<0 || topology>3 || (requiredTopology()!=-1 && requiredTopology()!=topology))
      `uvm_fatal("TOPOLOGY_MISMATCH",$sformatf("test=%s elaborated topology=%0d",get_type_name(),topology))
    cfg=SerialEnvCfg::type_id::create("cfg"); cfg.topology=topology_e'(topology);
    cfg.negativeTest=scenario()=="negative";
    uvm_config_db#(SerialEnvCfg)::set(this,"env","cfg",cfg);
    env=SerialEnv::type_id::create("env",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    SerialVirtualSeq virtualSeq;
    phase.raise_objection(this);
    virtualSeq=SerialVirtualSeq::type_id::create("virtualSeq"); virtualSeq.scenario=scenario();
    virtualSeq.start(env.virtualSeqr);
    phase.drop_objection(this);
  endtask
  virtual function void report_phase(input uvm_phase phase);
    `uvm_info("SERIAL_RESULT",$sformatf("{\"spi_verified\":%0d,\"i2c_verified\":%0d,\"spi_observed\":%0d,\"i2c_observed\":%0d,\"aborted_observed\":%0d,\"aborted_expected\":%0d,\"pending\":%0d,\"expected_diagnostics\":%0d,\"unexpected_errors\":%0d,\"overlap_pairs\":%0d,\"resets\":%0d,\"switch_forward\":%0d,\"switch_reverse\":%0d,\"stimulus_controls\":%0d,\"spi_hit_mask\":%0d,\"i2c_hit_mask\":%0d}",
      env.scoreboard.spiVerified,env.scoreboard.i2cVerified,env.scoreboard.spiObserved,env.scoreboard.i2cObserved,
      env.scoreboard.abortedObserved,env.scoreboard.abortedExpected,env.scoreboard.pending(),env.scoreboard.expectedDiagnostics,
      env.scoreboard.unexpectedErrors,env.coverage.overlapPairs,env.coverage.resets,env.coverage.switchForward,
      env.coverage.switchReverse,env.coverage.controlRequests,env.spiCoverage.hitMask,env.i2cCoverage.hitMask),UVM_NONE)
  endfunction
endclass
