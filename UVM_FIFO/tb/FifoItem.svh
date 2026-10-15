class FifoItem extends uvm_sequence_item;

    bit                              WrEn;
    bit                              RdEn;
    rand bit [1:0]                   Command;
    rand bit [FIFO_DATA_WIDTH-1:0]   Data;
    rand int unsigned                IdleCycles;

    logic [FIFO_DATA_WIDTH-1:0]      RData;
    logic                            Full;
    logic                            Empty;
    logic                            PostFull;
    logic                            PostEmpty;

    constraint c_idle_cycles {
        IdleCycles inside {[0:2]};
    }

    constraint c_command_mix {
        Command dist {
            2'b10 := 35,
            2'b01 := 35,
            2'b11 := 20,
            2'b00 := 10
        };
    }

    `uvm_object_utils_begin(FifoItem)
        `uvm_field_int(Command,    UVM_ALL_ON)
        `uvm_field_int(WrEn,       UVM_ALL_ON)
        `uvm_field_int(RdEn,       UVM_ALL_ON)
        `uvm_field_int(Data,       UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(IdleCycles, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(RData,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(Full,       UVM_ALL_ON)
        `uvm_field_int(Empty,      UVM_ALL_ON)
        `uvm_field_int(PostFull,   UVM_ALL_ON)
        `uvm_field_int(PostEmpty,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(input string name = "FifoItem");
        super.new(name);
    endfunction

    // Keep the original 35/35/20/10 command distribution without applying a
    // distribution constraint to a concatenation (unsupported by XSim 2025.2).
    function void post_randomize();
        WrEn = Command[1];
        RdEn = Command[0];
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "WrEn=%0b RdEn=%0b Data=0x%0h RData=0x%0h Full=%0b Empty=%0b PostFull=%0b PostEmpty=%0b IdleCycles=%0d",
            WrEn,
            RdEn,
            Data,
            RData,
            Full,
            Empty,
            PostFull,
            PostEmpty,
            IdleCycles
        );
    endfunction

endclass
