`timescale 1ns/1ps

module tb_sync_fifo;

    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 16;
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    logic clk_i;
    logic arst_ni;
    logic [DATA_WIDTH-1:0] data_in_i;
    logic data_in_valid_i;
    logic data_in_ready_o;
    logic [DATA_WIDTH-1:0] data_out_o;
    logic data_out_valid_o;
    logic data_out_ready_i;
    logic [ADDR_WIDTH:0] count_o;

    logic [DATA_WIDTH-1:0] expected_queue[$];
    int error_count = 0;

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk_i(clk_i),
        .arst_ni(arst_ni),
        .data_in_i(data_in_i),
        .data_in_valid_i(data_in_valid_i),
        .data_in_ready_o(data_in_ready_o),
        .data_out_o(data_out_o),
        .data_out_valid_o(data_out_valid_o),
        .data_out_ready_i(data_out_ready_i),
        .count_o(count_o)
    );

    task automatic reset_test();
        $display("[TEST] RESET");

        arst_ni = 0;
        data_in_i = '0;
        data_in_valid_i = 0;
        data_out_ready_i = 0;
        expected_queue.delete();

        repeat (3) @(posedge clk_i);
        #1;

        if (count_o !== 0) begin
            $error("[RESET] count = %0d, expected 0", count_o);
            error_count++;
        end

        if (data_out_valid_o !== 0) begin
            $error("[RESET] valid = %0b, expected 0", data_out_valid_o);
            error_count++;
        end

        if (data_in_ready_o !== 1) begin
            $error("[RESET] ready = %0b, expected 1", data_in_ready_o);
            error_count++;
        end

        arst_ni = 1;

        @(posedge clk_i);
        #1;

        if (count_o === 0 && data_out_valid_o === 0 && data_in_ready_o === 1)
            $display("[PASS] RESET");
    endtask

    task automatic write_during_reset_test();
        $display("[TEST] WRITE DURING RESET");

        arst_ni = 0;

        @(negedge clk_i);
        data_in_i = 8'hFF;
        data_in_valid_i = 1;
        data_out_ready_i = 0;

        @(posedge clk_i);
        #1;

        if (count_o !== 0) begin
            $error("[RESET WRITE] count = %0d, expected 0", count_o);
            error_count++;
        end

        if (data_out_valid_o !== 0) begin
            $error("[RESET WRITE] valid = %0b, expected 0", data_out_valid_o);
            error_count++;
        end

        @(negedge clk_i);
        data_in_valid_i = 0;
        arst_ni = 1;

        @(posedge clk_i);
        #1;

        if (count_o === 0 && data_out_valid_o === 0)
            $display("[PASS] WRITE DURING RESET - write was ignored");
    endtask

    task automatic no_operation_test();
        int old_count;

        $display("[TEST] NO OPERATION (00)");

        old_count = count_o;

        @(negedge clk_i);

        data_in_valid_i = 0;
        data_out_ready_i = 0;

        @(posedge clk_i);
        #1;

        if (count_o !== old_count) begin
            $error("[00] count changed from %0d to %0d", old_count, count_o);
            error_count++;
        end
        else begin
            $display("[PASS] 00");
        end
    endtask

    task automatic write_only_test(input logic [DATA_WIDTH-1:0] data);
        $display("[TEST] WRITE ONLY (10)");

        @(negedge clk_i);

        data_in_i <= data;
        data_in_valid_i = 1;
        data_out_ready_i = 0;

        #1;

        if (data_in_ready_o !== 1) begin
            $error("[10] ready = 0, data = 0x%0h", data);
            error_count++;
        end

        @(posedge clk_i);
        #1;

        expected_queue.push_back(data);

        @(negedge clk_i);
        data_in_valid_i = 0;

        if (data_in_ready_o || count_o == expected_queue.size())
            $display("[PASS] 10 - Wrote 0x%0h", data);
    endtask

    task automatic read_only_test();
        logic [DATA_WIDTH-1:0] expected_data;

        $display("[TEST] READ ONLY (01)");

        if (expected_queue.size() == 0) begin
            $error("[01] Reference queue is empty");
            error_count++;
            return;
        end

        expected_data = expected_queue[0];

        @(negedge clk_i);

        data_in_valid_i = 0;
        data_out_ready_i = 1;

        #1;

        if (data_out_valid_o !== 1) begin
            $error("[01] valid = 0");
            error_count++;
        end

        if (data_out_o !== expected_data) begin
            $error("[01] expected 0x%0h, got 0x%0h", expected_data, data_out_o);
            error_count++;
        end

        @(posedge clk_i);
        #1;

        expected_queue.pop_front();

        @(negedge clk_i);
        data_out_ready_i = 0;

        if (data_out_o === expected_data)
            $display("[PASS] 01 - Read 0x%0h", expected_data);
    endtask

    task automatic simultaneous_write_read_test(input logic [DATA_WIDTH-1:0] new_data);
        logic [DATA_WIDTH-1:0] expected_data;
        int expected_count;

        $display("[TEST] SIMULTANEOUS WRITE + READ (11)");

        if (expected_queue.size() == 0) begin
            $error("[11] Reference queue is empty");
            error_count++;
            return;
        end

        expected_data = expected_queue[0];
        expected_count = expected_queue.size();

        @(negedge clk_i);

        data_in_i = new_data;
        data_in_valid_i = 1;
        data_out_ready_i = 1;

        #1;

        if (data_in_ready_o !== 1) begin
            $error("[11] write ready = 0");
            error_count++;
        end

        if (data_out_valid_o !== 1) begin
            $error("[11] read valid = 0");
            error_count++;
        end

        if (data_out_o !== expected_data) begin
            $error("[11] expected 0x%0h, got 0x%0h", expected_data, data_out_o);
            error_count++;
        end

        @(posedge clk_i);
        #1;

        expected_queue.pop_front();
        expected_queue.push_back(new_data);

        if (count_o !== expected_count) begin
            $error("[11] count expected %0d, got %0d", expected_count, count_o);
            error_count++;
        end
        else begin
            $display("[PASS] 11 - POP 0x%0h, PUSH 0x%0h, COUNT %0d", expected_data, new_data, count_o);
        end

        @(negedge clk_i);

        data_in_valid_i = 0;
        data_out_ready_i = 0;
    endtask

    task automatic fifo_order_test();
        logic [DATA_WIDTH-1:0] expected_data;

        $display("[TEST] FIFO ORDER");

        for (int i = 0; i < 8; i++) begin
            @(negedge clk_i);

            data_in_i = 8'hC0 + i;
            data_in_valid_i = 1;
            data_out_ready_i = 0;

            @(posedge clk_i);
            #1;

            expected_queue.push_back(8'hC0 + i);

            @(negedge clk_i);
            data_in_valid_i = 0;
        end

        for (int i = 0; i < 8; i++) begin
            expected_data = expected_queue[0];

            @(negedge clk_i);

            data_in_valid_i = 0;
            data_out_ready_i = 1;

            #1;

            if (data_out_o !== expected_data) begin
                $error("[ORDER] expected 0x%0h, got 0x%0h", expected_data, data_out_o);
                error_count++;
            end

            @(posedge clk_i);
            #1;

            expected_queue.pop_front();

            @(negedge clk_i);
            data_out_ready_i = 0;
        end

        $display("[PASS] FIFO ORDER");
    endtask

    task automatic empty_test();
        logic [DATA_WIDTH-1:0] expected_data;

        $display("[TEST] EMPTY");

        while (expected_queue.size() > 0) begin
            expected_data = expected_queue[0];

            @(negedge clk_i);

            data_in_valid_i = 0;
            data_out_ready_i = 1;

            #1;

            if (data_out_valid_o !== 1) begin
                $error("[EMPTY] valid should be 1");
                error_count++;
                break;
            end

            if (data_out_o !== expected_data) begin
                $error("[EMPTY] expected 0x%0h, got 0x%0h", expected_data, data_out_o);
                error_count++;
            end

            @(posedge clk_i);
            #1;

            expected_queue.pop_front();

            @(negedge clk_i);
            data_out_ready_i = 0;
        end

        @(posedge clk_i);
        #1;

        if (count_o !== 0) begin
            $error("[EMPTY] count should be 0, got %0d", count_o);
            error_count++;
        end

        if (data_out_valid_o !== 0) begin
            $error("[EMPTY] valid should be 0");
            error_count++;
        end

        if (data_in_ready_o !== 1) begin
            $error("[EMPTY] ready should be 1");
            error_count++;
        end

        if (count_o === 0 && data_out_valid_o === 0 && data_in_ready_o === 1)
            $display("[PASS] EMPTY");
    endtask

    task automatic full_test();
        $display("[TEST] FULL");

        for (int i = 0; i < FIFO_DEPTH; i++) begin
            @(negedge clk_i);

            data_in_i = 8'hA0 + i;
            data_in_valid_i = 1;
            data_out_ready_i = 0;

            #1;

            if (data_in_ready_o !== 1) begin
                $error("[FULL] item %0d not accepted", i + 1);
                error_count++;
            end

            @(posedge clk_i);
            #1;

            expected_queue.push_back(8'hA0 + i);

            @(negedge clk_i);
            data_in_valid_i = 0;
        end

        #1;

        if (count_o !== FIFO_DEPTH) begin
            $error("[FULL] count expected %0d, got %0d", FIFO_DEPTH, count_o);
            error_count++;
        end

        if (data_in_ready_o !== 0) begin
            $error("[FULL] ready should be 0");
            error_count++;
        end

        if (data_out_valid_o !== 1) begin
            $error("[FULL] valid should be 1");
            error_count++;
        end

        if (count_o === FIFO_DEPTH && data_in_ready_o === 0 && data_out_valid_o === 1)
            $display("[PASS] FULL - count=%0d", count_o);
    endtask

    task automatic seventeenth_data_test();
        logic [DATA_WIDTH-1:0] data17;

        data17 = 8'hB0;

        $display("[TEST] 17TH DATA");

        @(negedge clk_i);

        data_in_i = data17;
        data_in_valid_i = 1;
        data_out_ready_i = 0;

        #1;

        if (data_in_ready_o !== 0) begin
            $error("[17TH] 17th data was accepted");
            error_count++;
        end

        @(posedge clk_i);
        #1;

        if (count_o !== FIFO_DEPTH) begin
            $error("[17TH] count expected %0d, got %0d", FIFO_DEPTH, count_o);
            error_count++;
        end
        else begin
            $display("[PASS] 17TH DATA - blocked");
        end

        @(negedge clk_i);
        data_in_valid_i = 0;
    endtask

    task automatic full_simultaneous_test();
        logic [DATA_WIDTH-1:0] expected_data;
        logic [DATA_WIDTH-1:0] new_data;

        new_data = 8'hEE;

        $display("[TEST] FULL + POP/PUSH (11)");

        if (count_o !== FIFO_DEPTH) begin
            $error("[FULL 11] FIFO is not full");
            error_count++;
            return;
        end

        expected_data = expected_queue[0];

        @(negedge clk_i);

        data_in_i = new_data;
        data_in_valid_i = 1;
        data_out_ready_i = 1;

        #1;

        if (data_out_valid_o !== 1) begin
            $error("[FULL 11] valid should be 1");
            error_count++;
        end

        if (data_out_o !== expected_data) begin
            $error("[FULL 11] expected 0x%0h, got 0x%0h", expected_data, data_out_o);
            error_count++;
        end

        if (data_in_ready_o !== 1) begin
            $error("[FULL 11] ready should be 1 during POP+PUSH");
            error_count++;
        end

        @(posedge clk_i);
        #1;

        expected_queue.pop_front();
        expected_queue.push_back(new_data);

        if (count_o !== FIFO_DEPTH) begin
            $error("[FULL 11] count expected %0d, got %0d", FIFO_DEPTH, count_o);
            error_count++;
        end
        else begin
            $display("[PASS] FULL 11 - POP 0x%0h, PUSH 0x%0h, COUNT %0d", expected_data, new_data, count_o);
        end

        @(negedge clk_i);

        data_in_valid_i = 0;
        data_out_ready_i = 0;
    endtask

    initial begin
        arst_ni = 0;
        data_in_i = '0;
        data_in_valid_i = 0;
        data_out_ready_i = 0;

        reset_test();

        write_during_reset_test();

        no_operation_test();

        write_only_test(8'h11);

        read_only_test();

        write_only_test(8'h21);
        write_only_test(8'h22);
        write_only_test(8'h23);

        simultaneous_write_read_test(8'h31);

        empty_test();

        fifo_order_test();

        empty_test();

        full_test();

        seventeenth_data_test();

        full_simultaneous_test();

        empty_test();

        #20;

        if (error_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED - %0d ERRORS", error_count);

        $finish;
    end

endmodule