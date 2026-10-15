// Wire observation and active-master request; response is never used as the golden value.
class SpiItem extends uvm_sequence_item;
  rand bit read;
  rand bit [7:0] regAddr;
  rand bit [7:0] data;
  logic [7:0] response;
  int unsigned endpointId;
  int unsigned epoch;
  int unsigned configId;
  time startedAt;
  time endedAt;
  bit aborted;
  bit malformed;
  int unsigned bitCount;
  constraint c_register_range { regAddr < 128; }
  `uvm_object_utils_begin(SpiItem)
    `uvm_field_int(read,UVM_DEFAULT)
    `uvm_field_int(regAddr,UVM_DEFAULT)
    `uvm_field_int(data,UVM_DEFAULT)
    `uvm_field_int(response,UVM_DEFAULT)
    `uvm_field_int(endpointId,UVM_DEFAULT)
    `uvm_field_int(epoch,UVM_DEFAULT)
    `uvm_field_int(configId,UVM_DEFAULT)
    `uvm_field_int(startedAt,UVM_DEFAULT)
    `uvm_field_int(endedAt,UVM_DEFAULT)
    `uvm_field_int(aborted,UVM_DEFAULT)
    `uvm_field_int(malformed,UVM_DEFAULT)
    `uvm_field_int(bitCount,UVM_DEFAULT)
  `uvm_object_utils_end
  function new(input string name="SpiItem");
    super.new(name); endpointId=0;
  endfunction
endclass
