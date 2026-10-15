// Test-only fault injection at the monitor/checker boundary; all normal traffic is cloned.
class SerialObservationFilter extends uvm_subscriber #(SpiItem);
  `uvm_component_utils(SerialObservationFilter)
  uvm_analysis_port #(SpiItem) observedAp;
  int injectMode=0;
  function new(input string name,input uvm_component parent);
    super.new(name,parent); observedAp=new("observedAp",this);
  endfunction
  virtual function void write(input SpiItem t);
    SpiItem copyItem,duplicateItem;
    $cast(copyItem,t.clone());
    case(injectMode)
      1: begin copyItem.data^=8'h01; observedAp.write(copyItem); end
      2: begin end
      3: begin
        observedAp.write(copyItem); $cast(duplicateItem,t.clone()); observedAp.write(duplicateItem);
      end
      default: observedAp.write(copyItem);
    endcase
    injectMode=0;
  endfunction
endclass
