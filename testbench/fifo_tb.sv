module fifo_tb;

    // ---------------------------------------------------------
    // Parameters (kept small so waveforms/logs are easy to read)
    // ---------------------------------------------------------
    localparam int ADDR_WIDTH = 2;               // 4-slot FIFO
    localparam int DATA_WIDTH = 8;                // byte-wide data, easier to eyeball than 1 bit
    localparam int DEPTH      = 2**ADDR_WIDTH;

    // ---------------------------------------------------------
    // DUT connections
    // ---------------------------------------------------------
    logic                  arst_ni;
    logic                  clk_i;

    logic [DATA_WIDTH-1:0] data_in_i;
    logic                  data_in_valid_i;
    logic                  data_in_ready_o;

    logic [DATA_WIDTH-1:0] data_out_o;
    logic                  data_out_valid_o;
    logic                  data_out_ready_i;

    logic [ADDR_WIDTH:0]   count_o;

    int errors = 0;
    int pass_count = 0;

    // ---------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------
    fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .arst_ni          (arst_ni),
        .clk_i            (clk_i),
        .data_in_i        (data_in_i),
        .data_in_valid_i  (data_in_valid_i),
        .data_in_ready_o  (data_in_ready_o),
        .data_out_o       (data_out_o),
        .data_out_valid_o (data_out_valid_o),
        .data_out_ready_i (data_out_ready_i),
        .count_o          (count_o)
    );

    // ---------------------------------------------------------
    // Clock generation: 10ns period (100MHz)
    // ---------------------------------------------------------
    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    // ---------------------------------------------------------
    // Helper: drive a single push transaction (blocks until accepted)
    // ---------------------------------------------------------
    task automatic push_word(input [DATA_WIDTH-1:0] data);
        begin
            data_in_i       = data;
            data_in_valid_i = 1'b1;
            // Wait until ready is ALREADY high before the qualifying edge -
            // checking it AFTER the edge is unreliable, since the DUT's own
            // state (and therefore ready) may change as a result of that edge.
            while (!data_in_ready_o) @(posedge clk_i);
            @(posedge clk_i);   // this is the edge that actually performs the push
            data_in_valid_i = 1'b0;
        end
    endtask

    // ---------------------------------------------------------
    // Helper: accept a single pop transaction, return the data
    // ---------------------------------------------------------
    task automatic pop_word(output [DATA_WIDTH-1:0] data);
        begin
            data_out_ready_i = 1'b1;
            // Same principle as push_word: confirm valid is high BEFORE the
            // qualifying edge, then capture data_out_o at that same moment -
            // not after the edge, since data_out_o/valid may already have
            // moved on to reflect post-transaction state by then.
            while (!data_out_valid_o) @(posedge clk_i);
            data = data_out_o;   // sampled at the moment valid&&ready are both true
            @(posedge clk_i);    // this is the edge that actually performs the pop
            data_out_ready_i = 1'b0;
        end
    endtask

    // ---------------------------------------------------------
    // Helper: simple checker
    // ---------------------------------------------------------
    task automatic check(input logic condition, input string msg);
        begin
            if (condition) begin
                pass_count++;
                $display("[PASS] %s", msg);
            end else begin
                errors++;
                $display("[FAIL] %s", msg);
            end
        end
    endtask

    // ---------------------------------------------------------
    // TEST 1: Reset behavior
    // ---------------------------------------------------------
    task automatic test_reset();
        begin
            $display("\n--- TEST 1: Reset behavior ---");
            arst_ni          = 0;
            data_in_valid_i  = 0;
            data_out_ready_i = 0;
            data_in_i        = '0;
            repeat (2) @(posedge clk_i);
            arst_ni = 1;
            @(posedge clk_i);

            check(count_o == 0, "count_o is 0 after reset");
            check(data_in_ready_o == 1'b1, "data_in_ready_o is high (FIFO has room) after reset");
            check(data_out_valid_o == 1'b0, "data_out_valid_o is low (FIFO empty) after reset");
        end
    endtask

    // ---------------------------------------------------------
    // TEST 2: Single write, single read, data integrity
    // ---------------------------------------------------------
    task automatic test_single_push_pop();
        logic [DATA_WIDTH-1:0] rdata;
        begin
            $display("\n--- TEST 2: Single push/pop ---");
            push_word(8'hA5);
            @(posedge clk_i);
            check(count_o == 1, "count_o == 1 after one push");

            pop_word(rdata);
            check(rdata == 8'hA5, "popped data matches what was pushed (0xA5)");
            @(posedge clk_i);
            check(count_o == 0, "count_o == 0 after the matching pop");
        end
    endtask

    // ---------------------------------------------------------
    // TEST 3: Fill FIFO completely, check ready deasserts
    // ---------------------------------------------------------
    task automatic test_fill_to_full();
        begin
            $display("\n--- TEST 3: Fill to full ---");
            for (int i = 0; i < DEPTH; i++) begin
                push_word(i[DATA_WIDTH-1:0]);
            end
            @(posedge clk_i);
            check(count_o == DEPTH, "count_o == DEPTH after filling FIFO completely");
            check(data_in_ready_o == 1'b0, "data_in_ready_o (push_ready) low when FIFO is full");
        end
    endtask

    // ---------------------------------------------------------
    // TEST 4: Drain FIFO completely, check valid deasserts,
    // and verify FIFO ordering (FIFO, not LIFO)
    // ---------------------------------------------------------
    task automatic test_drain_to_empty();
        logic [DATA_WIDTH-1:0] rdata;
        begin
            $display("\n--- TEST 4: Drain to empty (order check) ---");
            for (int i = 0; i < DEPTH; i++) begin
                pop_word(rdata);
                check(rdata == i[DATA_WIDTH-1:0],
                      $sformatf("pop #%0d returned %0d as expected (FIFO order preserved)", i, i));
            end
            @(posedge clk_i);
            check(count_o == 0, "count_o == 0 after draining FIFO completely");
            check(data_out_valid_o == 1'b0, "data_out_valid_o low when FIFO is empty");
        end
    endtask

    // ---------------------------------------------------------
    // TEST 5: Wraparound - fill, drain, fill again
    // (exercises pointer wraparound past the top bit)
    // ---------------------------------------------------------
    task automatic test_pointer_wraparound();
        logic [DATA_WIDTH-1:0] rdata;
        begin
            $display("\n--- TEST 5: Pointer wraparound ---");
            // First full fill+drain cycle to advance pointers past DEPTH
            for (int i = 0; i < DEPTH; i++) push_word(8'hC0 + i);
            for (int i = 0; i < DEPTH; i++) begin
                pop_word(rdata);
                check(rdata == 8'hC0 + i, $sformatf("wraparound cycle 1: word %0d correct", i));
            end

            // Second fill+drain cycle - pointers have now wrapped at least once
            for (int i = 0; i < DEPTH; i++) push_word(8'hD0 + i);
            for (int i = 0; i < DEPTH; i++) begin
                pop_word(rdata);
                check(rdata == 8'hD0 + i, $sformatf("wraparound cycle 2: word %0d correct", i));
            end
            check(count_o == 0, "count_o == 0 after wraparound test completes");
        end
    endtask

    // ---------------------------------------------------------
    // TEST 6: Reset in the middle of operation
    // ---------------------------------------------------------
    task automatic test_mid_operation_reset();
        begin
            $display("\n--- TEST 6: Reset mid-operation ---");
            push_word(8'h11);
            push_word(8'h22);
            @(posedge clk_i);
            check(count_o == 2, "count_o == 2 before mid-op reset");

            arst_ni = 0;
            @(posedge clk_i);
            arst_ni = 1;
            @(posedge clk_i);

            check(count_o == 0, "count_o == 0 immediately after mid-op reset");
            check(data_out_valid_o == 1'b0, "data_out_valid_o low after mid-op reset (old data discarded)");
        end
    endtask

    // ---------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------
    initial begin
        test_reset();
        test_single_push_pop();
        test_fill_to_full();
        test_drain_to_empty();
        test_pointer_wraparound();
        test_mid_operation_reset();

        $display("\n=====================================");
        $display(" TESTS COMPLETE: %0d passed, %0d failed", pass_count, errors);
        $display("=====================================");

        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");

        $finish;
    end

    // Safety timeout in case a wait condition never resolves (e.g. a real bug hangs the sim)
    initial begin
        #10000;
        $display("[TIMEOUT] Simulation did not finish in time - possible hang in DUT logic");
        $finish;
    end

endmodule