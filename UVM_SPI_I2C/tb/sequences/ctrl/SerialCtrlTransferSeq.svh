class SerialCtrlTransferSeq extends uvm_sequence #(SerialCtrlItem);
  `uvm_object_utils(SerialCtrlTransferSeq)
  SerialCtrlItem item;
  function new(input string name="SerialCtrlTransferSeq"); super.new(name); endfunction
  virtual task body();
    if(item==null) `uvm_fatal("NULL_ITEM","Transfer sequence requires an item")
    start_item(item); finish_item(item);
  endtask
endclass
