module fifo (
    input  logic       arst_ni,
    input  logic       clk_i,

    // Write interface
    input  logic [3:0] data_in_i,
    input  logic       data_in_valid_i,
    output logic       data_in_ready_o,

    // Read interface
    output logic [3:0] data_out_o,
    output logic       data_out_valid_o,
    input  logic       data_out_ready_i,

    // Number of items in FIFO
    output logic [2:0] count_o
);

    // ------------------------------------------------------------
    // FIFO MEMORY
    // ------------------------------------------------------------

    // 4 entries
    // Each entry is 4 bits
    logic [3:0] mem [0:3];


    // ------------------------------------------------------------
    // POINTERS
    // ------------------------------------------------------------

    // 3 bits:
    //
    // wr_ptr[1:0] = memory address
    // wr_ptr[2]   = wrap-around bit
    //
    // Same for rd_ptr.

    logic [2:0] wr_ptr;
    logic [2:0] rd_ptr;


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

    // Write pointer and read pointer are equal
    // when there are zero items.

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
        (wr_ptr[1:0] == rd_ptr[1:0]) &&
        (wr_ptr[2]    != rd_ptr[2]);


    // ------------------------------------------------------------
    // WRITE INTERFACE
    // ------------------------------------------------------------

    // FIFO can receive data when it is not full.

    assign data_in_ready_o = !full;


    // A write happens only when:
    //
    // valid = 1
    // ready = 1

    assign write_en =
        data_in_valid_i &&
        data_in_ready_o;


    // ------------------------------------------------------------
    // READ INTERFACE
    // ------------------------------------------------------------

    // FIFO has data when it is not empty.

    assign data_out_valid_o = !empty;


    // Data at the current read pointer
    // is placed on the output.

    assign data_out_o =
        mem[rd_ptr[1:0]];


    // A read happens only when:
    //
    // valid = 1
    // ready = 1

    assign read_en =
        data_out_valid_o &&
        data_out_ready_i;


    // ------------------------------------------------------------
    // COUNT
    // ------------------------------------------------------------

    // Number of items =
    //
    // write pointer - read pointer

    assign count_o =
        wr_ptr - rd_ptr;


    // ------------------------------------------------------------
    // MEMORY WRITE
    // ------------------------------------------------------------

    always_ff @(posedge clk_i) begin

        if (write_en) begin

            mem[wr_ptr[1:0]] <= data_in_i;

        end

    end


    // ------------------------------------------------------------
    // WRITE POINTER
    // ------------------------------------------------------------

    always_ff @(posedge clk_i or negedge arst_ni) begin

        if (!arst_ni) begin

            wr_ptr <= 3'b000;

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

            rd_ptr <= 3'b000;

        end

        else if (read_en) begin

            rd_ptr <= rd_ptr + 1'b1;

        end

    end

endmodule