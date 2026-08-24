`timescale 1ns/1ps

module tb_sync_fifo;

    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 16;
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    logic                  clk_i;
    logic                  arst_ni;
    logic [DATA_WIDTH-1:0] data_in_i;
    logic                  data_in_valid_i;
    logic                  data_in_ready_o;
    logic [DATA_WIDTH-1:0] data_out_o;
    logic                  data_out_valid_o;
    logic                  data_out_ready_i;
    logic [ADDR_WIDTH:0]   count_o;

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk_i            (clk_i),
        .arst_ni          (arst_ni),
        .data_in_i        (data_in_i),
        .data_in_valid_i  (data_in_valid_i),
        .data_in_ready_o  (data_in_ready_o),
        .data_out_o       (data_out_o),
        .data_out_valid_o (data_out_valid_o),
        .data_out_ready_i (data_out_ready_i),
        .count_o          (count_o)
    );

    logic [DATA_WIDTH-1:0] expected_queue[$];
    int error_count = 0;

    task automatic push(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk_i);
        while (!data_in_ready_o) @(posedge clk_i);
        data_in_valid_i <= 1'b1;
        data_in_i       <= data;
        expected_queue.push_back(data);
        @(posedge clk_i);
        data_in_valid_i <= 1'b0;
    endtask

    task automatic pop();
        logic [DATA_WIDTH-1:0] expected_data;

        @(posedge clk_i);
        while (!data_out_valid_o) @(posedge clk_i);

        data_out_ready_i <= 1'b1;
        expected_data = expected_queue.pop_front();

        #1;

        if (data_out_o !== expected_data) begin
            $error("[TB ERROR] Mismatch! Expected: 0x%0h, Got: 0x%0h",
                   expected_data, data_out_o);
            error_count++;
        end else begin
            $display("[TB PASS] Popped correct data: 0x%0h", data_out_o);
        end

        @(posedge clk_i);
        data_out_ready_i <= 1'b0;
    endtask

    initial begin
        arst_ni          = 0;
        data_in_i        = '0;
        data_in_valid_i  = 0;
        data_out_ready_i = 0;
        

        #25;
        arst_ni = 1;
        #10;

        $display("--- Test 1: Simple Sequential Push & Pop ---");

        for (int i = 0; i < 4; i++)
            push(8'h10 + i);

        for (int i = 0; i < 4; i++)
            pop();

        $display("--- Test 2: Fill FIFO to Maximum (Full Check) ---");

        for (int i = 0; i < FIFO_DEPTH; i++)
            push(8'hA0 + i);

        @(posedge clk_i);

        if (data_in_ready_o !== 1'b0) begin
            $error("[TB ERROR] Ready should be 0 when full!");
            error_count++;
        end else begin
            $display("[TB PASS] FIFO correctly asserted backpressure (ready=0).");
        end

        $display("--- Test 3: Drain FIFO to Zero (Empty Check) ---");

        for (int i = 0; i < FIFO_DEPTH; i++)
            pop();

        @(posedge clk_i);

        if (data_out_valid_o !== 1'b0) begin
            $error("[TB ERROR] Valid should be 0 when empty!");
            error_count++;
        end else begin
            $display("[TB PASS] FIFO correctly de-asserted valid (valid=0).");
        end

        $display("--- Test 4: Simultaneous Read & Write ---");

        fork
            begin
                for (int i = 0; i < 8; i++)
                    push(8'h50 + i);
            end
            begin
                #20;
                for (int i = 0; i < 8; i++)
                    pop();
            end
        join

        #50;

        if (error_count == 0)
            $display("\n====== ALL TESTS PASSED SUCCESSFULLY ======\n");
        else
            $display("\n====== TEST FAILED WITH %0d ERRORS ======\n", error_count);

        $finish;
    end

endmodule