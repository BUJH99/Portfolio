// Passive mode creates only a monitor. Master BFM objects exist only in active mode.
class I2cAgent extends uvm_agent;
  `uvm_component_utils(I2cAgent)
  virtual i2c_if vif_i2c;
  uvm_sequencer #(I2cItem) seqr;
  I2cDriver driver;
  I2cMonitor monitor;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual i2c_if)::get(this,"","vif_i2c",vif_i2c)) `uvm_fatal("NO_VIF","i2c")
    monitor=I2cMonitor::type_id::create("monitor",this); monitor.vif_i2c=vif_i2c;
    if(is_active==UVM_ACTIVE) begin
      seqr=new("seqr",this); driver=I2cDriver::type_id::create("driver",this);
      driver.vif_i2c=vif_i2c;
    end
  endfunction
  virtual function void connect_phase(input uvm_phase phase);
    if(is_active==UVM_ACTIVE) driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
