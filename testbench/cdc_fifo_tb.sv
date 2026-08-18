module cdc_fifo_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================

    localparam int DATA_WIDTH = 4;
    localparam int FIFO_SIZE  = 2;


    // ============================================================
    // WRITE DOMAIN
    // ============================================================

    logic                  data_in_clk_i;
    logic                  data_in_arst_ni;

    logic [DATA_WIDTH-1:0] data_in_i;
    logic                  data_in_valid_i;
    logic                  data_in_ready_o;

    logic [FIFO_SIZE:0]    data_in_count_o;


    // ============================================================
    // READ DOMAIN
    // ============================================================

    logic                  data_out_clk_i;
    logic                  data_out_arst_ni;

    logic [DATA_WIDTH-1:0] data_out_o;
    logic                  data_out_valid_o;
    logic                  data_out_ready_i;

    logic [FIFO_SIZE:0]    data_out_count_o;


    // ============================================================
    // DUT
    // ============================================================

    cdc_fifo #(
        .DATA_WIDTH  (DATA_WIDTH),
        .FIFO_SIZE   (FIFO_SIZE),
        .SYNC_STAGES (2)
    ) dut (
        .data_in_clk_i      (data_in_clk_i),
        .data_in_arst_ni    (data_in_arst_ni),

        .data_in_i          (data_in_i),
        .data_in_valid_i    (data_in_valid_i),
        .data_in_ready_o    (data_in_ready_o),

        .data_in_count_o    (data_in_count_o),

        .data_out_clk_i     (data_out_clk_i),
        .data_out_arst_ni   (data_out_arst_ni),

        .data_out_o        (data_out_o),
        .data_out_valid_o  (data_out_valid_o),
        .data_out_ready_i  (data_out_ready_i),

        .data_out_count_o  (data_out_count_o)
    );


    // ============================================================
    // WRITE CLOCK
    //
    // Period = 10 ns
    // ============================================================

    initial begin

        data_in_clk_i = 1'b0;

        forever begin

            #5ns;
            data_in_clk_i = ~data_in_clk_i;

        end

    end


    // ============================================================
    // READ CLOCK
    //
    // Period = 14 ns
    // ============================================================

    initial begin

        data_out_clk_i = 1'b0;

        forever begin

            #7ns;
            data_out_clk_i = ~data_out_clk_i;

        end

    end


    // ============================================================
    // RESET
    // ============================================================

    initial begin

        data_in_arst_ni  = 1'b0;
        data_out_arst_ni = 1'b0;

        data_in_i        = '0;
        data_in_valid_i  = 1'b0;

        data_out_ready_i = 1'b0;

        #30ns;

        data_in_arst_ni  = 1'b1;
        data_out_arst_ni = 1'b1;

    end


    // ============================================================
    // SCOREBOARD
    // ============================================================

    logic [DATA_WIDTH-1:0] expected_queue[$];

    int write_count = 0;
    int read_count  = 0;


    // ============================================================
    // WRITE TASK
    // ============================================================

    task automatic write_fifo(
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            data_in_i       = data;
            data_in_valid_i = 1'b1;

            // Wait until FIFO can accept the data.

            while (!data_in_ready_o)
                @(posedge data_in_clk_i);

            // This clock edge performs the actual handshake.

            @(posedge data_in_clk_i);

            expected_queue.push_back(data);

            write_count++;

            $display(
                "[WRITE] time=%0t data=%0h count=%0d",
                $time,
                data,
                data_in_count_o
            );

            data_in_valid_i = 1'b0;

        end

    endtask


    // ============================================================
    // READ TASK
    // ============================================================

    task automatic read_fifo;

        logic [DATA_WIDTH-1:0] expected;

        begin

            data_out_ready_i = 1'b1;

            // Wait until FIFO has data.

            while (!data_out_valid_o)
                @(posedge data_out_clk_i);

            // Actual read handshake.

            @(posedge data_out_clk_i);

            expected = expected_queue.pop_front();

            read_count++;

            if (data_out_o !== expected) begin

                $error(
                    "[READ ERROR] time=%0t expected=%0h got=%0h",
                    $time,
                    expected,
                    data_out_o
                );

            end
            else begin

                $display(
                    "[READ ] time=%0t data=%0h count=%0d",
                    $time,
                    data_out_o,
                    data_out_count_o
                );

            end

            data_out_ready_i = 1'b0;

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // Wait until both resets are released.

        wait (
            data_in_arst_ni &&
            data_out_arst_ni
        );


        // Allow synchronizers to settle.

        repeat (3)
            @(posedge data_in_clk_i);


        // ========================================================
        // TEST 1
        // FILL ENTIRE FIFO
        // ========================================================

        $display("");
        $display("======================================");
        $display("TEST 1: FILL FIFO");
        $display("======================================");

        write_fifo(4'hA);
        write_fifo(4'hB);
        write_fifo(4'hC);
        write_fifo(4'hD);


        // ========================================================
        // TEST 1
        // READ ENTIRE FIFO
        // ========================================================

        $display("");
        $display("======================================");
        $display("TEST 1: EMPTY FIFO");
        $display("======================================");

        read_fifo();
        read_fifo();
        read_fifo();
        read_fifo();


        // ========================================================
        // WAIT FOR POINTER SYNCHRONIZATION
        // ========================================================

        repeat (5)
            @(posedge data_in_clk_i);


        // ========================================================
        // TEST 2
        // ========================================================

        $display("");
        $display("======================================");
        $display("TEST 2: WRITE AGAIN");
        $display("======================================");

        write_fifo(4'h1);
        write_fifo(4'h2);
        write_fifo(4'h3);
        write_fifo(4'h4);


        // ========================================================
        // READ AGAIN
        // ========================================================

        $display("");
        $display("======================================");
        $display("TEST 2: READ AGAIN");
        $display("======================================");

        read_fifo();
        read_fifo();
        read_fifo();
        read_fifo();


        // ========================================================
        // FINAL CHECK
        // ========================================================

        repeat (10)
            @(posedge data_in_clk_i);


        $display("");
        $display("======================================");

        if (expected_queue.size() == 0) begin

            $display("       CDC FIFO TEST PASSED");
            $display("======================================");
            $display("Writes = %0d", write_count);
            $display("Reads  = %0d", read_count);
            $display("======================================");

        end
        else begin

            $error(
                "TEST FAILED: %0d items remain",
                expected_queue.size()
            );

        end


        $finish;

    end


endmodule