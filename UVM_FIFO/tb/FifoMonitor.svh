class FifoMonitor extends uvm_monitor;

    `uvm_component_utils(FifoMonitor)

    protected virtual FifoIf #(FIFO_DATA_WIDTH) vif_fifo;
    uvm_analysis_port #(FifoItem) ap;

    function new(input string name = "FifoMonitor", input uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(input uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual FifoIf #(FIFO_DATA_WIDTH))::get(this, "", "vif_fifo", vif_fifo)) begin
            `uvm_fatal("FIFO_MON", "virtual interface vif_fifo was not set")
        end
    endfunction

    virtual task run_phase(input uvm_phase phase);
        FifoItem item;

        forever begin
            @(posedge vif_fifo.iClk);

            if (!vif_fifo.iRstn) begin
                continue;
            end

            item = FifoItem::type_id::create("item", this);
            // Snapshot the command and admission flags before the edge's NBA
            // updates. Observe registered data/flags only after they settle.
            item.WrEn      = vif_fifo.Wr_En;
            item.RdEn      = vif_fifo.Rd_En;
            item.Data      = vif_fifo.iData;
            item.Full      = vif_fifo.Full;
            item.Empty     = vif_fifo.Empty;
            #1ns;
            item.RData     = vif_fifo.oData;
            item.PostFull  = vif_fifo.Full;
            item.PostEmpty = vif_fifo.Empty;

            ap.write(item);

        end
    endtask

endclass
