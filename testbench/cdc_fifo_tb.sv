module cdc_fifo_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================

    localparam int DATA_WIDTH = 4;
    localparam int FIFO_SIZE  = 2;
    localparam int FIFO_DEPTH = 2 ** FIFO_SIZE;


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
    // TEST VARIABLES
    // ============================================================

    int tests_passed;
    int tests_failed;

    logic [DATA_WIDTH-1:0] read_data;


    // ============================================================
    // SCOREBOARD
    // ============================================================

    logic [DATA_WIDTH-1:0] expected_queue[$];

    int write_count;
    int read_count;


    // ============================================================
    // CHECK TASK
    // ============================================================

    task automatic check(
        input string test_name,
        input logic  condition
    );

        if (condition) begin

            $display(
                "[PASS] %s",
                test_name
            );

            tests_passed++;

        end

        else begin

            $display(
                "[FAIL] %s",
                test_name
            );

            tests_failed++;

        end

    endtask


    // ============================================================
    // WAIT FOR CDC SYNCHRONIZATION
    //
    // Pointer information takes multiple clock cycles to cross
    // between the write and read clock domains.
    // ============================================================

    task automatic wait_cdc_sync;

        repeat (5)
            @(posedge data_in_clk_i);

        repeat (5)
            @(posedge data_out_clk_i);

    endtask


    // ============================================================
    // WRITE TASK
    // ============================================================

    task automatic write_fifo(
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            data_in_i       = data;
            data_in_valid_i = 1'b1;

            // Wait until write side says it can accept data.

            while (!data_in_ready_o)
                @(posedge data_in_clk_i);

            // Write handshake occurs here.

            @(posedge data_in_clk_i);

            #1;

            expected_queue.push_back(data);

            write_count++;

            $display(
                "[WRITE] time=%0t data=%0h write_count=%0d",
                $time,
                data,
                write_count
            );

            data_in_valid_i = 1'b0;
            data_in_i       = '0;

        end

    endtask


    // ============================================================
    // READ TASK
    // ============================================================

    task automatic read_fifo(
        output logic [DATA_WIDTH-1:0] value
    );

        logic [DATA_WIDTH-1:0] expected;

        begin

            data_out_ready_i = 1'b1;

            // Wait until data becomes visible in read domain.

            while (!data_out_valid_o)
                @(posedge data_out_clk_i);

            // Data must be captured BEFORE the read clock edge,
            // because the FIFO may update data_out_o after the
            // handshake.

            #1;

            value = data_out_o;

            expected = expected_queue.pop_front();

            check(
                $sformatf(
                    "Read data expected %0h got %0h",
                    expected,
                    value
                ),
                value === expected
            );

            read_count++;

            // Read handshake.

            @(posedge data_out_clk_i);

            #1;

            $display(
                "[READ ] time=%0t data=%0h read_count=%0d",
                $time,
                value,
                read_count
            );

            data_out_ready_i = 1'b0;

        end

    endtask


    // ============================================================
    // RESET TASK
    // ============================================================

    task automatic reset_fifo;

        begin

            data_in_arst_ni  = 1'b0;
            data_out_arst_ni = 1'b0;

            data_in_valid_i  = 1'b0;
            data_out_ready_i = 1'b0;

            data_in_i        = '0;

            // Allow asynchronous reset to propagate.

            #1;

            check(
                "Write ready is 0 during reset",
                data_in_ready_o == 1'b0
            );

            check(
                "Read valid is 0 during reset",
                data_out_valid_o == 1'b0
            );

            check(
                "Read data is 0 during reset",
                data_out_o == '0
            );

            check(
                "Write count is 0 during reset",
                data_in_count_o == 0
            );

            check(
                "Read count is 0 during reset",
                data_out_count_o == 0
            );

            // Keep reset active for several clocks in both domains.

            repeat (3)
                @(posedge data_in_clk_i);

            repeat (3)
                @(posedge data_out_clk_i);

            #1;

            check(
                "Write ready remains 0 during reset",
                data_in_ready_o == 1'b0
            );

            check(
                "Read valid remains 0 during reset",
                data_out_valid_o == 1'b0
            );

            check(
                "Write count remains 0 during reset",
                data_in_count_o == 0
            );

            check(
                "Read count remains 0 during reset",
                data_out_count_o == 0
            );

            // Release both resets.

            data_in_arst_ni  = 1'b1;
            data_out_arst_ni = 1'b1;

            // Allow CDC synchronizers to settle.

            wait_cdc_sync;

            check(
                "Write side ready after reset",
                data_in_ready_o == 1'b1
            );

            check(
                "Read side empty after reset",
                data_out_valid_o == 1'b0
            );

            check(
                "Write count is zero after reset",
                data_in_count_o == 0
            );

            check(
                "Read count is zero after reset",
                data_out_count_o == 0
            );

        end

    endtask


    // ============================================================
    // TEST 1
    // RESET TEST
    // ============================================================

    task automatic test_reset;

        begin

            $display("");
            $display("========================================");
            $display("TEST 1: RESET");
            $display("========================================");

            reset_fifo;

        end

    endtask


    // ============================================================
    // TEST 2
    // SINGLE WRITE AND READ
    // ============================================================

    task automatic test_single_write_read;

        begin

            $display("");
            $display("========================================");
            $display("TEST 2: SINGLE WRITE AND READ");
            $display("========================================");

            write_fifo(4'hA);

            check(
                "Write count becomes 1",
                data_in_count_o == 1
            );

            // Give pointer time to cross clock domains.

            wait_cdc_sync;

            check(
                "Read side sees valid data",
                data_out_valid_o == 1'b1
            );

            read_fifo(read_data);

            check(
                "Single read data is A",
                read_data == 4'hA
            );

            wait_cdc_sync;

            check(
                "Read side becomes empty",
                data_out_valid_o == 1'b0
            );

            check(
                "Read count becomes zero",
                data_out_count_o == 0
            );

        end

    endtask


    // ============================================================
    // TEST 3
    // FIFO ORDER
    // ============================================================

    task automatic test_fifo_order;

        begin

            $display("");
            $display("========================================");
            $display("TEST 3: FIFO ORDER");
            $display("========================================");

            write_fifo(4'h1);
            write_fifo(4'h2);
            write_fifo(4'h3);

            check(
                "Write count is 3",
                data_in_count_o == 3
            );

            wait_cdc_sync;

            read_fifo(read_data);

            check(
                "First value is 1",
                read_data == 4'h1
            );

            read_fifo(read_data);

            check(
                "Second value is 2",
                read_data == 4'h2
            );

            read_fifo(read_data);

            check(
                "Third value is 3",
                read_data == 4'h3
            );

            wait_cdc_sync;

            check(
                "FIFO is empty after ordered reads",
                data_out_valid_o == 1'b0
            );

        end

    endtask


    // ============================================================
    // TEST 4
    // FILL FIFO
    // ============================================================

    task automatic test_fill_fifo;

        begin

            $display("");
            $display("========================================");
            $display("TEST 4: FILL FIFO");
            $display("========================================");

            write_fifo(4'h4);
            write_fifo(4'h5);
            write_fifo(4'h6);
            write_fifo(4'h7);

            check(
                "Write count is FIFO depth",
                data_in_count_o == FIFO_DEPTH
            );

            check(
                "FIFO ready is 0 when full",
                data_in_ready_o == 1'b0
            );

            wait_cdc_sync;

            check(
                "Read side sees valid data when full",
                data_out_valid_o == 1'b1
            );

            check(
                "Read side count is FIFO depth",
                data_out_count_o == FIFO_DEPTH
            );

        end

    endtask


    // ============================================================
    // TEST 5
    // CANNOT WRITE WHEN FULL
    // ============================================================

    task automatic test_blocked_write;

        begin

            $display("");
            $display("========================================");
            $display("TEST 5: BLOCKED WRITE WHEN FULL");
            $display("========================================");

            // FIFO should already be full from TEST 4.

            check(
                "FIFO is full before blocked write",
                data_in_count_o == FIFO_DEPTH
            );

            data_in_i       = 4'hF;
            data_in_valid_i = 1'b1;

            #1;

            check(
                "Ready is 0 while FIFO is full",
                data_in_ready_o == 1'b0
            );

            // Wait one write clock.

            @(posedge data_in_clk_i);

            #1;

            check(
                "Write count remains full",
                data_in_count_o == FIFO_DEPTH
            );

            data_in_valid_i = 1'b0;
            data_in_i       = '0;

        end

    endtask


    // ============================================================
    // TEST 6
    // READ / EMPTY FIFO
    // ============================================================

    task automatic test_empty_fifo;

        begin

            $display("");
            $display("========================================");
            $display("TEST 6: EMPTY FIFO");
            $display("========================================");

            read_fifo(read_data);

            check(
                "Drain value is 4",
                read_data == 4'h4
            );

            read_fifo(read_data);

            check(
                "Drain value is 5",
                read_data == 4'h5
            );

            read_fifo(read_data);

            check(
                "Drain value is 6",
                read_data == 4'h6
            );

            read_fifo(read_data);

            check(
                "Drain value is 7",
                read_data == 4'h7
            );

            wait_cdc_sync;

            check(
                "Read count becomes zero",
                data_out_count_o == 0
            );

            check(
                "Read valid is 0 when empty",
                data_out_valid_o == 1'b0
            );

            // Try to read while empty.

            data_out_ready_i = 1'b1;

            #1;

            check(
                "Valid remains 0 while empty",
                data_out_valid_o == 1'b0
            );

            @(posedge data_out_clk_i);

            #1;

            check(
                "Read count remains zero",
                data_out_count_o == 0
            );

            data_out_ready_i = 1'b0;

        end

    endtask


    // ============================================================
    // TEST 7
    // POINTER WRAP-AROUND
    // ============================================================

    task automatic test_pointer_wrap;

        begin

            $display("");
            $display("========================================");
            $display("TEST 7: POINTER WRAP-AROUND");
            $display("========================================");

            // First fill and empty FIFO.

            write_fifo(4'h8);
            write_fifo(4'h9);
            write_fifo(4'hA);
            write_fifo(4'hB);

            wait_cdc_sync;

            read_fifo(read_data);

            check(
                "Wrap read 1 is 8",
                read_data == 4'h8
            );

            read_fifo(read_data);

            check(
                "Wrap read 2 is 9",
                read_data == 4'h9
            );

            read_fifo(read_data);

            check(
                "Wrap read 3 is A",
                read_data == 4'hA
            );

            read_fifo(read_data);

            check(
                "Wrap read 4 is B",
                read_data == 4'hB
            );

            wait_cdc_sync;

            // Write again after pointers have wrapped.

            write_fifo(4'hC);
            write_fifo(4'hD);

            check(
                "Write count is 2 after pointer wrap",
                data_in_count_o == 2
            );

            wait_cdc_sync;

            read_fifo(read_data);

            check(
                "Wrap-around new value 1 is C",
                read_data == 4'hC
            );

            read_fifo(read_data);

            check(
                "Wrap-around new value 2 is D",
                read_data == 4'hD
            );

        end

    endtask


    // ============================================================
    // TEST 8
    // SIMULTANEOUS READ AND WRITE
    // ============================================================

    task automatic test_simultaneous_read_write;

        logic [DATA_WIDTH-1:0] expected;

        begin

            $display("");
            $display("========================================");
            $display("TEST 8: SIMULTANEOUS READ AND WRITE");
            $display("========================================");

            // Put one value into FIFO.

            write_fifo(4'hE);

            wait_cdc_sync;

            check(
                "Read side sees E",
                data_out_valid_o == 1'b1
            );

            // Request read.

            data_out_ready_i = 1'b1;

            // Request write.

            data_in_i       = 4'hF;
            data_in_valid_i = 1'b1;

            // Capture value being read before read edge.

            #1;

            expected = data_out_o;

            check(
                "Simultaneous read data is E",
                expected == 4'hE
            );

            // Wait for write side to become ready.

            while (!data_in_ready_o)
                @(posedge data_in_clk_i);

            // Read and write occur on their respective clocks.

            @(posedge data_out_clk_i);

            @(posedge data_in_clk_i);

            #1;

            data_out_ready_i = 1'b0;
            data_in_valid_i  = 1'b0;
            data_in_i        = '0;

            check(
                "Simultaneous read received E",
                expected == 4'hE
            );

            // Allow the newly written value to cross CDC.

            wait_cdc_sync;

            check(
                "FIFO contains new F after simultaneous operation",
                data_out_valid_o == 1'b1
            );

            read_fifo(read_data);

            check(
                "Next value is F",
                read_data == 4'hF
            );

        end

    endtask


    // ============================================================
    // TEST 9
    // FULL + READ/WRITE
    //
    // Important CDC behavior:
    //
    // When FIFO is full, the write side does NOT immediately know
    // that a read happened in the other clock domain.
    //
    // The read pointer must first cross through the synchronizer.
    //
    // Therefore we:
    //
    // 1. Fill FIFO.
    // 2. Start a read.
    // 3. Wait for read pointer synchronization.
    // 4. Verify write side becomes ready.
    // 5. Write new data.
    //
    // ============================================================

    task automatic test_full_simultaneous;

        logic [DATA_WIDTH-1:0] first_value;

        begin

            $display("");
            $display("========================================");
            $display("TEST 9: FULL + READ/WRITE");
            $display("========================================");

            write_fifo(4'h1);
            write_fifo(4'h2);
            write_fifo(4'h3);
            write_fifo(4'h4);

            check(
                "FIFO count is full",
                data_in_count_o == FIFO_DEPTH
            );

            check(
                "FIFO is not ready when full",
                data_in_ready_o == 1'b0
            );

            wait_cdc_sync;

            check(
                "Read side sees full FIFO",
                data_out_count_o == FIFO_DEPTH
            );

            // Start read.

            data_out_ready_i = 1'b1;

            while (!data_out_valid_o)
                @(posedge data_out_clk_i);

            #1;

            first_value = data_out_o;

            check(
                "First full FIFO value is 1",
                first_value == 4'h1
            );

            @(posedge data_out_clk_i);

            #1;

            data_out_ready_i = 1'b0;

            // ----------------------------------------------------
            // The write side must wait for the read pointer to
            // cross the CDC synchronizer.
            // ----------------------------------------------------

            wait_cdc_sync;

            check(
                "Write side sees space after read synchronization",
                data_in_ready_o == 1'b1
            );

            // Now write 9.

            write_fifo(4'h9);

            check(
                "Write count returns to FIFO depth",
                data_in_count_o == FIFO_DEPTH
            );

            // Allow write pointer to cross.

            wait_cdc_sync;

            // Remaining sequence must be:
            //
            // 2
            // 3
            // 4
            // 9

            read_fifo(read_data);

            check(
                "Full simultaneous next value is 2",
                read_data == 4'h2
            );

            read_fifo(read_data);

            check(
                "Full simultaneous next value is 3",
                read_data == 4'h3
            );

            read_fifo(read_data);

            check(
                "Full simultaneous next value is 4",
                read_data == 4'h4
            );

            read_fifo(read_data);

            check(
                "Full simultaneous new value is 9",
                read_data == 4'h9
            );

            wait_cdc_sync;

            check(
                "FIFO is empty after full simultaneous test",
                data_out_count_o == 0
            );

        end

    endtask


    // ============================================================
    // TEST 10
    // RESET DURING OPERATION
    // ============================================================

    task automatic test_reset_during_operation;

        begin

            $display("");
            $display("========================================");
            $display("TEST 10: RESET DURING OPERATION");
            $display("========================================");

            // Put data into FIFO.

            write_fifo(4'hA);
            write_fifo(4'hB);
            write_fifo(4'hC);

            check(
                "Write count is 3 before reset",
                data_in_count_o == 3
            );

            wait_cdc_sync;

            check(
                "Read side has valid data before reset",
                data_out_valid_o == 1'b1
            );

            check(
                "Read count is 3 before reset",
                data_out_count_o == 3
            );

            // ----------------------------------------------------
            // Assert reset during operation.
            // ----------------------------------------------------

            data_in_arst_ni  = 1'b0;
            data_out_arst_ni = 1'b0;

            #1;

            check(
                "Write ready becomes 0 during reset",
                data_in_ready_o == 1'b0
            );

            check(
                "Read valid becomes 0 during reset",
                data_out_valid_o == 1'b0
            );

            check(
                "Read data becomes 0 during reset",
                data_out_o == '0
            );

            check(
                "Write count becomes 0 during reset",
                data_in_count_o == 0
            );

            check(
                "Read count becomes 0 during reset",
                data_out_count_o == 0
            );

            // Reset remains active.

            repeat (3)
                @(posedge data_in_clk_i);

            repeat (3)
                @(posedge data_out_clk_i);

            #1;

            check(
                "Write ready remains 0 during reset",
                data_in_ready_o == 1'b0
            );

            check(
                "Read valid remains 0 during reset",
                data_out_valid_o == 1'b0
            );

            check(
                "Write count remains 0 during reset",
                data_in_count_o == 0
            );

            check(
                "Read count remains 0 during reset",
                data_out_count_o == 0
            );

            // ----------------------------------------------------
            // Release reset.
            // ----------------------------------------------------

            data_in_arst_ni  = 1'b1;
            data_out_arst_ni = 1'b1;

            wait_cdc_sync;

            check(
                "FIFO empty after reset release",
                data_out_valid_o == 1'b0
            );

            check(
                "Write count zero after reset release",
                data_in_count_o == 0
            );

            check(
                "Read count zero after reset release",
                data_out_count_o == 0
            );

            check(
                "FIFO ready after reset release",
                data_in_ready_o == 1'b1
            );

            // ----------------------------------------------------
            // Verify FIFO works again after reset.
            // ----------------------------------------------------

            write_fifo(4'hD);

            check(
                "FIFO accepts data after reset",
                data_in_count_o == 1
            );

            wait_cdc_sync;

            read_fifo(read_data);

            check(
                "Correct post-reset data is D",
                read_data == 4'hD
            );

            wait_cdc_sync;

            check(
                "FIFO empty after post-reset read",
                data_out_count_o == 0
            );

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        tests_passed = 0;
        tests_failed = 0;

        write_count = 0;
        read_count  = 0;

        expected_queue.delete();

        data_in_arst_ni  = 1'b0;
        data_out_arst_ni = 1'b0;

        data_in_i        = '0;
        data_in_valid_i  = 1'b0;

        data_out_ready_i = 1'b0;


        // ========================================================
        // START
        // ========================================================

        $display("");
        $display("========================================");
        $display("       CDC FIFO TESTBENCH START");
        $display("========================================");

        // Allow reset to be active initially.

        #30ns;

        data_in_arst_ni  = 1'b1;
        data_out_arst_ni = 1'b1;

        wait_cdc_sync;


        // ========================================================
        // RUN TESTS
        // ========================================================

        test_reset;

        test_single_write_read;

        test_fifo_order;

        test_fill_fifo;

        test_blocked_write;

        test_empty_fifo;

        test_pointer_wrap;

        test_simultaneous_read_write;

        test_full_simultaneous;

        test_reset_during_operation;


        // ========================================================
        // FINAL SCOREBOARD CHECK
        // ========================================================

        wait_cdc_sync;

        check(
            "Scoreboard is empty",
            expected_queue.size() == 0
        );


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("             TEST SUMMARY");
        $display("========================================");

        $display(
            "Tests passed : %0d",
            tests_passed
        );

        $display(
            "Tests failed : %0d",
            tests_failed
        );

        $display(
            "Total writes : %0d",
            write_count
        );

        $display(
            "Total reads  : %0d",
            read_count
        );

        $display(
            "Queue left   : %0d",
            expected_queue.size()
        );

        if (tests_failed == 0) begin

            $display("");
            $display("*** ALL CDC FIFO TESTS PASSED ***");

        end

        else begin

            $display("");
            $display("*** SOME CDC FIFO TESTS FAILED ***");

        end

        $display("========================================");

        #50ns;

        $finish;

    end


    // ============================================================
    // WAVEFORM
    // ============================================================

    initial begin

        $dumpfile("cdc_fifo.vcd");
        $dumpvars(0, cdc_fifo_tb);

    end

endmodule