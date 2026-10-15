// Passive mode creates only a monitor. Master BFM objects exist only in active mode.
class SpiAgent extends uvm_agent;
  `uvm_component_utils(SpiAgent)
  virtual spi_if vif_spi;
  uvm_sequencer #(SpiItem) seqr;
  SpiDriver driver;
  SpiMonitor monitor;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual spi_if)::get(this,"","vif_spi",vif_spi)) `uvm_fatal("NO_VIF","spi")
    monitor=SpiMonitor::type_id::create("monitor",this); monitor.vif_spi=vif_spi;
    if(is_active==UVM_ACTIVE) begin
      seqr=new("seqr",this); driver=SpiDriver::type_id::create("driver",this);
      driver.vif_spi=vif_spi;
    end
  endfunction
  virtual function void connect_phase(input uvm_phase phase);
    if(is_active==UVM_ACTIVE) driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
