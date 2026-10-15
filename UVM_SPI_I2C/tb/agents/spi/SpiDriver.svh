// Mode-0, MSB-first, 16-bit master BFM. Only CSn/SCLK/MOSI are driven.
class SpiDriver extends uvm_driver #(SpiItem);
  `uvm_component_utils(SpiDriver)
  virtual spi_if vif_spi;
  uvm_analysis_port #(SpiItem) intentAp;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); intentAp=new("intentAp",this);
  endfunction
  virtual task halfCycle(); repeat(LP_HALF_CYCLES) @(vif_spi.cbDrv); endtask
  virtual task driveFrame(input SpiItem item);
    bit [15:0] bits;
    bits={item.read,item.regAddr[6:0],item.data};
    @(vif_spi.cbDrv);
    vif_spi.cbDrv.driveCsn<=0; vif_spi.cbDrv.driveSclk<=0;
    for(int idx=15;idx>=0;idx--) begin
      vif_spi.cbDrv.driveMosi<=bits[idx]; halfCycle();
      vif_spi.cbDrv.driveSclk<=1; halfCycle();
      vif_spi.cbDrv.driveSclk<=0;
    end
    halfCycle(); vif_spi.cbDrv.driveCsn<=1; halfCycle();
  endtask
  virtual task run_phase(input uvm_phase phase);
    SpiItem intentItem;
    // Initialize the clocking outputs as well as the interface's idle values.
    // Otherwise a simulator's initial clocking value of zero can swallow the first CS assertion.
    @(vif_spi.cbDrv);
    vif_spi.cbDrv.driveCsn<=1; vif_spi.cbDrv.driveSclk<=0; vif_spi.cbDrv.driveMosi<=0;
    forever begin
      seq_item_port.get_next_item(req);
      wait(!vif_spi.iRst);
      req.epoch=vif_spi.epoch; req.configId=vif_spi.configId;
      $cast(intentItem,req.clone()); intentAp.write(intentItem);
      fork
        driveFrame(req);
        begin @(posedge vif_spi.iRst); req.aborted=1; end
      join_any
      disable fork;
      @(vif_spi.cbDrv);
      vif_spi.cbDrv.driveCsn<=1; vif_spi.cbDrv.driveSclk<=0; vif_spi.cbDrv.driveMosi<=0;
      seq_item_port.item_done();
    end
  endtask
endclass
