module fifo_tb;

    // ------------------------------------------------------------
    // PARAMETERS
    // ------------------------------------------------------------

    parameter int DATA_WIDTH = 4;
    parameter int FIFO_DEPTH = 4;


    // ------------------------------------------------------------
    // TESTBENCH SIGNALS
    // ------------------------------------------------------------

    logic clk;
    logic arst_ni;

    logic [DATA_WIDTH-1:0] data_in_i;
    logic                  data_in_valid_i;
    logic                  data_in_ready_o;

    logic [DATA_WIDTH-1:0] data_out_o;
    logic                  data_out_valid_o;
    logic                  data_out_ready_i;

    logic [2:0] count_o;


    // ------------------------------------------------------------
    // TEST VARIABLES
    // ------------------------------------------------------------

    int tests_passed;
    int tests_failed;

    logic [DATA_WIDTH-1:0] read_data;


    // ------------------------------------------------------------
    // CLOCK
    // ------------------------------------------------------------

    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    fifo dut (
        .arst_ni          (arst_ni),
        .clk_i            (clk),

        .data_in_i        (data_in_i),
        .data_in_valid_i  (data_in_valid_i),
        .data_in_ready_o  (data_in_ready_o),

        .data_out_o       (data_out_o),
        .data_out_valid_o (data_out_valid_o),
        .data_out_ready_i (data_out_ready_i),

        .count_o          (count_o)
    );


    // ------------------------------------------------------------
    // WAVEFORM
    // ------------------------------------------------------------

    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
    end


    // ------------------------------------------------------------
    // CHECK TASK
    // ------------------------------------------------------------

    task automatic check(
        input string test_name,
        input logic condition
    );

        if (condition) begin

            $display("[PASS] %s", test_name);
            tests_passed++;

        end

        else begin

            $display("[FAIL] %s", test_name);
            tests_failed++;

        end

    endtask


    // ------------------------------------------------------------
    // PUSH TASK
    //
    // Writes one value into the FIFO.
    // ------------------------------------------------------------

    task automatic push(
        input logic [DATA_WIDTH-1:0] value
    );

        data_in_i = value;
        data_in_valid_i = 1;

        // Wait until FIFO is ready
        while (!data_in_ready_o) begin
            @(posedge clk);
        end

        // Write happens on this clock edge
        @(posedge clk);

        #1;

        data_in_valid_i = 0;
        data_in_i = 0;

    endtask


    // ------------------------------------------------------------
    // POP TASK
    //
    // Reads one value from the FIFO.
    // ------------------------------------------------------------

    task automatic pop(
        output logic [DATA_WIDTH-1:0] value
    );

        data_out_ready_i = 1;

        // Wait until FIFO contains data
        while (!data_out_valid_o) begin
            @(posedge clk);
        end

        // Capture data before rd_ptr changes
        #1;

        value = data_out_o;

        // Read happens on this clock edge
        @(posedge clk);

        #1;

        data_out_ready_i = 0;

    endtask


    // ------------------------------------------------------------
    // MAIN TEST
    // ------------------------------------------------------------

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        tests_passed = 0;
        tests_failed = 0;

        arst_ni = 0;

        data_in_i = 0;
        data_in_valid_i = 0;

        data_out_ready_i = 0;


        // ========================================================
        // RESET
        // ========================================================

        $display("");
        $display("========================================");
        $display("       FIFO TESTBENCH START");
        $display("========================================");

        $display("");
        $display("----------------------------------------");
        $display("RESET TEST");
        $display("----------------------------------------");

        repeat (2)
            @(posedge clk);

        arst_ni = 1;

        #1;


        check(
            "FIFO empty after reset",
            data_out_valid_o == 0
        );

        check(
            "FIFO count is zero after reset",
            count_o == 0
        );

        check(
            "FIFO ready after reset",
            data_in_ready_o == 1
        );


        // ========================================================
        // TEST 1: SINGLE WRITE AND READ
        //
        // Write A and then read A.
        // Tests basic FIFO operation.
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 1: SINGLE WRITE AND READ");
        $display("----------------------------------------");

        push(4'hA);

        check(
            "Count becomes 1 after write",
            count_o == 1
        );

        pop(read_data);

        $display(
            "Expected = A, Got = %h",
            read_data
        );

        check(
            "Read data is A",
            read_data == 4'hA
        );

        check(
            "Count becomes 0 after read",
            count_o == 0
        );


        // ========================================================
        // TEST 2: FIFO ORDER
        //
        // Write 1, 2, 3.
        // Read them back.
        //
        // Expected:
        //
        // 1 -> 2 -> 3
        //
        // Tests FIFO ordering.
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 2: FIFO ORDER");
        $display("----------------------------------------");

        push(4'h1);
        push(4'h2);
        push(4'h3);

        check(
            "Count is 3",
            count_o == 3
        );


        pop(read_data);

        check(
            "First value is 1",
            read_data == 4'h1
        );


        pop(read_data);

        check(
            "Second value is 2",
            read_data == 4'h2
        );


        pop(read_data);

        check(
            "Third value is 3",
            read_data == 4'h3
        );


        // ========================================================
        // TEST 3: FILL FIFO
        //
        // Write four values.
        //
        // FIFO_DEPTH = 4
        //
        // Expected:
        //
        // count = 4
        // ready = 0
        // valid = 1
        //
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 3: FILL FIFO");
        $display("----------------------------------------");

        push(4'h4);
        push(4'h5);
        push(4'h6);
        push(4'h7);

        check(
            "Count is 4 when FIFO is full",
            count_o == 4
        );

        check(
            "FIFO ready is 0 when full",
            data_in_ready_o == 0
        );

        check(
            "FIFO valid is 1 when full",
            data_out_valid_o == 1
        );


        // ========================================================
        // TEST 4: CANNOT WRITE WHEN FULL
        //
        // FIFO is full.
        //
        // No read is requested.
        //
        // Therefore the write must be blocked.
        //
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 4: CANNOT WRITE WHEN FULL");
        $display("----------------------------------------");

        data_in_i = 4'hF;
        data_in_valid_i = 1;

        data_out_ready_i = 0;

        #1;

        check(
            "FIFO ready is 0 when full and no read",
            data_in_ready_o == 0
        );

        check(
            "Write enable is 0 when full and no read",
            dut.write_en == 0
        );

        @(posedge clk);

        #1;

        data_in_valid_i = 0;
        data_in_i = 0;

        check(
            "Write is blocked when FIFO is full",
            count_o == 4
        );

        check(
            "Count remains 4 after blocked write",
            count_o == 4
        );


        // ========================================================
        // TEST 5: CANNOT READ WHEN EMPTY
        //
        // First drain the FIFO.
        //
        // Then try to read when empty.
        //
        // Expected:
        //
        // valid = 0
        // read_en = 0
        // count = 0
        //
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 5: CANNOT READ WHEN EMPTY");
        $display("----------------------------------------");


        pop(read_data);

        check(
            "Drain value = 4",
            read_data == 4'h4
        );


        pop(read_data);

        check(
            "Drain value = 5",
            read_data == 4'h5
        );


        pop(read_data);

        check(
            "Drain value = 6",
            read_data == 4'h6
        );


        pop(read_data);

        check(
            "Drain value = 7",
            read_data == 4'h7
        );


        check(
            "FIFO count is 0",
            count_o == 0
        );

        check(
            "FIFO valid is 0 when empty",
            data_out_valid_o == 0
        );


        // Try to read while empty

        data_out_ready_i = 1;

        #1;

        check(
            "FIFO valid remains 0 when empty",
            data_out_valid_o == 0
        );

        check(
            "Read enable is 0 when empty",
            dut.read_en == 0
        );

        @(posedge clk);

        #1;

        data_out_ready_i = 0;

        check(
            "Read is blocked when FIFO is empty",
            dut.read_en == 0
        );

        check(
            "Count remains 0 after blocked read",
            count_o == 0
        );


        // ========================================================
        // TEST 6: POINTER WRAP-AROUND
        //
        // Write and read four values.
        //
        // Then write again.
        //
        // Tests pointer wrap-around.
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 6: POINTER WRAP-AROUND");
        $display("----------------------------------------");


        push(4'h8);
        push(4'h9);
        push(4'hA);
        push(4'hB);


        pop(read_data);

        check(
            "Wrap read 1 = 8",
            read_data == 4'h8
        );


        pop(read_data);

        check(
            "Wrap read 2 = 9",
            read_data == 4'h9
        );


        pop(read_data);

        check(
            "Wrap read 3 = A",
            read_data == 4'hA
        );


        pop(read_data);

        check(
            "Wrap read 4 = B",
            read_data == 4'hB
        );


        // Write again after wrap-around

        push(4'hC);
        push(4'hD);


        check(
            "Count is 2 after wrap-around writes",
            count_o == 2
        );


        pop(read_data);

        check(
            "Wrap-around new value 1 = C",
            read_data == 4'hC
        );


        pop(read_data);

        check(
            "Wrap-around new value 2 = D",
            read_data == 4'hD
        );


        // ========================================================
        // TEST 7: NORMAL SIMULTANEOUS READ AND WRITE
        //
        // FIFO contains E.
        //
        // Same clock:
        //
        // READ E
        // WRITE F
        //
        // Expected:
        //
        // E is removed
        // F is inserted
        // count remains 1
        //
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 7: SIMULTANEOUS READ AND WRITE");
        $display("----------------------------------------");


        push(4'hE);


        // Request WRITE F

        data_in_i = 4'hF;
        data_in_valid_i = 1;

        // Request READ E

        data_out_ready_i = 1;

        #1;


        // Check that both operations are enabled
        // before the clock edge.

        check(
            "Read enable is 1",
            dut.read_en == 1
        );

        check(
            "Write enable is 1",
            dut.write_en == 1
        );


        // Capture E before read pointer changes

        read_data = data_out_o;


        // BOTH operations happen on this SAME clock edge

        @(posedge clk);

        #1;


        // Stop interfaces

        data_in_valid_i = 0;
        data_out_ready_i = 0;
        data_in_i = 0;


        check(
            "Simultaneous read gets E",
            read_data == 4'hE
        );

        check(
            "Count is 1 after simultaneous read/write",
            count_o == 1
        );


        // F should now be the only item

        pop(read_data);

        check(
            "Next value is F",
            read_data == 4'hF
        );


        // ========================================================
        // TEST 8: FULL + SIMULTANEOUS READ/WRITE
        //
        // This is the MAIN TEST.
        //
        // First fill FIFO:
        //
        // [1][2][3][4]
        //
        // count = 4
        //
        // FIFO is FULL.
        //
        // Then request:
        //
        //     READ 1
        //     WRITE 9
        //
        // on the SAME clock cycle.
        //
        // The new logic should allow the write because:
        //
        //     full = 1
        //     read_en = 1
        //
        // Therefore:
        //
        //     ready = !full || read_en
        //           = !1 || 1
        //           = 1
        //
        // Both write_en and read_en must be 1.
        //
        // After the clock:
        //
        // [2][3][4][9]
        //
        // count = 4
        //
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 8: FULL + SIMULTANEOUS READ/WRITE");
        $display("----------------------------------------");


        // --------------------------------------------------------
        // Fill FIFO
        // --------------------------------------------------------

        push(4'h1);
        push(4'h2);
        push(4'h3);
        push(4'h4);


        check(
            "FIFO count is 4 before full simultaneous test",
            count_o == 4
        );

        check(
            "FIFO is full before simultaneous test",
            data_in_ready_o == 0
        );


        // --------------------------------------------------------
        // Prepare READ + WRITE
        // --------------------------------------------------------

        // New data to write

        data_in_i = 4'h9;

        // Request write

        data_in_valid_i = 1;

        // Request read

        data_out_ready_i = 1;

        #1;


        // Current output must be 1

        check(
            "Output valid is 1 when FIFO is full",
            data_out_valid_o == 1
        );

        check(
            "Data being read is 1",
            data_out_o == 4'h1
        );


        // --------------------------------------------------------
        // BEFORE THE CLOCK
        //
        // Both operations should be enabled.
        // --------------------------------------------------------

        check(
            "Read enable is 1 before simultaneous clock",
            dut.read_en == 1
        );

        check(
            "Write enable is 1 before simultaneous clock",
            dut.write_en == 1
        );

        check(
            "Ready becomes 1 when full and read is happening",
            data_in_ready_o == 1
        );


        // Save data that is being read

        read_data = data_out_o;


        // --------------------------------------------------------
        // SAME CLOCK EDGE
        //
        // READ 1
        // WRITE 9
        //
        // Both happen here.
        // --------------------------------------------------------

        @(posedge clk);


        // Immediately after the edge, check that both
        // enables were active for this transaction.

        check(
            "Read enable was active during simultaneous clock",
            dut.read_en == 1
        );

        check(
            "Write enable was active during simultaneous clock",
            dut.write_en == 1
        );


        #1;


        // Stop interfaces

        data_in_valid_i = 0;
        data_out_ready_i = 0;
        data_in_i = 0;


        // --------------------------------------------------------
        // Verify READ
        //
        // The value that was on the output was 1.
        //
        // The next FIFO value must now be 2.
        //
        // Therefore 1 was removed.
        // --------------------------------------------------------

        check(
            "Full FIFO simultaneous read gets 1",
            read_data == 4'h1
        );


        // --------------------------------------------------------
        // Verify COUNT
        //
        // 4 - 1 + 1 = 4
        //
        // Therefore the FIFO remains full.
        // --------------------------------------------------------

        check(
            "Count remains 4 after simultaneous read/write",
            count_o == 4
        );


        // FIFO must still have data

        check(
            "FIFO still has valid data",
            data_out_valid_o == 1
        );


        // --------------------------------------------------------
        // Verify that 1 is gone.
        //
        // Next value must be 2.
        // --------------------------------------------------------

        pop(read_data);

        check(
            "After simultaneous operation next value = 2",
            read_data == 4'h2
        );


        // --------------------------------------------------------
        // Continue checking FIFO order.
        // --------------------------------------------------------

        pop(read_data);

        check(
            "Next value = 3",
            read_data == 4'h3
        );


        pop(read_data);

        check(
            "Next value = 4",
            read_data == 4'h4
        );


        // --------------------------------------------------------
        // Finally verify that 9 was inserted.
        //
        // If the write did not happen on the simultaneous
        // clock, there would be no 9 here.
        // --------------------------------------------------------

        pop(read_data);

        check(
            "Newly written value = 9",
            read_data == 4'h9
        );


        // --------------------------------------------------------
        // FIFO must now be empty.
        // --------------------------------------------------------

        check(
            "FIFO is empty after final drain",
            count_o == 0
        );

        check(
            "FIFO valid is 0 after final drain",
            data_out_valid_o == 0
        );


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("          TEST SUMMARY");
        $display("========================================");

        $display(
            "Tests passed : %0d",
            tests_passed
        );

        $display(
            "Tests failed : %0d",
            tests_failed
        );


        if (tests_failed == 0) begin

            $display("");
            $display("*** ALL TESTS PASSED ***");

        end

        else begin

            $display("");
            $display("*** SOME TESTS FAILED ***");

        end


        $display("========================================");


        #20;

        $finish;

    end

endmodule