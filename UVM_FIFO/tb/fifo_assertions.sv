`timescale 1ns / 1ps

module FifoAssertions (
    FifoIf vif_fifo
);

    property p_flags_known;
        @(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn)
        !$isunknown({vif_fifo.Full, vif_fifo.Empty});
    endproperty

    assert_flags_known: assert property (p_flags_known)
        else $error("FIFO flags contain X/Z");

    property p_not_full_and_empty;
        @(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn)
        !(vif_fifo.Full && vif_fifo.Empty);
    endproperty

    assert_not_full_and_empty: assert property (p_not_full_and_empty)
        else $error("FIFO Full and Empty asserted together");

    property p_read_data_known;
        @(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn)
        (vif_fifo.Rd_En && !vif_fifo.Empty) |=> !$isunknown(vif_fifo.oData);
    endproperty

    assert_read_data_known: assert property (p_read_data_known)
        else $error("FIFO read data contains X/Z after an accepted read");

    cover_write_fire: cover property (@(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn) vif_fifo.Wr_En && !vif_fifo.Full);
    cover_read_fire:  cover property (@(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn) vif_fifo.Rd_En && !vif_fifo.Empty);
    cover_full:       cover property (@(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn) vif_fifo.Full);
    cover_empty:      cover property (@(posedge vif_fifo.iClk) disable iff (!vif_fifo.iRstn) vif_fifo.Empty);

endmodule
