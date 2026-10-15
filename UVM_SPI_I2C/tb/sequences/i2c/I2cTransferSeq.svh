class I2cTransferSeq extends uvm_sequence #(I2cItem);
  `uvm_object_utils(I2cTransferSeq)
  I2cItem item;
  function new(input string name="I2cTransferSeq"); super.new(name); endfunction
  virtual task body();
    if(item==null) `uvm_fatal("NULL_ITEM","Transfer sequence requires an item")
    start_item(item); finish_item(item);
  endtask
endclass
