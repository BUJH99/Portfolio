// Applied configuration intent. configId separates even identical consecutive requests.
class SerialCtrlItem extends uvm_sequence_item;
  rand bit protocolSel;
  rand bit [6:0] masterData, spiSwitch, i2cSwitch;
  bit resetRequest;
  int unsigned epoch, configId;
  `uvm_object_utils_begin(SerialCtrlItem)
    `uvm_field_int(protocolSel,UVM_DEFAULT)
    `uvm_field_int(masterData,UVM_DEFAULT)
    `uvm_field_int(spiSwitch,UVM_DEFAULT)
    `uvm_field_int(i2cSwitch,UVM_DEFAULT)
    `uvm_field_int(resetRequest,UVM_DEFAULT)
    `uvm_field_int(epoch,UVM_DEFAULT)
    `uvm_field_int(configId,UVM_DEFAULT)
  `uvm_object_utils_end
  function new(input string name="SerialCtrlItem"); super.new(name); endfunction
endclass

class SerialStatusItem extends uvm_sequence_item;
  int unsigned epoch;
  bit inReset;
  logic [6:0] masterLed, spiLed, i2cLed;
  time sampledAt;
  `uvm_object_utils_begin(SerialStatusItem)
    `uvm_field_int(epoch,UVM_DEFAULT)
    `uvm_field_int(inReset,UVM_DEFAULT)
    `uvm_field_int(masterLed,UVM_DEFAULT)
    `uvm_field_int(spiLed,UVM_DEFAULT)
    `uvm_field_int(i2cLed,UVM_DEFAULT)
    `uvm_field_int(sampledAt,UVM_DEFAULT)
  `uvm_object_utils_end
  function new(input string name="SerialStatusItem"); super.new(name); endfunction
endclass
