class SerialCtrlAgent extends uvm_agent;
  `uvm_component_utils(SerialCtrlAgent)
  virtual serial_ctrl_if vif_ctrl;
  virtual serial_status_if vif_status;
  uvm_sequencer #(SerialCtrlItem) seqr;
  SerialCtrlDriver driver;
  SerialCtrlMonitor monitor;
  function new(input string name,input uvm_component parent); super.new(name,parent); endfunction
  virtual function void build_phase(input uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual serial_ctrl_if)::get(this,"","vif_ctrl",vif_ctrl)) `uvm_fatal("NO_VIF","ctrl")
    if(!uvm_config_db#(virtual serial_status_if)::get(this,"","vif_status",vif_status)) `uvm_fatal("NO_VIF","status")
    monitor=SerialCtrlMonitor::type_id::create("monitor",this);
    monitor.vif_status=vif_status;
    if(is_active==UVM_ACTIVE) begin
      seqr=new("seqr",this); driver=SerialCtrlDriver::type_id::create("driver",this);
      driver.vif_ctrl=vif_ctrl;
    end
  endfunction
  virtual function void connect_phase(input uvm_phase phase);
    if(is_active==UVM_ACTIVE) driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
