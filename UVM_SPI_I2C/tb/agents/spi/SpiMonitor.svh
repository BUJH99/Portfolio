// Reconstruct every wire frame, including repeated payloads and reset-aborted frames.
class SpiMonitor extends uvm_monitor;
  `uvm_component_utils(SpiMonitor)
  virtual spi_if vif_spi;
  uvm_analysis_port #(SpiItem) observedAp;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); observedAp=new("observedAp",this);
  endfunction
  virtual task run_phase(input uvm_phase phase);
    bit prevCsn=1, prevSclk=0;
    logic [15:0] txBits,rxBits;
    SpiItem frameItem;
    forever begin
      @(vif_spi.cbMon);
      if(vif_spi.cbMon.iRst) begin
        if(frameItem!=null) begin
          frameItem.aborted=1; frameItem.endedAt=$time;
          observedAp.write(frameItem); frameItem=null;
        end
      end else begin
        if(prevCsn && !vif_spi.cbMon.csn) begin
          frameItem=SpiItem::type_id::create("frameItem");
          frameItem.epoch=vif_spi.cbMon.epoch; frameItem.configId=vif_spi.cbMon.configId;
          frameItem.startedAt=$time; txBits='0; rxBits='0;
        end
        if(frameItem!=null && !vif_spi.cbMon.csn && !prevSclk && vif_spi.cbMon.sclk) begin
          txBits={txBits[14:0],vif_spi.cbMon.mosi};
          rxBits={rxBits[14:0],vif_spi.cbMon.miso}; frameItem.bitCount++;
        end
        if(frameItem!=null && !prevCsn && vif_spi.cbMon.csn) begin
          frameItem.read=txBits[15]; frameItem.regAddr={1'b0,txBits[14:8]};
          frameItem.data=txBits[7:0]; frameItem.response=rxBits[7:0];
          frameItem.endedAt=$time; frameItem.malformed=frameItem.bitCount!=16 || $isunknown({txBits,rxBits});
          observedAp.write(frameItem); frameItem=null;
        end
      end
      prevCsn=vif_spi.cbMon.csn; prevSclk=vif_spi.cbMon.sclk;
    end
  endtask
endclass
