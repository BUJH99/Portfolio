// Coordinates control, SPI, and I2C sequencers. Completion barriers use wire verification counts.
class SerialVirtualSeq extends uvm_sequence;
  `uvm_object_utils(SerialVirtualSeq)
  `uvm_declare_p_sequencer(SerialVirtualSequencer)
  string scenario="smoke";
  function new(input string name="SerialVirtualSeq"); super.new(name); endfunction
  virtual task configure(input bit protocolSel,input bit [6:0] masterData,spiSwitch,i2cSwitch,
                         input bit resetRequest,output int unsigned configId);
    SerialCtrlTransferSeq ctrlSeq;
    ctrlSeq=SerialCtrlTransferSeq::type_id::create("ctrlSeq");
    ctrlSeq.item=SerialCtrlItem::type_id::create("ctrlItem");
    ctrlSeq.item.protocolSel=protocolSel; ctrlSeq.item.masterData=masterData;
    ctrlSeq.item.spiSwitch=spiSwitch; ctrlSeq.item.i2cSwitch=i2cSwitch;
    ctrlSeq.item.resetRequest=resetRequest;
    ctrlSeq.start(p_sequencer.ctrlSeqr);
    configId=ctrlSeq.item.configId;
    p_sequencer.scoreboard.coverage.controlRequests++;
  endtask
  virtual task waitCompletions(input int unsigned configId,input int unsigned target);
    for(int idx=0;idx<LP_WAIT_CYCLES;idx++) begin
      @(p_sequencer.vif_ctrl.cbMon);
      if(p_sequencer.scoreboard.completions(configId)>=target) return;
    end
    `uvm_fatal("COMPLETION_TIMEOUT",$sformatf("config=%0d expected=%0d actual=%0d",configId,target,p_sequencer.scoreboard.completions(configId)))
  endtask
  virtual task drain();
    for(int idx=0;idx<LP_WAIT_CYCLES;idx++) begin
      @(p_sequencer.vif_ctrl.cbMon);
      if(!p_sequencer.vif_ctrl.cbMon.masterBusy && !p_sequencer.vif_ctrl.cbMon.cmdLoad &&
         p_sequencer.vif_spi.csn && !p_sequencer.vif_i2c.frameActive && p_sequencer.scoreboard.pending()==0) return;
    end
    `uvm_fatal("DRAIN_TIMEOUT",$sformatf("pending=%0d",p_sequencer.scoreboard.pending()))
  endtask
  virtual task spiTxn(input bit read,input bit [7:0] regAddr,data);
    SpiTransferSeq spiSeq;
    if(p_sequencer.spiSeqr==null) `uvm_fatal("PASSIVE_SEQUENCE","SPI sequence requested in passive mode")
    spiSeq=SpiTransferSeq::type_id::create("spiSeq");
    spiSeq.item=SpiItem::type_id::create("spiItem");
    spiSeq.item.read=read; spiSeq.item.regAddr=regAddr; spiSeq.item.data=data;
    spiSeq.start(p_sequencer.spiSeqr);
  endtask
  virtual task i2cTxn(input bit read,input bit [7:0] regAddr,data,input bit [6:0] deviceAddr=7'h5a);
    I2cTransferSeq i2cSeq;
    if(p_sequencer.i2cSeqr==null) `uvm_fatal("PASSIVE_SEQUENCE","I2C sequence requested in passive mode")
    i2cSeq=I2cTransferSeq::type_id::create("i2cSeq");
    i2cSeq.item=I2cItem::type_id::create("i2cItem");
    i2cSeq.item.read=read; i2cSeq.item.regAddr=regAddr; i2cSeq.item.data=data; i2cSeq.item.deviceAddr=deviceAddr;
    i2cSeq.start(p_sequencer.i2cSeqr);
  endtask
  virtual task unitPair(input bit protocolSel,input bit [7:0] data);
    if(protocolSel) begin i2cTxn(0,1,data); i2cTxn(1,2,0); end
    else begin spiTxn(0,1,data); spiTxn(1,2,0); end
  endtask
  virtual task loopPair(input bit protocolSel,input bit [6:0] masterData,slaveData);
    int unsigned configId;
    configure(protocolSel,masterData,slaveData,slaveData,0,configId);
    waitCompletions(configId,2); drain();
  endtask
  virtual task unitScenario(input bit protocolSel);
    bit [7:0] values[5]='{0,1,8'h35,8'h7f,8'hff};
    int unsigned configId;
    foreach(values[idx]) begin
      configure(protocolSel,0,values[idx][6:0],values[idx][6:0],0,configId);
      unitPair(protocolSel,values[idx]); waitCompletions(configId,2);
    end
    // Unsupported registers read zero and writes leave LED state unchanged.
    if(protocolSel) begin i2cTxn(0,8'h03,8'h11); i2cTxn(1,8'h03,0); i2cTxn(0,1,8'h42,7'h5b); end
    else begin spiTxn(0,8'h03,8'h11); spiTxn(1,8'h03,0); end
    drain();
  endtask
  virtual task parallelScenario();
    int unsigned configId;
    configure(0,0,7'h12,7'h65,0,configId);
    fork
      begin unitPair(0,8'h55); unitPair(0,8'h55); end
      begin unitPair(1,8'h2a); unitPair(1,8'h2a); end
    join
    waitCompletions(configId,8); drain();
    if(p_sequencer.scoreboard.coverage.overlapPairs==0) `uvm_fatal("NO_OVERLAP","Independent SPI/I2C frames did not overlap")
  endtask
  virtual task repeatedScenario();
    int unsigned configId;
    if(p_sequencer.cfg.topology==LOOPBACK) begin
      repeat(2) loopPair(0,7'h35,7'h52);
      repeat(2) loopPair(1,7'h35,7'h52);
    end else begin
      configure(0,0,7'h52,7'h26,0,configId);
      fork
        if(p_sequencer.cfg.spiActive()) begin unitPair(0,8'h35); unitPair(0,8'h35); end
        if(p_sequencer.cfg.i2cActive()) begin unitPair(1,8'h49); unitPair(1,8'h49); end
      join
      waitCompletions(configId,p_sequencer.cfg.topology==DUAL_SLAVE_UNIT ? 8 : 4);
    end
    drain();
  endtask
  virtual task resetScenario();
    int unsigned configId,resetId;
    if(p_sequencer.cfg.topology==LOOPBACK) begin
      for(int protocolSel=0;protocolSel<2;protocolSel++) begin
        configure(protocolSel,7'h33,7'h24,7'h56,0,configId);
        if(protocolSel) wait(p_sequencer.vif_i2c.frameActive);
        else wait(!p_sequencer.vif_spi.csn);
        repeat(80) @(p_sequencer.vif_ctrl.cbMon);
        configure(protocolSel,7'h6a,7'h31,7'h47,1,resetId);
        waitCompletions(resetId,2); drain();
      end
    end else begin
      configure(0,0,7'h24,7'h56,0,configId);
      fork
        if(p_sequencer.cfg.spiActive()) spiTxn(0,1,8'h33);
        if(p_sequencer.cfg.i2cActive()) i2cTxn(0,1,8'h55);
        begin
          if(p_sequencer.cfg.spiActive()) wait(!p_sequencer.vif_spi.csn);
          if(p_sequencer.cfg.i2cActive()) wait(p_sequencer.vif_i2c.frameActive);
          repeat(80) @(p_sequencer.vif_ctrl.cbMon);
          configure(0,0,7'h31,7'h47,1,resetId);
        end
      join
      fork
        if(p_sequencer.cfg.spiActive()) unitPair(0,8'h6a);
        if(p_sequencer.cfg.i2cActive()) unitPair(1,8'h15);
      join
      waitCompletions(resetId,p_sequencer.cfg.topology==DUAL_SLAVE_UNIT ? 4 : 2);
    end
    drain();
    if(p_sequencer.scoreboard.abortedObserved==0 || p_sequencer.scoreboard.coverage.resets==0)
      `uvm_fatal("RESET_NOT_TESTED","Expected a partial wire frame aborted by reset")
  endtask
  virtual task negativeScenario();
    int unsigned configId;
    configure(0,0,7'h52,0,0,configId);
    p_sequencer.scoreboard.armDiagnostic("DATA_MISMATCH");
    p_sequencer.observationFilter.injectMode=1; spiTxn(0,1,8'h35); drain();
    p_sequencer.scoreboard.armDiagnostic("MISSING_FRAME");
    p_sequencer.observationFilter.injectMode=2; spiTxn(0,1,8'h35);
    repeat(20) @(p_sequencer.vif_ctrl.cbMon);
    p_sequencer.scoreboard.checkMissing(); drain();
    p_sequencer.scoreboard.armDiagnostic("UNEXPECTED_FRAME");
    p_sequencer.observationFilter.injectMode=3; spiTxn(0,1,8'h35); drain();
    unitPair(0,8'h35); drain();
    if(p_sequencer.scoreboard.expectedDiagnostics!=3) `uvm_fatal("NEGATIVE_INCOMPLETE","Corrupt/drop/duplicate must each be detected once")
  endtask
  virtual task body();
    bit [6:0] boundary[4]='{0,1,7'h35,7'h7f};
    SerialCtrlItem randItem;
    if(p_sequencer.ctrlSeqr==null) `uvm_fatal("NO_CTRL_SEQUENCER","Control sequencer is required")
    case(scenario)
      "spi_smoke": begin loopPair(0,7'h12,7'h21); loopPair(0,7'h55,7'h3a); end
      "i2c_smoke": begin loopPair(1,7'h2d,7'h4e); loopPair(1,7'h7f,7'h01); end
      "switch": begin loopPair(0,7'h12,7'h21); loopPair(1,7'h2d,7'h4e); loopPair(0,7'h55,7'h3a); loopPair(1,7'h7f,7'h01); end
      "random": repeat(16) begin
        randItem=SerialCtrlItem::type_id::create("randItem");
        if(!randItem.randomize()) `uvm_fatal("RANDOMIZE","Control randomization failed")
        loopPair(randItem.protocolSel,randItem.masterData,randItem.spiSwitch);
      end
      "coverage": for(int proto=0;proto<2;proto++) foreach(boundary[idx]) loopPair(proto,boundary[idx],boundary[idx]);
      "spi_unit": unitScenario(0);
      "i2c_unit": unitScenario(1);
      "parallel": parallelScenario();
      "repeated": repeatedScenario();
      "reset": resetScenario();
      "negative": negativeScenario();
      default: begin loopPair(0,7'h12,7'h21); loopPair(0,7'h55,7'h3a); loopPair(1,7'h2d,7'h4e); loopPair(1,7'h7f,7'h01); end
    endcase
    drain();
  endtask
endclass
