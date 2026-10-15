// Independent register contract. Only control intents enter this model, never DUT readback.
class SerialPredictor extends uvm_component;
  `uvm_component_utils(SerialPredictor)
  uvm_tlm_analysis_fifo #(SerialCtrlItem) ctrlFifo;
  protected SerialCtrlItem m_configs[int unsigned];
  function new(input string name,input uvm_component parent);
    super.new(name,parent); ctrlFifo=new("ctrlFifo",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    SerialCtrlItem ctrlItem,copyItem;
    forever begin
      ctrlFifo.get(ctrlItem); $cast(copyItem,ctrlItem.clone());
      m_configs[ctrlItem.configId]=copyItem;
    end
  endtask
  virtual function SerialCtrlItem configuration(input int unsigned configId);
    if(!m_configs.exists(configId)) begin
      `uvm_fatal("NO_PREDICTION",$sformatf("No control intent for configId=%0d",configId))
      return null;
    end
    return m_configs[configId];
  endfunction
  virtual function bit [7:0] readValue(input int unsigned configId,input int unsigned endpointId,input bit [7:0] regAddr);
    SerialCtrlItem cfgItem;
    cfgItem=configuration(configId);
    if(regAddr!=8'h02) return 0;
    return endpointId==0 ? {1'b0,cfgItem.spiSwitch} : {1'b0,cfgItem.i2cSwitch};
  endfunction
endclass
