// Single-byte 7-bit-address master BFM, with repeated START for register reads.
class I2cDriver extends uvm_driver #(I2cItem);
  `uvm_component_utils(I2cDriver)
  virtual i2c_if vif_i2c;
  uvm_analysis_port #(I2cItem) intentAp;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); intentAp=new("intentAp",this);
  endfunction
  virtual task halfCycle(); repeat(LP_HALF_CYCLES) @(vif_i2c.cbDrv); endtask
  virtual task releaseClock();
    vif_i2c.cbDrv.sclDriveLow<=0;
    for(int idx=0;idx<LP_WAIT_CYCLES;idx++) begin
      @(vif_i2c.cbDrv);
      if(vif_i2c.cbDrv.scl===1'b1) return;
    end
    `uvm_fatal("I2C_STRETCH_TIMEOUT","SCL remained low")
  endtask
  virtual task startBus();
    vif_i2c.cbDrv.sdaDriveLow<=0; halfCycle(); releaseClock(); halfCycle();
    vif_i2c.cbDrv.sdaDriveLow<=1; halfCycle();
    vif_i2c.cbDrv.sclDriveLow<=1; halfCycle();
  endtask
  virtual task stopBus();
    vif_i2c.cbDrv.sclDriveLow<=1; vif_i2c.cbDrv.sdaDriveLow<=1; halfCycle();
    releaseClock(); halfCycle(); vif_i2c.cbDrv.sdaDriveLow<=0; halfCycle();
  endtask
  virtual task sendByte(input bit [7:0] value,output bit ack);
    for(int idx=7;idx>=0;idx--) begin
      vif_i2c.cbDrv.sdaDriveLow<=!value[idx]; halfCycle();
      releaseClock(); halfCycle(); vif_i2c.cbDrv.sclDriveLow<=1; halfCycle();
    end
    vif_i2c.cbDrv.sdaDriveLow<=0; halfCycle(); releaseClock(); halfCycle();
    ack=!vif_i2c.cbDrv.sda;
    vif_i2c.cbDrv.sclDriveLow<=1; halfCycle();
  endtask
  virtual task readByte();
    vif_i2c.cbDrv.sdaDriveLow<=0;
    repeat(8) begin halfCycle(); releaseClock(); halfCycle(); vif_i2c.cbDrv.sclDriveLow<=1; halfCycle(); end
    // Single-byte read ends with a master NACK, then STOP.
    halfCycle(); releaseClock(); halfCycle(); vif_i2c.cbDrv.sclDriveLow<=1; halfCycle();
  endtask
  virtual task driveFrame(input I2cItem item);
    bit ack;
    @(vif_i2c.cbDrv); startBus(); sendByte({item.deviceAddr,1'b0},ack);
    if(ack) begin
      sendByte(item.regAddr,ack);
      if(item.read) begin
        startBus(); sendByte({item.deviceAddr,1'b1},ack); readByte();
      end else sendByte(item.data,ack);
    end
    stopBus();
  endtask
  virtual task run_phase(input uvm_phase phase);
    I2cItem intentItem;
    forever begin
      seq_item_port.get_next_item(req); wait(!vif_i2c.iRst);
      req.epoch=vif_i2c.epoch; req.configId=vif_i2c.configId;
      $cast(intentItem,req.clone()); intentAp.write(intentItem);
      fork
        driveFrame(req);
        begin @(posedge vif_i2c.iRst); req.aborted=1; end
      join_any
      disable fork;
      @(vif_i2c.cbDrv); vif_i2c.cbDrv.sclDriveLow<=0; vif_i2c.cbDrv.sdaDriveLow<=0;
      seq_item_port.item_done();
    end
  endtask
endclass
