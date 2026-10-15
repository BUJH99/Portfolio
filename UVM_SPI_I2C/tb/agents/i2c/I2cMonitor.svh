// Samples resolved pins, combines pointer-write/repeated-START/read into one register transaction.
class I2cMonitor extends uvm_monitor;
  `uvm_component_utils(I2cMonitor)
  virtual i2c_if vif_i2c;
  uvm_analysis_port #(I2cItem) observedAp;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); observedAp=new("observedAp",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    bit prevScl=1,prevSda=1;
    int bitCount=0;
    logic [7:0] byteShift;
    logic [7:0] bytesSeen[4];
    I2cItem frameItem;
    forever begin
      @(vif_i2c.cbMon);
      if(vif_i2c.cbMon.iRst) begin
        if(frameItem!=null) begin
          frameItem.aborted=1; frameItem.endedAt=$time;
          observedAp.write(frameItem); frameItem=null;
        end
        vif_i2c.frameActive=0; bitCount=0;
      end else if(vif_i2c.cbMon.scl && prevScl && prevSda && !vif_i2c.cbMon.sda) begin
        if(frameItem==null) begin
          frameItem=I2cItem::type_id::create("frameItem");
          frameItem.startedAt=$time; frameItem.epoch=vif_i2c.cbMon.epoch;
          frameItem.configId=vif_i2c.cbMon.configId;
          foreach(bytesSeen[idx]) bytesSeen[idx]=0;
        end else begin
          frameItem.repeatedStart=1;
          if(frameItem.byteCount!=2) frameItem.malformed=1;
        end
        bitCount=0; byteShift=0; vif_i2c.frameActive=1;
      end else if(vif_i2c.cbMon.scl && prevScl && !prevSda && vif_i2c.cbMon.sda) begin
        if(frameItem!=null) begin
          frameItem.deviceAddr=bytesSeen[0][7:1]; frameItem.regAddr=bytesSeen[1];
          frameItem.read=frameItem.repeatedStart;
          frameItem.data=frameItem.read ? 0 : bytesSeen[2]; frameItem.response=bytesSeen[3];
          if(frameItem.deviceAddr==7'h5a) begin
            if(frameItem.read) frameItem.malformed |= frameItem.byteCount!=4 || bytesSeen[2]!={frameItem.deviceAddr,1'b1};
            else frameItem.malformed |= frameItem.byteCount!=3;
          end else frameItem.malformed |= frameItem.byteCount!=1;
          frameItem.malformed |= bytesSeen[0][0]!=0;
          frameItem.endedAt=$time; observedAp.write(frameItem); frameItem=null;
        end
        vif_i2c.frameActive=0; bitCount=0;
      end else if(frameItem!=null && !prevScl && vif_i2c.cbMon.scl) begin
        if(bitCount<8) begin
          byteShift={byteShift[6:0],vif_i2c.cbMon.sda}; bitCount++;
          frameItem.malformed |= $isunknown(vif_i2c.cbMon.sda);
        end else begin
          if(frameItem.byteCount<4) begin
            bytesSeen[frameItem.byteCount]=byteShift;
            frameItem.ackBits[frameItem.byteCount]=!vif_i2c.cbMon.sda;
          end else frameItem.malformed=1;
          frameItem.byteCount++; bitCount=0; byteShift=0;
        end
      end
      prevScl=vif_i2c.cbMon.scl; prevSda=vif_i2c.cbMon.sda;
    end
  endtask
endclass
