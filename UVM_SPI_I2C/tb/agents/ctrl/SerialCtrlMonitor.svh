// Independent read-only status stream: sample every cycle, never predict from LEDs.
class SerialCtrlMonitor extends uvm_monitor;
  `uvm_component_utils(SerialCtrlMonitor)
  virtual serial_status_if vif_status;
  uvm_analysis_port #(SerialStatusItem) statusAp;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); statusAp=new("statusAp",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    SerialStatusItem statusItem;
    forever begin
      @(vif_status.cbMon);
      statusItem=SerialStatusItem::type_id::create("statusItem");
      statusItem.epoch=vif_status.cbMon.epoch;
      statusItem.inReset=vif_status.cbMon.iRst;
      statusItem.masterLed=vif_status.cbMon.masterLed[14:8];
      statusItem.spiLed=vif_status.cbMon.spiLed[6:0];
      statusItem.i2cLed=vif_status.cbMon.i2cLed[6:0];
      statusItem.sampledAt=$time;
      statusAp.write(statusItem);
    end
  endtask
endclass
