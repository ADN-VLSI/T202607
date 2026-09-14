module fifo_tb;

    // ------------------------------------------------------------
    // PARAMETERS
    // ------------------------------------------------------------

    parameter int DATA_WIDTH = 4;
    parameter int FIFO_DEPTH = 4;

    localparam int COUNT_WIDTH = $clog2(FIFO_DEPTH + 1);


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

    logic [COUNT_WIDTH-1:0] count_o;


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

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
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

        // Write occurs on this clock

        @(posedge clk);

        #1;

        data_in_valid_i = 0;
        data_in_i = 0;

    endtask


    // ------------------------------------------------------------
    // POP TASK
    // ------------------------------------------------------------

    task automatic pop(
        output logic [DATA_WIDTH-1:0] value
    );

        data_out_ready_i = 1;

        // Wait until FIFO has data

        while (!data_out_valid_o) begin
            @(posedge clk);
        end

        // Capture data before read pointer changes

        #1;

        value = data_out_o;

        // Read occurs on this clock

        @(posedge clk);

        #1;

        data_out_ready_i = 0;

    endtask


    // ------------------------------------------------------------
    // MAIN TEST
    // ------------------------------------------------------------

    initial begin

        tests_passed = 0;
        tests_failed = 0;

        arst_ni = 0;

        data_in_i = 0;
        data_in_valid_i = 0;

        data_out_ready_i = 0;


        // ========================================================
        // RESET TEST
        //
        // Verify all outputs are zero during reset.
        // ========================================================

        $display("");
        $display("========================================");
        $display("       FIFO TESTBENCH START");
        $display("========================================");

        $display("");
        $display("----------------------------------------");
        $display("RESET TEST");
        $display("----------------------------------------");

        #1;

        check(
            "Ready is 0 during reset",
            data_in_ready_o == 0
        );

        check(
            "Valid is 0 during reset",
            data_out_valid_o == 0
        );

        check(
            "Data output is 0 during reset",
            data_out_o == '0
        );

        check(
            "Count is 0 during reset",
            count_o == 0
        );


        // Keep reset active for two clocks

        repeat (2)
            @(posedge clk);


        // Release reset

        arst_ni = 1;

        #1;


        // Check FIFO state after reset

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
            count_o == FIFO_DEPTH
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
            "Ready is 0 when full and no read",
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
            "Count remains 4 after blocked write",
            count_o == 4
        );


        // ========================================================
        // TEST 5: CANNOT READ WHEN EMPTY
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


        // Try reading while empty

        data_out_ready_i = 1;

        #1;

        check(
            "Read enable is 0 when empty",
            dut.read_en == 0
        );

        @(posedge clk);

        #1;

        data_out_ready_i = 0;

        check(
            "Count remains 0 after blocked read",
            count_o == 0
        );


        // ========================================================
        // TEST 6: POINTER WRAP-AROUND
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
        // TEST 7: SIMULTANEOUS READ AND WRITE
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 7: SIMULTANEOUS READ AND WRITE");
        $display("----------------------------------------");

        push(4'hE);

        data_in_i = 4'hF;
        data_in_valid_i = 1;

        data_out_ready_i = 1;

        #1;

        check(
            "Read enable is 1",
            dut.read_en == 1
        );

        check(
            "Write enable is 1",
            dut.write_en == 1
        );

        read_data = data_out_o;

        @(posedge clk);

        #1;

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

        pop(read_data);

        check(
            "Next value is F",
            read_data == 4'hF
        );


        // ========================================================
        // TEST 8: FULL + SIMULTANEOUS READ/WRITE
        //
        // FIFO:
        //
        // [1][2][3][4]
        //
        // Same clock:
        //
        // READ 1
        // WRITE 9
        //
        // Result:
        //
        // [2][3][4][9]
        //
        // Count remains 4.
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 8: FULL + SIMULTANEOUS READ/WRITE");
        $display("----------------------------------------");

        push(4'h1);
        push(4'h2);
        push(4'h3);
        push(4'h4);

        check(
            "FIFO count is 4 before simultaneous test",
            count_o == 4
        );

        check(
            "FIFO is full before simultaneous test",
            data_in_ready_o == 0
        );


        // Request write 9

        data_in_i = 4'h9;
        data_in_valid_i = 1;

        // Request read 1

        data_out_ready_i = 1;

        #1;

        check(
            "Ready becomes 1 when full and read happens",
            data_in_ready_o == 1
        );

        check(
            "Read enable is 1",
            dut.read_en == 1
        );

        check(
            "Write enable is 1",
            dut.write_en == 1
        );

        check(
            "Data being read is 1",
            data_out_o == 4'h1
        );


        // Same clock edge

        @(posedge clk);

        #1;

        data_in_valid_i = 0;
        data_out_ready_i = 0;
        data_in_i = 0;


        check(
            "Count remains 4 after simultaneous operation",
            count_o == 4
        );


        // Verify 1 was removed

        pop(read_data);

        check(
            "Next value is 2",
            read_data == 4'h2
        );

        pop(read_data);

        check(
            "Next value is 3",
            read_data == 4'h3
        );

        pop(read_data);

        check(
            "Next value is 4",
            read_data == 4'h4
        );


        // Verify 9 was inserted

        pop(read_data);

        check(
            "Newly written value is 9",
            read_data == 4'h9
        );


        check(
            "FIFO is empty after final drain",
            count_o == 0
        );


        // ========================================================
        // TEST 9: RESET DURING OPERATION
        //
        // Fill FIFO partially.
        //
        // Then assert reset randomly while FIFO contains data.
        //
        // During reset:
        //
        // ready = 0
        // valid = 0
        // data_out = 0
        // count = 0
        //
        // After reset:
        //
        // FIFO must start empty.
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 9: RESET DURING OPERATION");
        $display("----------------------------------------");


        // Put data into FIFO

        push(4'hA);
        push(4'hB);
        push(4'hC);


        check(
            "Count is 3 before random reset",
            count_o == 3
        );

        check(
            "FIFO has valid data before reset",
            data_out_valid_o == 1
        );


        // --------------------------------------------------------
        // Randomly assert reset while FIFO is operating.
        // --------------------------------------------------------

        arst_ni = 0;

        #1;


        // --------------------------------------------------------
        // ALL OUTPUTS MUST BE ZERO DURING RESET
        // --------------------------------------------------------

        check(
            "Ready becomes 0 during reset",
            data_in_ready_o == 0
        );

        check(
            "Valid becomes 0 during reset",
            data_out_valid_o == 0
        );

        check(
            "Data output becomes 0 during reset",
            data_out_o == '0
        );

        check(
            "Count becomes 0 during reset",
            count_o == 0
        );


        // --------------------------------------------------------
        // Keep reset active for two clocks.
        // --------------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;


        // Check outputs again while reset remains active

        check(
            "Ready remains 0 during reset",
            data_in_ready_o == 0
        );

        check(
            "Valid remains 0 during reset",
            data_out_valid_o == 0
        );

        check(
            "Data output remains 0 during reset",
            data_out_o == '0
        );

        check(
            "Count remains 0 during reset",
            count_o == 0
        );


        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------

        arst_ni = 1;

        #1;


        // --------------------------------------------------------
        // FIFO must start empty after reset.
        // --------------------------------------------------------

        check(
            "FIFO is empty after reset release",
            data_out_valid_o == 0
        );

        check(
            "Count is zero after reset release",
            count_o == 0
        );

        check(
            "FIFO is ready after reset release",
            data_in_ready_o == 1
        );


        // --------------------------------------------------------
        // Verify FIFO can operate normally again.
        // --------------------------------------------------------

        push(4'hD);

        check(
            "FIFO accepts data after reset",
            count_o == 1
        );

        pop(read_data);

        check(
            "Correct data after reset is D",
            read_data == 4'hD
        );

        check(
            "FIFO is empty after post-reset read",
            count_o == 0
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