// Only scoreboard-verified completions reach this subscriber.
class I2cCoverage extends uvm_subscriber #(I2cItem);
  `uvm_component_utils(I2cCoverage)
  int unsigned completed;
  bit [9:0] hitMask;
  covergroup cg_i2c_transaction with function sample(input bit read,input bit [7:0] payload);
    option.per_instance=1;
    cp_read: coverpoint read { bins b_write={0}; bins b_read={1}; }
    cp_payload: coverpoint payload {
      bins b_zero={0}; bins b_one={1}; bins b_mid={[2:126]};
      bins b_max={127}; bins b_upper={[128:255]};
    }
    cx_rw_payload: cross cp_read,cp_payload {
      ignore_bins b_read_upper = binsof(cp_read.b_read) && binsof(cp_payload.b_upper);
    }
  endgroup
  function new(input string name,input uvm_component parent);
    super.new(name,parent); cg_i2c_transaction=new();
  endfunction
  virtual function void write(input I2cItem t);
    bit [7:0] payload; int bucket;
    if(t.deviceAddr!=7'h5a || t.regAddr!=(t.read ? 2 : 1)) return;
    payload=t.read ? t.response : t.data;
    bucket=payload==0 ? 0 : payload==1 ? 1 : payload==127 ? 3 : payload>127 ? 4 : 2;
    hitMask[(t.read ? 5 : 0)+bucket]=1;
    cg_i2c_transaction.sample(t.read,payload); completed++;
  endfunction
endclass
