module fifo #(
    parameter int DATA_WIDTH = 4,
    parameter int FIFO_DEPTH = 4
) (
    input  logic                  arst_ni,
    input  logic                  clk_i,

    // Write interface
    input  logic [DATA_WIDTH-1:0] data_in_i,
    input  logic                  data_in_valid_i,
    output logic                  data_in_ready_o,

    // Read interface
    output logic [DATA_WIDTH-1:0] data_out_o,
    output logic                  data_out_valid_o,
    input  logic                  data_out_ready_i,

    // Number of items in FIFO
    output logic [$clog2(FIFO_DEPTH+1)-1:0] count_o
);

    // ------------------------------------------------------------
    // PARAMETERS
    // ------------------------------------------------------------

    localparam int ADDR_WIDTH  = $clog2(FIFO_DEPTH);
    localparam int PTR_WIDTH   = ADDR_WIDTH + 1;
    localparam int COUNT_WIDTH = $clog2(FIFO_DEPTH + 1);


    // ------------------------------------------------------------
    // FIFO MEMORY
    // ------------------------------------------------------------

    // FIFO_DEPTH entries
    // Each entry is DATA_WIDTH bits

    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];


    // ------------------------------------------------------------
    // POINTERS
    // ------------------------------------------------------------

    // ADDR_WIDTH lower bits = memory address
    //
    // MSB = wrap-around bit

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;


    // ------------------------------------------------------------
    // INTERNAL SIGNALS
    // ------------------------------------------------------------

    logic write_en;
    logic read_en;

    logic empty;
    logic full;


    // ------------------------------------------------------------
    // EMPTY
    // ------------------------------------------------------------

    assign empty = (wr_ptr == rd_ptr);


    // ------------------------------------------------------------
    // FULL
    // ------------------------------------------------------------

    // FIFO is full when:
    //
    // lower address bits are equal
    // AND
    // wrap-around bits are different.

    assign full =
        (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
        (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);


    // ------------------------------------------------------------
    // READ HANDSHAKE
    // ------------------------------------------------------------

    // FIFO contains data when it is not empty.
    //
    // During reset, valid is forced to 0.

    assign data_out_valid_o =
        arst_ni && !empty;


    // ------------------------------------------------------------
    // READ ENABLE
    // ------------------------------------------------------------

    // A read happens when:
    //
    // FIFO has valid data
    // AND
    // receiver is ready

    assign read_en =
        data_out_valid_o &&
        data_out_ready_i;


    // ------------------------------------------------------------
    // WRITE INTERFACE
    // ------------------------------------------------------------

    // Normally:
    //
    //     ready = !full
    //
    // But if FIFO is full and a read happens
    // in the same cycle, the read frees one location.
    //
    // Therefore we allow a write when:
    //
    //     !full || read_en
    //
    // During reset, ready is forced to 0.

    assign data_in_ready_o =
        arst_ni &&
        (!full || read_en);


    // ------------------------------------------------------------
    // WRITE ENABLE
    // ------------------------------------------------------------

    // A write happens when:
    //
    // valid = 1
    // AND
    // ready = 1

    assign write_en =
        data_in_valid_i &&
        data_in_ready_o;


    // ------------------------------------------------------------
    // DATA OUTPUT
    // ------------------------------------------------------------

    // During reset:
    //
    //     data_out_o = 0
    //
    // Otherwise:
    //
    //     output the memory location
    //     pointed to by rd_ptr.

    assign data_out_o =
        arst_ni ?
        mem[rd_ptr[ADDR_WIDTH-1:0]] :
        '0;


    // ------------------------------------------------------------
    // COUNT
    // ------------------------------------------------------------

    // Number of entries currently stored:
    //
    //     write pointer - read pointer
    //
    // During reset:
    //
    //     count = 0

    assign count_o =
        arst_ni ?
        (wr_ptr - rd_ptr) :
        '0;


    // ------------------------------------------------------------
    // MEMORY WRITE
    // ------------------------------------------------------------

    always_ff @(posedge clk_i) begin

        if (write_en) begin

            mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in_i;

        end

    end


    // ------------------------------------------------------------
    // WRITE POINTER
    // ------------------------------------------------------------

    always_ff @(posedge clk_i or negedge arst_ni) begin

        if (!arst_ni) begin

            wr_ptr <= '0;

        end

        else if (write_en) begin

            wr_ptr <= wr_ptr + 1'b1;

        end

    end


    // ------------------------------------------------------------
    // READ POINTER
    // ------------------------------------------------------------

    always_ff @(posedge clk_i or negedge arst_ni) begin

        if (!arst_ni) begin

            rd_ptr <= '0;

        end

        else if (read_en) begin

            rd_ptr <= rd_ptr + 1'b1;

        end

    end

endmodule