/*
[MODULE_INFO_START]
Name: Window3x3LineBuffer
Role: Generate zero-padded 3x3 windows with two reusable raster line buffers.
Summary:
  - Reads each source pixel exactly once in raster order.
  - Reuses two previous image rows and six horizontal shift registers.
  - Emits one packed 3x3 window per clock after the initial line fill.
  - Flushes the right and bottom borders without additional source-memory reads.
[MODULE_INFO_END]
*/

`timescale 1ns / 1ps

module Window3x3LineBuffer #(
    parameter integer P_IMG_WIDTH  = 480,
    parameter integer P_IMG_HEIGHT = 272,
    parameter integer P_ROW_WIDTH  = 9,
    parameter integer P_COL_WIDTH  = 9,
    parameter integer P_ADDR_WIDTH = 17,
    parameter integer P_PIX_WIDTH  = 24
)(
    input  logic                         iClk,
    input  logic                         iRstn,

    output logic [P_ADDR_WIDTH-1:0]      oBramAddr,
    output logic                         oBramEn,
    input  logic [P_PIX_WIDTH-1:0]       iBramData,

    output logic                         oValid,
    output logic [(P_PIX_WIDTH*9)-1:0]   oData,
    output logic                         oFrameDone
);

    localparam integer LP_LAST_ADDR = (P_IMG_WIDTH * P_IMG_HEIGHT) - 1;

    // Each memory holds one complete previous raster row. Explicit synchronous
    // RAM wrappers keep the two 480x24 storage arrays in block RAM resources.
    logic [P_COL_WIDTH-1:0] LineReadAddr;
    logic                   LineWriteEn;
    logic [P_COL_WIDTH-1:0] LineWriteAddr;
    logic [P_PIX_WIDTH-1:0] LinePrevReadData;
    logic [P_PIX_WIDTH-1:0] LinePrev2ReadData;

    logic [P_ADDR_WIDTH-1:0] SourceAddr;
    logic                    ReadIssueDone;
    logic                    ReadValidD1;
    logic                    ReadValidD2;

    logic [P_ROW_WIDTH-1:0] ProcessRow;
    logic [P_COL_WIDTH-1:0] ProcessCol;
    logic [P_COL_WIDTH-1:0] FlushCol;
    logic                   FlushActive;
    logic                   FinalRightPending;

    // Older/Newest correspond to columns x-1/x for the row currently being
    // shifted. A new input pixel supplies column x+1 for the emitted window.
    logic [P_PIX_WIDTH-1:0] TopOlder;
    logic [P_PIX_WIDTH-1:0] TopNewest;
    logic [P_PIX_WIDTH-1:0] MidOlder;
    logic [P_PIX_WIDTH-1:0] MidNewest;
    logic [P_PIX_WIDTH-1:0] BottomOlder;
    logic [P_PIX_WIDTH-1:0] BottomNewest;

    // The frame-buffer reader and downstream writer run at a fixed raster rate.
    // Once reads start, the core therefore emits valid data without backpressure.

    assign LineWriteEn   = ReadValidD2;
    assign LineWriteAddr = ProcessCol;

    // The synchronous line RAMs are read one column ahead. Their registered
    // data then aligns with the source pixel consumed on the following edge.
    always_comb begin
        LineReadAddr = ProcessCol;
        if (FlushActive) begin
            if (FlushCol == (P_IMG_WIDTH-1)) begin
                LineReadAddr = {P_COL_WIDTH{1'b0}};
            end else begin
                LineReadAddr = FlushCol + {{(P_COL_WIDTH-1){1'b0}}, 1'b1};
            end
        end else if (ReadValidD2) begin
            if (ProcessCol == (P_IMG_WIDTH-1)) begin
                LineReadAddr = {P_COL_WIDTH{1'b0}};
            end else begin
                LineReadAddr = ProcessCol + {{(P_COL_WIDTH-1){1'b0}}, 1'b1};
            end
        end
    end

    WindowLineBufferRam #(
        .P_DEPTH      (P_IMG_WIDTH),
        .P_ADDR_WIDTH (P_COL_WIDTH),
        .P_DATA_WIDTH (P_PIX_WIDTH)
    ) uLinePrevRam (
        .iClk       (iClk),
        .iReadEn    (1'b1),
        .iReadAddr  (LineReadAddr),
        .oReadData  (LinePrevReadData),
        .iWriteEn   (LineWriteEn),
        .iWriteAddr (LineWriteAddr),
        .iWriteData (iBramData)
    );

    WindowLineBufferRam #(
        .P_DEPTH      (P_IMG_WIDTH),
        .P_ADDR_WIDTH (P_COL_WIDTH),
        .P_DATA_WIDTH (P_PIX_WIDTH)
    ) uLinePrev2Ram (
        .iClk       (iClk),
        .iReadEn    (1'b1),
        .iReadAddr  (LineReadAddr),
        .oReadData  (LinePrev2ReadData),
        .iWriteEn   (LineWriteEn),
        .iWriteAddr (LineWriteAddr),
        .iWriteData (LinePrevReadData)
    );

    always_ff @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oBramAddr         <= {P_ADDR_WIDTH{1'b0}};
            oBramEn           <= 1'b0;
            oValid            <= 1'b0;
            oData             <= {(P_PIX_WIDTH*9){1'b0}};
            oFrameDone        <= 1'b0;
            SourceAddr        <= {P_ADDR_WIDTH{1'b0}};
            ReadIssueDone     <= 1'b0;
            ReadValidD1       <= 1'b0;
            ReadValidD2       <= 1'b0;
            ProcessRow        <= {P_ROW_WIDTH{1'b0}};
            ProcessCol        <= {P_COL_WIDTH{1'b0}};
            FlushCol          <= {P_COL_WIDTH{1'b0}};
            FlushActive       <= 1'b0;
            FinalRightPending <= 1'b0;
            TopOlder          <= {P_PIX_WIDTH{1'b0}};
            TopNewest         <= {P_PIX_WIDTH{1'b0}};
            MidOlder          <= {P_PIX_WIDTH{1'b0}};
            MidNewest         <= {P_PIX_WIDTH{1'b0}};
            BottomOlder       <= {P_PIX_WIDTH{1'b0}};
            BottomNewest      <= {P_PIX_WIDTH{1'b0}};
        end else begin
            oBramEn    <= 1'b0;
            oValid     <= 1'b0;
            oFrameDone <= 1'b0;

            // The input-memory macro has one registered read stage. These two
            // tags align the address registered here with iBramData at this core.
            ReadValidD2 <= ReadValidD1;
            ReadValidD1 <= 1'b0;

            if (!ReadIssueDone && !FlushActive && !FinalRightPending) begin
                oBramAddr   <= SourceAddr;
                oBramEn     <= 1'b1;
                ReadValidD1 <= 1'b1;

                if (SourceAddr == LP_LAST_ADDR[P_ADDR_WIDTH-1:0]) begin
                    ReadIssueDone <= 1'b1;
                end else begin
                    SourceAddr <= SourceAddr + {{(P_ADDR_WIDTH-1){1'b0}}, 1'b1};
                end
            end

            if (ReadValidD2) begin
                if (ProcessCol == {P_COL_WIDTH{1'b0}}) begin
                    // Complete the right border of the preceding output row.
                    if (ProcessRow >= 2) begin
                        oData  <= {
                            {P_PIX_WIDTH{1'b0}}, BottomNewest, BottomOlder,
                            {P_PIX_WIDTH{1'b0}}, MidNewest,    MidOlder,
                            {P_PIX_WIDTH{1'b0}}, TopNewest,    TopOlder
                        };
                        oValid <= 1'b1;
                    end

                    TopOlder    <= {P_PIX_WIDTH{1'b0}};
                    TopNewest   <= (ProcessRow < 2) ?
                                   {P_PIX_WIDTH{1'b0}} : LinePrev2ReadData;
                    MidOlder    <= {P_PIX_WIDTH{1'b0}};
                    MidNewest   <= (ProcessRow < 1) ?
                                   {P_PIX_WIDTH{1'b0}} : LinePrevReadData;
                    BottomOlder <= {P_PIX_WIDTH{1'b0}};
                    BottomNewest<= iBramData;
                end else begin
                    // Packed order is {p22..p00}; Conv3x3ReluParam extracts
                    // p00 from the least-significant pixel field.
                    if (ProcessRow >= 1) begin
                        oData <= {
                            iBramData, BottomNewest, BottomOlder,
                            (ProcessRow < 1) ? {P_PIX_WIDTH{1'b0}} : LinePrevReadData,
                            MidNewest, MidOlder,
                            (ProcessRow < 2) ? {P_PIX_WIDTH{1'b0}} : LinePrev2ReadData,
                            TopNewest, TopOlder
                        };
                        oValid <= 1'b1;
                    end

                    TopOlder     <= TopNewest;
                    TopNewest    <= (ProcessRow < 2) ?
                                    {P_PIX_WIDTH{1'b0}} : LinePrev2ReadData;
                    MidOlder     <= MidNewest;
                    MidNewest    <= (ProcessRow < 1) ?
                                    {P_PIX_WIDTH{1'b0}} : LinePrevReadData;
                    BottomOlder  <= BottomNewest;
                    BottomNewest <= iBramData;
                end

                if (ProcessCol == (P_IMG_WIDTH-1)) begin
                    ProcessCol <= {P_COL_WIDTH{1'b0}};
                    if (ProcessRow == (P_IMG_HEIGHT-1)) begin
                        FlushActive <= 1'b1;
                        FlushCol    <= {P_COL_WIDTH{1'b0}};
                    end else begin
                        ProcessRow <= ProcessRow + {{(P_ROW_WIDTH-1){1'b0}}, 1'b1};
                    end
                end else begin
                    ProcessCol <= ProcessCol + {{(P_COL_WIDTH-1){1'b0}}, 1'b1};
                end
            end else if (FlushActive) begin
                // A virtual all-zero row generates bottom-padding windows.
                if (FlushCol == {P_COL_WIDTH{1'b0}}) begin
                    oData <= {
                        {P_PIX_WIDTH{1'b0}}, BottomNewest, BottomOlder,
                        {P_PIX_WIDTH{1'b0}}, MidNewest,    MidOlder,
                        {P_PIX_WIDTH{1'b0}}, TopNewest,    TopOlder
                    };
                    oValid <= 1'b1;

                    TopOlder     <= {P_PIX_WIDTH{1'b0}};
                    TopNewest    <= LinePrev2ReadData;
                    MidOlder     <= {P_PIX_WIDTH{1'b0}};
                    MidNewest    <= LinePrevReadData;
                    BottomOlder  <= {P_PIX_WIDTH{1'b0}};
                    BottomNewest <= {P_PIX_WIDTH{1'b0}};
                end else begin
                    oData <= {
                        {P_PIX_WIDTH{1'b0}}, BottomNewest, BottomOlder,
                        LinePrevReadData,  MidNewest, MidOlder,
                        LinePrev2ReadData, TopNewest, TopOlder
                    };
                    oValid <= 1'b1;

                    TopOlder     <= TopNewest;
                    TopNewest    <= LinePrev2ReadData;
                    MidOlder     <= MidNewest;
                    MidNewest    <= LinePrevReadData;
                    BottomOlder  <= BottomNewest;
                    BottomNewest <= {P_PIX_WIDTH{1'b0}};
                end

                if (FlushCol == (P_IMG_WIDTH-1)) begin
                    FlushActive       <= 1'b0;
                    FinalRightPending <= 1'b1;
                end else begin
                    FlushCol <= FlushCol + {{(P_COL_WIDTH-1){1'b0}}, 1'b1};
                end
            end else if (FinalRightPending) begin
                oData <= {
                    {P_PIX_WIDTH{1'b0}}, BottomNewest, BottomOlder,
                    {P_PIX_WIDTH{1'b0}}, MidNewest,    MidOlder,
                    {P_PIX_WIDTH{1'b0}}, TopNewest,    TopOlder
                };
                oValid     <= 1'b1;
                oFrameDone <= 1'b1;

                // Restart automatically so the input frame can be processed
                // repeatedly, matching the original generator's behavior.
                SourceAddr        <= {P_ADDR_WIDTH{1'b0}};
                ReadIssueDone     <= 1'b0;
                ReadValidD1       <= 1'b0;
                ReadValidD2       <= 1'b0;
                ProcessRow        <= {P_ROW_WIDTH{1'b0}};
                ProcessCol        <= {P_COL_WIDTH{1'b0}};
                FlushCol          <= {P_COL_WIDTH{1'b0}};
                FinalRightPending <= 1'b0;
                TopOlder          <= {P_PIX_WIDTH{1'b0}};
                TopNewest         <= {P_PIX_WIDTH{1'b0}};
                MidOlder          <= {P_PIX_WIDTH{1'b0}};
                MidNewest         <= {P_PIX_WIDTH{1'b0}};
                BottomOlder       <= {P_PIX_WIDTH{1'b0}};
                BottomNewest      <= {P_PIX_WIDTH{1'b0}};
            end
        end
    end

endmodule

/*
[MODULE_INFO_START]
Name: WindowLineBufferRam
Role: Infer one synchronous simple-dual-port block RAM for a raster line.
Summary:
  - Provides one registered read port and one write port on a common clock.
  - Uses read-first behavior when both ports access the same address.
[MODULE_INFO_END]
*/
module WindowLineBufferRam #(
    parameter integer P_DEPTH      = 480,
    parameter integer P_ADDR_WIDTH = 9,
    parameter integer P_DATA_WIDTH = 24
)(
    input  logic                    iClk,
    input  logic                    iReadEn,
    input  logic [P_ADDR_WIDTH-1:0] iReadAddr,
    output logic [P_DATA_WIDTH-1:0] oReadData,
    input  logic                    iWriteEn,
    input  logic [P_ADDR_WIDTH-1:0] iWriteAddr,
    input  logic [P_DATA_WIDTH-1:0] iWriteData
);

    (* ram_style = "block" *) logic [P_DATA_WIDTH-1:0] Memory [0:P_DEPTH-1];

    always_ff @(posedge iClk) begin
        if (iReadEn) begin
            oReadData <= Memory[iReadAddr];
        end
        if (iWriteEn) begin
            Memory[iWriteAddr] <= iWriteData;
        end
    end

endmodule
