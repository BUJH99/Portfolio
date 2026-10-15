// Owns configuration changes; the interface serializes reset requests.
class SerialCtrlDriver extends uvm_driver #(SerialCtrlItem);
  `uvm_component_utils(SerialCtrlDriver)
  virtual serial_ctrl_if vif_ctrl;
  uvm_analysis_port #(SerialCtrlItem) intentAp;
  function new(input string name, input uvm_component parent);
    super.new(name,parent); intentAp=new("intentAp",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    SerialCtrlItem intentItem;
    wait(vif_ctrl.initialized);
    forever begin
      seq_item_port.get_next_item(req);
      if (req.resetRequest) vif_ctrl.applyReset(12);
      // Polling pair boundary, not the gap between its write and read frames.
      begin : waitIdle
        for(int idx=0;idx<LP_WAIT_CYCLES;idx++) begin
          @(vif_ctrl.cbDrv);
          if (!vif_ctrl.cbDrv.masterBusy && !vif_ctrl.cbDrv.cmdLoad) break;
          if(idx==LP_WAIT_CYCLES-1) `uvm_fatal("CTRL_TIMEOUT","Master did not become idle")
        end
      end
      vif_ctrl.cbDrv.protocolSel <= req.protocolSel;
      vif_ctrl.cbDrv.masterData <= req.masterData;
      vif_ctrl.cbDrv.spiSwitch <= req.spiSwitch;
      vif_ctrl.cbDrv.i2cSwitch <= req.i2cSwitch;
      vif_ctrl.cbDrv.configId <= vif_ctrl.configId+1;
      @(vif_ctrl.cbMon);
      req.epoch=vif_ctrl.epoch; req.configId=vif_ctrl.configId;
      $cast(intentItem,req.clone()); intentAp.write(intentItem);
      seq_item_port.item_done();
    end
  endtask
endclass
