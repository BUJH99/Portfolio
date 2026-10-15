class SpiTransferSeq extends uvm_sequence #(SpiItem);
  `uvm_object_utils(SpiTransferSeq)
  SpiItem item;
  function new(input string name="SpiTransferSeq"); super.new(name); endfunction
  virtual task body();
    if(item==null) `uvm_fatal("NULL_ITEM","Transfer sequence requires an item")
    start_item(item); finish_item(item);
  endtask
endclass
