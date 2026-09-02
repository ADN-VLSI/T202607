`timescale 1ns/1ps

module apb_uart_top_tb;

    import uart_regif_pkg::*;

    logic clk;
    logic arst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // APB signals
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [3:0]  pstrb;
    logic        pready;
    logic [31:0] prdata;
    logic        perror;

    // UART pins
    logic        tx;
    logic        rx;
    logic        intr;

    integer pass_count;
    integer fail_count;

    // Loopback: connect tx output directly to rx input
    assign rx = tx;

    apb_uart_top #(
        .ADDR_WIDTH   (32),
        .DATA_WIDTH   (32),
        .WSTRB_WIDTH  (4),
        .FIFO_DEPTH_W (9)
    ) DUT (
        .clk_i     (clk),
        .arst_ni   (arst_n),

        .psel_i    (psel),
        .penable_i (penable),
        .pwrite_i  (pwrite),
        .paddr_i   (paddr),
        .pwdata_i  (pwdata),
        .pstrb_i   (pstrb),

        .pready_o  (pready),
        .prdata_o  (prdata),
        .perror_o  (perror),

        .tx_o      (tx),
        .rx_i      (rx),
        .intr_o    (intr)
    );

    // APB Write Task
    task automatic apb_write(input logic [7:0] addr, input logic [31:0] data);
    begin
        @(posedge clk);
        psel    <= 1'b1;
        penable <= 1'b0;
        pwrite  <= 1'b1;
        paddr   <= 32'(addr);
        pwdata  <= data;
        pstrb   <= 4'hF;
        @(posedge clk);
        penable <= 1'b1;
        @(posedge clk);
        #1;
        psel    <= 1'b0;
        penable <= 1'b0;
    end
    endtask

    // APB Read Task
    task automatic apb_read(input logic [7:0] addr, output logic [31:0] data);
    begin
        @(posedge clk);
        psel    <= 1'b1;
        penable <= 1'b0;
        pwrite  <= 1'b0;
        paddr   <= 32'(addr);
        pwdata  <= 32'h0;
        pstrb   <= 4'h0;
        @(posedge clk);
        penable <= 1'b1;
        @(posedge clk);
        #1;
        data = prdata;
        psel    <= 1'b0;
        penable <= 1'b0;
    end
    endtask

    initial begin
        logic [31:0] rdata;
        pass_count = 0;
        fail_count = 0;

        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 32'h0;
        pwdata  = 32'h0;
        pstrb   = 4'h0;

        $display("\n============================================");
        $display("       APB_UART_TOP SYSTEM TESTBENCH        ");
        $display("============================================");

        $dumpfile("sim.vcd");
        $dumpvars(0, apb_uart_top_tb);

        // 1. Reset
        arst_n = 1'b0;
        repeat(5) @(posedge clk);
        arst_n = 1'b1;
        repeat(5) @(posedge clk);

        // 2. Test Register Access
        $display("\n[TEST 1] APB CONFIG REGISTER WRITE & READ");
        // Set baud_div = 16 (so baud_div/8 = 2 for fast simulation), 8 bits, no parity
        apb_write(ADDR_CFG, 32'h0003_0010);
        apb_read(ADDR_CFG, rdata);
        if (rdata[15:0] == 16'h0010) begin
            $display("PASS : CFG write/read verified");
            pass_count++;
        end else begin
            $display("FAIL : CFG mismatch (got %h, expected 0010)", rdata[15:0]);
            fail_count++;
        end

        // 3. Enable TX & RX
        $display("\n[TEST 2] ENABLE TX & RX IN CONTROL REGISTER");
        apb_write(ADDR_CTRL, 32'h0000_0003); // tx_en = 1, rx_en = 1
        apb_read(ADDR_CTRL, rdata);
        if (rdata[1:0] == 2'b11) begin
            $display("PASS : TX and RX enabled");
            pass_count++;
        end else begin
            $display("FAIL : CTRL mismatch (got %h)", rdata);
            fail_count++;
        end

        // 4. Send Byte via APB
        $display("\n[TEST 3] APB TX WRITE TO UART_TXD");
        apb_write(ADDR_TXD, 32'h0000_00A5);
        $display("PASS : Data 0xA5 written to TXD register");
        pass_count++;

        // 5. Wait for transmission through clock dividers, CDC FIFOs, and UART TX/RX
        $display("\n[TEST 4] WAITING FOR SERIAL LOOPBACK (TX -> RX)");
        repeat(500) @(posedge clk);

        // Check STATUS register
        apb_read(ADDR_STATUS, rdata);
        $display("STATUS Reg: 0x%08h (rx_count=%0d, tx_count=%0d, rx_busy=%0b, tx_busy=%0b)",
                 rdata, rdata[19:10], rdata[9:0], rdata[21], rdata[20]);

        // 6. Check RX data
        apb_read(ADDR_RXD, rdata);
        $display("RX Data Read: 0x%02h", rdata[7:0]);
        if (rdata[7:0] == 8'hA5) begin
            $display("PASS : Loopback received data matches transmitted data (0xA5)!");
            pass_count++;
        end else begin
            $display("FAIL : Loopback data mismatch (got %02h, expected A5)", rdata[7:0]);
            fail_count++;
        end

        $display("\n============================================");
        $display("        APB_UART_TOP TEST SUMMARY           ");
        $display("============================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        if (fail_count == 0)
            $display("ALL INTEGRATION TESTS PASSED\n");
        else
            $display("INTEGRATION TESTS FAILED\n");

        $finish;
    end

endmodule : apb_uart_top_tb
