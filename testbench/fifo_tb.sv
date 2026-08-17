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
    // ------------------------------------------------------------

    task automatic push(
        input logic [DATA_WIDTH-1:0] value
    );

        // Put data on input
        data_in_i = value;

        // Tell FIFO that data is valid
        data_in_valid_i = 1;

        // Wait until FIFO is ready
        while (!data_in_ready_o) begin
            @(posedge clk);
        end

        // Wait for the clock edge where
        // the FIFO actually writes the data.
        @(posedge clk);

        // Allow DUT to update
        #1;

        // Now remove valid
        data_in_valid_i = 0;

        data_in_i = 0;

    endtask


    // ------------------------------------------------------------
    // POP TASK
    // ------------------------------------------------------------

    task automatic pop(
        output logic [DATA_WIDTH-1:0] value
    );

        // Tell FIFO that we are ready to receive data
        data_out_ready_i = 1;

        // Wait until FIFO has valid data
        while (!data_out_valid_o) begin
            @(posedge clk);
        end

        // Data is already available BEFORE the read clock.
        //
        // Capture it before rd_ptr changes.
        #1;

        value = data_out_o;

        // Now perform the actual read
        @(posedge clk);

        // Allow DUT to update
        #1;

        // Stop reading
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


        // --------------------------------------------------------
        // START MESSAGE
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("       FIFO TESTBENCH START");
        $display("========================================");


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        $display("");
        $display("Resetting FIFO...");

        repeat (2)
            @(posedge clk);

        arst_ni = 1;

        // Give reset release time to settle
        #1;


        // --------------------------------------------------------
        // RESET CHECKS
        // --------------------------------------------------------

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
        // TEST 1
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
        // TEST 2
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

        $display(
            "Expected = 1, Got = %h",
            read_data
        );

        check(
            "First value is 1",
            read_data == 4'h1
        );


        pop(read_data);

        $display(
            "Expected = 2, Got = %h",
            read_data
        );

        check(
            "Second value is 2",
            read_data == 4'h2
        );


        pop(read_data);

        $display(
            "Expected = 3, Got = %h",
            read_data
        );

        check(
            "Third value is 3",
            read_data == 4'h3
        );


        // ========================================================
        // TEST 3
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
        // TEST 4
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 4: DRAIN FIFO");
        $display("----------------------------------------");


        pop(read_data);

        $display(
            "Expected = 4, Got = %h",
            read_data
        );

        check(
            "First drain value is 4",
            read_data == 4'h4
        );


        pop(read_data);

        $display(
            "Expected = 5, Got = %h",
            read_data
        );

        check(
            "Second drain value is 5",
            read_data == 4'h5
        );


        pop(read_data);

        $display(
            "Expected = 6, Got = %h",
            read_data
        );

        check(
            "Third drain value is 6",
            read_data == 4'h6
        );


        pop(read_data);

        $display(
            "Expected = 7, Got = %h",
            read_data
        );

        check(
            "Fourth drain value is 7",
            read_data == 4'h7
        );


        check(
            "Count is zero after draining",
            count_o == 0
        );

        check(
            "FIFO is empty after draining",
            data_out_valid_o == 0
        );


        // ========================================================
        // TEST 5
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 5: POINTER WRAP-AROUND");
        $display("----------------------------------------");


        // Write four values

        push(4'h8);
        push(4'h9);
        push(4'hA);
        push(4'hB);


        // Read four values

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
        // TEST 6
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 6: SIMULTANEOUS READ AND WRITE");
        $display("----------------------------------------");


        // First put E into FIFO

        push(4'hE);


        // --------------------------------------------------------
        // Prepare simultaneous read and write
        // --------------------------------------------------------

        data_in_i = 4'hF;
        data_in_valid_i = 1;

        data_out_ready_i = 1;


        // E is the current output.
        // Capture it BEFORE the clock changes rd_ptr.

        #1;

        read_data = data_out_o;


        // Read E and write F happen on this clock

        @(posedge clk);

        #1;


        // Stop the interfaces

        data_in_valid_i = 0;
        data_out_ready_i = 0;
        data_in_i = 0;


        // E should have been read

        check(
            "Simultaneous read gets E",
            read_data == 4'hE
        );


        // F should now be the only item in FIFO

        check(
            "Count is 1 after simultaneous read/write",
            count_o == 1
        );


        // Read F

        pop(read_data);


        check(
            "Next value is F",
            read_data == 4'hF
        );


        // --------------------------------------------------------
        // FINAL SUMMARY
        // --------------------------------------------------------

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