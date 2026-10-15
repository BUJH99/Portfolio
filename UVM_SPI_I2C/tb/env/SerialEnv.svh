class SerialEnv extends uvm_env;
  `uvm_component_utils(SerialEnv)
  SerialEnvCfg cfg;
  SerialCtrlAgent ctrlAgent;
  SpiAgent spiAgent;
  I2cAgent i2cAgent;
  SerialPredictor predictor;
  SerialScoreboard scoreboard;
  SpiCoverage spiCoverage;
  I2cCoverage i2cCoverage;
  SerialCoverage coverage;
  SerialObservationFilter observationFilter;
  SerialVirtualSequencer virtualSeqr;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(SerialEnvCfg)::get(this,"","cfg",cfg)) `uvm_fatal("NO_CFG","env")
    uvm_config_db#(uvm_active_passive_enum)::set(this,"ctrlAgent","is_active",UVM_ACTIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this,"spiAgent","is_active",cfg.spiActive()?UVM_ACTIVE:UVM_PASSIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this,"i2cAgent","is_active",cfg.i2cActive()?UVM_ACTIVE:UVM_PASSIVE);
    ctrlAgent=SerialCtrlAgent::type_id::create("ctrlAgent",this);
    spiAgent=SpiAgent::type_id::create("spiAgent",this);
    i2cAgent=I2cAgent::type_id::create("i2cAgent",this);
    predictor=SerialPredictor::type_id::create("predictor",this);
    scoreboard=SerialScoreboard::type_id::create("scoreboard",this);
    spiCoverage=SpiCoverage::type_id::create("spiCoverage",this);
    i2cCoverage=I2cCoverage::type_id::create("i2cCoverage",this);
    coverage=SerialCoverage::type_id::create("coverage",this);
    observationFilter=SerialObservationFilter::type_id::create("observationFilter",this);
    virtualSeqr=SerialVirtualSequencer::type_id::create("virtualSeqr",this);
    scoreboard.cfg=cfg; scoreboard.predictor=predictor; scoreboard.coverage=coverage;
  endfunction
  virtual function void connect_phase(input uvm_phase phase);
    ctrlAgent.driver.intentAp.connect(predictor.ctrlFifo.analysis_export);
    ctrlAgent.monitor.statusAp.connect(scoreboard.statusFifo.analysis_export);
    spiAgent.monitor.observedAp.connect(observationFilter.analysis_export);
    observationFilter.observedAp.connect(scoreboard.spiFifo.analysis_export);
    i2cAgent.monitor.observedAp.connect(scoreboard.i2cFifo.analysis_export);
    scoreboard.spiVerifiedAp.connect(spiCoverage.analysis_export);
    scoreboard.i2cVerifiedAp.connect(i2cCoverage.analysis_export);
    scoreboard.vif_ctrl=ctrlAgent.vif_ctrl;
    virtualSeqr.cfg=cfg; virtualSeqr.ctrlSeqr=ctrlAgent.seqr;
    virtualSeqr.scoreboard=scoreboard; virtualSeqr.observationFilter=observationFilter;
    virtualSeqr.vif_ctrl=ctrlAgent.vif_ctrl;
    virtualSeqr.vif_spi=spiAgent.vif_spi; virtualSeqr.vif_i2c=i2cAgent.vif_i2c;
    if(cfg.spiActive()) begin
      virtualSeqr.spiSeqr=spiAgent.seqr;
      spiAgent.driver.intentAp.connect(scoreboard.spiIntentFifo.analysis_export);
    end else if(spiAgent.driver!=null || spiAgent.seqr!=null) `uvm_fatal("PASSIVE_SPI","Passive SPI must not own a driver/sequencer")
    if(cfg.i2cActive()) begin
      virtualSeqr.i2cSeqr=i2cAgent.seqr;
      i2cAgent.driver.intentAp.connect(scoreboard.i2cIntentFifo.analysis_export);
    end else if(i2cAgent.driver!=null || i2cAgent.seqr!=null) `uvm_fatal("PASSIVE_I2C","Passive I2C must not own a driver/sequencer")
  endfunction
endclass
