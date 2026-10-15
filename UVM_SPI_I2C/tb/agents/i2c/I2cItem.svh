// Wire observation and active-master request; response is never used as the golden value.
class I2cItem extends uvm_sequence_item;
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
  rand bit [6:0] deviceAddr;
  bit [3:0] ackBits;
  int unsigned byteCount;
  bit repeatedStart;
  constraint c_device_address { deviceAddr == 7'h5a; }
  `uvm_object_utils_begin(I2cItem)
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
    `uvm_field_int(deviceAddr,UVM_DEFAULT)
    `uvm_field_int(ackBits,UVM_DEFAULT)
    `uvm_field_int(byteCount,UVM_DEFAULT)
    `uvm_field_int(repeatedStart,UVM_DEFAULT)
  `uvm_object_utils_end
  function new(input string name="I2cItem");
    super.new(name); endpointId=1; deviceAddr=7'h5a;
  endfunction
endclass
