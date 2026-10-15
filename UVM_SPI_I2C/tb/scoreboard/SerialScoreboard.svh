// Ordered wire events are compared to requests and the independent predictor, then to DUT status.
class SerialScoreboard extends uvm_scoreboard;
  `uvm_component_utils(SerialScoreboard)
  SerialEnvCfg cfg;
  SerialPredictor predictor;
  SerialCoverage coverage;
  virtual serial_ctrl_if vif_ctrl;
  uvm_tlm_analysis_fifo #(SpiItem) spiFifo,spiIntentFifo;
  uvm_tlm_analysis_fifo #(I2cItem) i2cFifo,i2cIntentFifo;
  uvm_tlm_analysis_fifo #(SerialStatusItem) statusFifo;
  uvm_analysis_port #(SpiItem) spiVerifiedAp;
  uvm_analysis_port #(I2cItem) i2cVerifiedAp;
  int unsigned spiObserved,i2cObserved,spiVerified,i2cVerified;
  int unsigned abortedObserved,abortedExpected,expectedDiagnostics,unexpectedErrors;
  int unsigned latestEpoch,processing,addressNacks;
  int unsigned verifiedByConfig[int unsigned];
  protected SerialStatusItem m_status;
  protected bit [6:0] m_led[2];
  protected bit m_nextRead[2];
  protected time m_spiStarts[$],m_spiEnds[$],m_i2cStarts[$],m_i2cEnds[$];
  protected string m_expectedDiagnostic;
  protected int unsigned m_lastConfig;
  protected bit m_lastProtocol;
  function new(input string name,input uvm_component parent);
    super.new(name,parent);
    spiFifo=new("spiFifo",this); i2cFifo=new("i2cFifo",this);
    spiIntentFifo=new("spiIntentFifo",this); i2cIntentFifo=new("i2cIntentFifo",this);
    statusFifo=new("statusFifo",this);
    spiVerifiedAp=new("spiVerifiedAp",this); i2cVerifiedAp=new("i2cVerifiedAp",this);
  endfunction
  virtual function void diagnose(input string id,input string message);
    if(cfg.negativeTest && m_expectedDiagnostic==id) begin
      expectedDiagnostics++; m_expectedDiagnostic="";
      `uvm_info("EXPECTED_DIAGNOSTIC",{id,": ",message},UVM_LOW)
    end else begin unexpectedErrors++; `uvm_error(id,message) end
  endfunction
  virtual function void armDiagnostic(input string id);
    if(!cfg.negativeTest || m_expectedDiagnostic!="") `uvm_fatal("NEGATIVE_SETUP","Invalid expected-diagnostic setup")
    m_expectedDiagnostic=id;
  endfunction
  virtual function int pending();
    return spiIntentFifo.used()+i2cIntentFifo.used()+spiFifo.used()+i2cFifo.used()+processing;
  endfunction
  virtual function int completions(input int unsigned configId);
    return verifiedByConfig.exists(configId) ? verifiedByConfig[configId] : 0;
  endfunction
  virtual function void checkMissing();
    SpiItem spiItem; I2cItem i2cItem;
    while(spiIntentFifo.try_get(spiItem)) diagnose("MISSING_FRAME","SPI request has no completed wire frame");
    while(i2cIntentFifo.try_get(i2cItem)) diagnose("MISSING_FRAME","I2C request has no completed wire frame");
  endfunction
  virtual task collectStatus();
    SerialStatusItem statusItem;
    SpiItem spiItem; I2cItem i2cItem;
    forever begin
      statusFifo.get(statusItem); m_status=statusItem;
      if(statusItem.epoch!=latestEpoch) begin
        if(latestEpoch!=0) coverage.resets++;
        latestEpoch=statusItem.epoch;
        foreach(m_led[idx]) begin m_led[idx]=0; m_nextRead[idx]=0; end
        m_spiStarts.delete(); m_spiEnds.delete(); m_i2cStarts.delete(); m_i2cEnds.delete();
        while(spiIntentFifo.try_get(spiItem)) abortedExpected++;
        while(i2cIntentFifo.try_get(i2cItem)) abortedExpected++;
      end
    end
  endtask
  virtual function bit checkLoopIntent(input bit protocolSel,input bit read,input bit [7:0] regAddr,data,input int unsigned configId,epoch);
    SerialCtrlItem ctrlItem;
    ctrlItem=predictor.configuration(configId);
    if(ctrlItem.epoch!=epoch || ctrlItem.protocolSel!=protocolSel || read!=m_nextRead[protocolSel] ||
       regAddr!=(read ? 8'h02 : 8'h01) || data!=(read ? 0 : {1'b0,ctrlItem.masterData})) begin
      diagnose("LOOP_INTENT",$sformatf("protocol=%0d read=%0d reg=%02h data=%02h config=%0d",protocolSel,read,regAddr,data,configId));
      return 0;
    end
    m_nextRead[protocolSel]=!read;
    return 1;
  endfunction
  virtual task checkStatus(input bit protocolSel,read,input bit [7:0] regAddr,data,response,input int unsigned epoch,output bit ok);
    ok=1;
    if(!read && regAddr==1) m_led[protocolSel]=data[6:0];
    // Bounded allowance for pin synchronizers, commit pulse, and LED register.
    repeat(16) @(vif_ctrl.cbMon);
    if(epoch!=latestEpoch) begin ok=0; abortedObserved++; return; end
    if(m_status==null) begin diagnose("NO_STATUS","No status samples"); ok=0; return; end
    if((protocolSel ? m_status.i2cLed : m_status.spiLed)!==m_led[protocolSel]) begin
      diagnose("LED_MISMATCH",$sformatf("protocol=%0d expected=%02h actual=%02h",protocolSel,m_led[protocolSel],protocolSel ? m_status.i2cLed : m_status.spiLed)); ok=0;
    end
    if(cfg.topology==LOOPBACK && read && m_status.masterLed!==response[6:0]) begin
      diagnose("MASTER_LED_MISMATCH",$sformatf("expected=%02h actual=%02h",response,m_status.masterLed)); ok=0;
    end
  endtask
  virtual function void recordCompletion(input bit protocolSel,read,input int unsigned configId,input time startedAt,endedAt);
    int unsigned overlaps=0;
    // Count each pair exactly once, when its later-completing frame is verified.
    if(cfg.topology==DUAL_SLAVE_UNIT) begin
      if(protocolSel) begin
        foreach(m_spiStarts[idx]) if(startedAt<m_spiEnds[idx] && endedAt>m_spiStarts[idx]) overlaps++;
        m_i2cStarts.push_back(startedAt); m_i2cEnds.push_back(endedAt);
      end else begin
        foreach(m_i2cStarts[idx]) if(startedAt<m_i2cEnds[idx] && endedAt>m_i2cStarts[idx]) overlaps++;
        m_spiStarts.push_back(startedAt); m_spiEnds.push_back(endedAt);
      end
    end
    verifiedByConfig[configId]=completions(configId)+1;
    if(cfg.topology==LOOPBACK && m_lastConfig!=0 && configId!=m_lastConfig && protocolSel!=m_lastProtocol) begin
      if(protocolSel) coverage.switchForward++; else coverage.switchReverse++;
    end
    m_lastConfig=configId; m_lastProtocol=protocolSel;
    coverage.sampleCompletion(protocolSel,read,overlaps);
    `uvm_info("WIRE_VERIFIED",$sformatf("endpoint=%0d epoch=%0d config=%0d read=%0d start_ns=%0d end_ns=%0d overlap=%0d",
      protocolSel,latestEpoch,configId,read,startedAt,endedAt,overlaps),UVM_MEDIUM)
  endfunction
  virtual task compareSpi(input SpiItem t);
    SpiItem intentItem; bit ok;
    spiObserved++;
    if(t.aborted || t.epoch!=latestEpoch) begin
      abortedObserved++;
      `uvm_info("WIRE_ABORTED",$sformatf("SPI epoch=%0d config=%0d sampled_bits=%0d start_ns=%0d end_ns=%0d",t.epoch,t.configId,t.bitCount,t.startedAt,t.endedAt),UVM_MEDIUM)
      return;
    end
    if(t.malformed) begin diagnose("SPI_FRAME","SPI frame must contain exactly 16 known bits"); return; end
    if(cfg.topology==LOOPBACK) begin
      if(!checkLoopIntent(0,t.read,t.regAddr,t.data,t.configId,t.epoch)) return;
    end else begin
      if(!spiIntentFifo.try_get(intentItem)) begin diagnose("UNEXPECTED_FRAME","SPI completion without request"); return; end
      if(intentItem.epoch!=t.epoch || intentItem.configId!=t.configId || intentItem.read!=t.read ||
         intentItem.regAddr!=t.regAddr || intentItem.data!=t.data || t.endpointId!=0) begin
        diagnose("DATA_MISMATCH",$sformatf("SPI intent rd/reg/data/epoch/cfg=%0d/%02h/%02h/%0d/%0d observed=%0d/%02h/%02h/%0d/%0d",
          intentItem.read,intentItem.regAddr,intentItem.data,intentItem.epoch,intentItem.configId,t.read,t.regAddr,t.data,t.epoch,t.configId)); return;
      end
    end
    if(t.read && t.response!==predictor.readValue(t.configId,0,t.regAddr)) begin
      diagnose("READ_MISMATCH",$sformatf("SPI expected=%02h actual=%02h",predictor.readValue(t.configId,0,t.regAddr),t.response)); return;
    end
    checkStatus(0,t.read,t.regAddr,t.data,t.response,t.epoch,ok);
    if(!ok) return;
    spiVerified++; recordCompletion(0,t.read,t.configId,t.startedAt,t.endedAt); spiVerifiedAp.write(t);
  endtask
  virtual task compareI2c(input I2cItem t);
    I2cItem intentItem; bit ok;
    i2cObserved++;
    if(t.aborted || t.epoch!=latestEpoch) begin
      abortedObserved++;
      `uvm_info("WIRE_ABORTED",$sformatf("I2C epoch=%0d config=%0d complete_bytes=%0d start_ns=%0d end_ns=%0d",t.epoch,t.configId,t.byteCount,t.startedAt,t.endedAt),UVM_MEDIUM)
      return;
    end
    if(t.malformed) begin diagnose("I2C_FRAME",$sformatf("Unexpected byte/restart layout: count=%0d",t.byteCount)); return; end
    if(cfg.topology==LOOPBACK) begin
      if(t.deviceAddr!=7'h5a) begin diagnose("DEVICE_ADDRESS","Master addressed the wrong I2C slave"); return; end
      if(!checkLoopIntent(1,t.read,t.regAddr,t.data,t.configId,t.epoch)) return;
    end else begin
      if(!i2cIntentFifo.try_get(intentItem)) begin diagnose("UNEXPECTED_FRAME","I2C completion without request"); return; end
      if(intentItem.epoch!=t.epoch || intentItem.configId!=t.configId || intentItem.deviceAddr!=t.deviceAddr ||
         (t.deviceAddr==7'h5a && (intentItem.read!=t.read || intentItem.regAddr!=t.regAddr || (!t.read && intentItem.data!=t.data))) || t.endpointId!=1) begin
        diagnose("DATA_MISMATCH","I2C request and wire observation differ"); return;
      end
    end
    if(t.deviceAddr!=7'h5a) begin
      if(t.ackBits[0]) begin diagnose("ACK_MISMATCH","Unaddressed slave must NACK"); return; end
      checkStatus(1,1,0,0,0,t.epoch,ok);
    end else begin
      if(t.ackBits!=4'b0111) begin
        diagnose("ACK_MISMATCH",$sformatf("Unexpected ACK/NACK pattern %b",t.ackBits)); return;
      end
      if(t.read && t.response!==predictor.readValue(t.configId,1,t.regAddr)) begin
        diagnose("READ_MISMATCH",$sformatf("I2C expected=%02h actual=%02h",predictor.readValue(t.configId,1,t.regAddr),t.response)); return;
      end
      checkStatus(1,t.read,t.regAddr,t.data,t.response,t.epoch,ok);
    end
    if(!ok) return;
    if(t.deviceAddr!=7'h5a) addressNacks++;
    i2cVerified++; recordCompletion(1,t.read,t.configId,t.startedAt,t.endedAt); i2cVerifiedAp.write(t);
  endtask
  virtual task collectSpi();
    SpiItem t;
    forever begin spiFifo.get(t); processing++; compareSpi(t); processing--; end
  endtask
  virtual task collectI2c();
    I2cItem t;
    forever begin i2cFifo.get(t); processing++; compareI2c(t); processing--; end
  endtask
  virtual task run_phase(input uvm_phase phase);
    fork collectStatus(); collectSpi(); collectI2c(); join
  endtask
  virtual function void check_phase(input uvm_phase phase);
    checkMissing();
    if(pending()!=0) diagnose("PENDING_AT_END",$sformatf("pending=%0d",pending()));
    if(spiVerified+i2cVerified==0) diagnose("VACUOUS_PASS","No verified bus transactions");
    if(m_expectedDiagnostic!="") diagnose("MISSING_DIAGNOSTIC",m_expectedDiagnostic);
  endfunction
endclass
