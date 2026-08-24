module cdc_fifo #(
    parameter int DATA_WIDTH  = 4,
    parameter int FIFO_SIZE   = 2,
    parameter int SYNC_STAGES = 2
) (
    // ============================================================
    // WRITE DOMAIN
    // ============================================================

    input  logic                  data_in_clk_i,
    input  logic                  data_in_arst_ni,

    input  logic [DATA_WIDTH-1:0] data_in_i,
    input  logic                  data_in_valid_i,
    output logic                  data_in_ready_o,

    output logic [FIFO_SIZE:0]    data_in_count_o,


    // ============================================================
    // READ DOMAIN
    // ============================================================

    input  logic                  data_out_clk_i,
    input  logic                  data_out_arst_ni,

    output logic [DATA_WIDTH-1:0] data_out_o,
    output logic                  data_out_valid_o,
    input  logic                  data_out_ready_i,

    output logic [FIFO_SIZE:0]    data_out_count_o
);

    localparam int PTR_WIDTH = FIFO_SIZE + 1;
    localparam int DEPTH     = 1 << FIFO_SIZE;


    // ============================================================
    // FIFO MEMORY
    // ============================================================

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];


    // ============================================================
    // WRITE POINTER
    // ============================================================

    logic [PTR_WIDTH-1:0] wr_ptr_bin;
    logic [PTR_WIDTH-1:0] wr_ptr_gray;

    logic [PTR_WIDTH-1:0] wr_ptr_bin_next;
    logic [PTR_WIDTH-1:0] wr_ptr_gray_next;


    // ============================================================
    // READ POINTER
    // ============================================================

    logic [PTR_WIDTH-1:0] rd_ptr_bin;
    logic [PTR_WIDTH-1:0] rd_ptr_gray;

    logic [PTR_WIDTH-1:0] rd_ptr_bin_next;
    logic [PTR_WIDTH-1:0] rd_ptr_gray_next;


    // ============================================================
    // SYNCHRONIZERS
    // ============================================================

    // Read pointer crossing into write domain

    logic [PTR_WIDTH-1:0] rd_ptr_gray_sync1;
    logic [PTR_WIDTH-1:0] rd_ptr_gray_sync2;

    // Write pointer crossing into read domain

    logic [PTR_WIDTH-1:0] wr_ptr_gray_sync1;
    logic [PTR_WIDTH-1:0] wr_ptr_gray_sync2;


    // ============================================================
    // SYNCHRONIZED BINARY POINTERS
    // ============================================================

    logic [PTR_WIDTH-1:0] rd_ptr_bin_sync;
    logic [PTR_WIDTH-1:0] wr_ptr_bin_sync;


    // ============================================================
    // FIFO STATUS
    // ============================================================

    logic full;
    logic empty;

    logic write_en;
    logic read_en;


    // ============================================================
    // GRAY TO BINARY FUNCTION
    // ============================================================

    function automatic logic [PTR_WIDTH-1:0]
        gray_to_binary(input logic [PTR_WIDTH-1:0] gray);

        logic [PTR_WIDTH-1:0] binary;

        begin

            binary[PTR_WIDTH-1] = gray[PTR_WIDTH-1];

            for (int i = PTR_WIDTH-2; i >= 0; i--) begin

                binary[i] = binary[i+1] ^ gray[i];

            end

            return binary;

        end

    endfunction


    // ============================================================
    // WRITE HANDSHAKE
    // ============================================================

    assign data_in_ready_o = !full;

    assign write_en =
        data_in_valid_i &&
        data_in_ready_o;


    // ============================================================
    // READ HANDSHAKE
    // ============================================================

    assign data_out_valid_o = !empty;

    assign read_en =
        data_out_valid_o &&
        data_out_ready_i;


    // ============================================================
    // WRITE POINTER NEXT
    // ============================================================

    always_comb begin

        if (write_en)
            wr_ptr_bin_next = wr_ptr_bin + 1'b1;
        else
            wr_ptr_bin_next = wr_ptr_bin;

        wr_ptr_gray_next =
            (wr_ptr_bin_next >> 1) ^
             wr_ptr_bin_next;

    end


    // ============================================================
    // READ POINTER NEXT
    // ============================================================

    always_comb begin

        if (read_en)
            rd_ptr_bin_next = rd_ptr_bin + 1'b1;
        else
            rd_ptr_bin_next = rd_ptr_bin;

        rd_ptr_gray_next =
            (rd_ptr_bin_next >> 1) ^
             rd_ptr_bin_next;

    end


    // ============================================================
    // WRITE POINTER REGISTER
    // ============================================================

    always_ff @(posedge data_in_clk_i or negedge data_in_arst_ni) begin

        if (!data_in_arst_ni) begin

            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;

        end
        else begin

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

        end

    end


    // ============================================================
    // READ POINTER REGISTER
    // ============================================================

    always_ff @(posedge data_out_clk_i or negedge data_out_arst_ni) begin

        if (!data_out_arst_ni) begin

            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;

        end
        else begin

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

        end

    end


    // ============================================================
    // MEMORY WRITE
    // ============================================================

    always_ff @(posedge data_in_clk_i) begin

        if (write_en) begin

            mem[wr_ptr_bin[FIFO_SIZE-1:0]] <= data_in_i;

        end

    end


    // ============================================================
    // MEMORY READ
    // ============================================================

    assign data_out_o =
        mem[rd_ptr_bin[FIFO_SIZE-1:0]];


    // ============================================================
    // READ POINTER SYNCHRONIZER
    //
    // READ DOMAIN
    //       rd_ptr_gray
    //            |
    //            v
    //          sync1
    //            |
    //            v
    //          sync2
    //            |
    //            v
    // WRITE DOMAIN
    // ============================================================

    always_ff @(posedge data_in_clk_i or negedge data_in_arst_ni) begin

        if (!data_in_arst_ni) begin

            rd_ptr_gray_sync1 <= '0;
            rd_ptr_gray_sync2 <= '0;

        end
        else begin

            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;

        end

    end


    // ============================================================
    // WRITE POINTER SYNCHRONIZER
    //
    // WRITE DOMAIN
    //       wr_ptr_gray
    //            |
    //            v
    //          sync1
    //            |
    //            v
    //          sync2
    //            |
    //            v
    // READ DOMAIN
    // ============================================================

    always_ff @(posedge data_out_clk_i or negedge data_out_arst_ni) begin

        if (!data_out_arst_ni) begin

            wr_ptr_gray_sync1 <= '0;
            wr_ptr_gray_sync2 <= '0;

        end
        else begin

            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;

        end

    end


    // ============================================================
    // GRAY -> BINARY
    // ============================================================

    assign rd_ptr_bin_sync =
        gray_to_binary(rd_ptr_gray_sync2);

    assign wr_ptr_bin_sync =
        gray_to_binary(wr_ptr_gray_sync2);


    // ============================================================
    // EMPTY DETECTION
    // ============================================================

    assign empty =
        (rd_ptr_gray == wr_ptr_gray_sync2);


    // ============================================================
    // FULL DETECTION
    // ============================================================

    logic [PTR_WIDTH-1:0] rd_ptr_gray_full;

    always_comb begin

        rd_ptr_gray_full = rd_ptr_gray_sync2;

        rd_ptr_gray_full[PTR_WIDTH-1] =
            ~rd_ptr_gray_sync2[PTR_WIDTH-1];

        rd_ptr_gray_full[PTR_WIDTH-2] =
            ~rd_ptr_gray_sync2[PTR_WIDTH-2];

    end


    // IMPORTANT:
    //
    // Compare CURRENT write pointer here.
    //
    // This allows the final FIFO location to be written.
    //
    // After that write, wr_ptr_gray becomes equal to
    // rd_ptr_gray_full and full becomes 1.

    assign full =
        (wr_ptr_gray == rd_ptr_gray_full);


    // ============================================================
    // FIFO COUNTS
    // ============================================================

    assign data_in_count_o =
        wr_ptr_bin - rd_ptr_bin_sync;

    assign data_out_count_o =
        wr_ptr_bin_sync - rd_ptr_bin;


endmodule