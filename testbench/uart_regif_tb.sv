`timescale 1ns/1ps
`include "uart_regif_pkg.sv"
`include "mem_if_pkg.sv"

import mem_if_pkg::*;
import uart_regif_pkg::*;

module uart_regif_tb;

    // ---------------------------------------------------------
    // Clock and Reset
    // ---------------------------------------------------------
    logic clk_i;
    logic rst_ni;

    // ---------------------------------------------------------
    // DUT Signals
    // ---------------------------------------------------------
    mem_req_t   mem_req_i;
    mem_resp_t  mem_resp_o;

    logic [9:0] tx_fifo_count;
    logic [9:0] rx_fifo_count;
    logic       tx_busy;
    logic       rx_busy;

    logic [7:0] tx_data_o;
    logic       tx_data_valid_o;
    logic       tx_data_ready_i;

    logic [7:0] rx_data_i;
    logic       rx_data_valid_i;
    logic       rx_data_ready_o;

    uart_ctrl_t ctrl_o;
    uart_cfg_t  cfg_o;
    uart_intr_t intr_o;

    // ---------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------
    uart_regif dut (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        .mem_req_i       (mem_req_i),
        .mem_resp_o      (mem_resp_o),
        .tx_fifo_count   (tx_fifo_count),
        .rx_fifo_count   (rx_fifo_count),
        .tx_busy         (tx_busy),
        .rx_busy         (rx_busy),
        .tx_data_o       (tx_data_o),
        .tx_data_valid_o (tx_data_valid_o),
        .tx_data_ready_i (tx_data_ready_i),
        .rx_data_i       (rx_data_i),
        .rx_data_valid_i (rx_data_valid_i),
        .rx_data_ready_o (rx_data_ready_o),
        .ctrl_o          (ctrl_o),
        .cfg_o           (cfg_o),
        .intr_o          (intr_o)
    );

    // ---------------------------------------------------------
    // Clock Generation
    // ---------------------------------------------------------
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100MHz clock
    end

    // ---------------------------------------------------------
    // Bus Access Tasks
    // ---------------------------------------------------------
    task automatic write_reg(
        input logic [7:0]  addr, 
        input logic [31:0] data, 
        input logic [3:0]  strb = 4'b1111
    );
        @(posedge clk_i);
        mem_req_i.valid = 1'b1;
        mem_req_i.write = 1'b1;
        mem_req_i.addr  = {24'd0, addr};
        mem_req_i.wdata = data;
        mem_req_i.strb  = strb;
        
        wait(mem_resp_o.ready);
        @(posedge clk_i);
        mem_req_i.valid = 1'b0;
        mem_req_i.write = 1'b0;
    endtask

    task automatic read_reg(
        input  logic [7:0]  addr, 
        output logic [31:0] rdata, 
        output logic        error
    );
        @(posedge clk_i);
        mem_req_i.valid = 1'b1;
        mem_req_i.write = 1'b0;
        mem_req_i.addr  = {24'd0, addr};
        
        wait(mem_resp_o.ready);
        rdata = mem_resp_o.rdata;
        error = mem_resp_o.error;
        
        @(posedge clk_i);
        mem_req_i.valid = 1'b0;
    endtask

    // ---------------------------------------------------------
    // Main Test Sequence
    // ---------------------------------------------------------
    logic [31:0] read_data;
    logic        read_err;

    initial begin
        $dumpfile("uart_regif.vcd");
        $dumpvars(0, uart_regif_tb);

        // Initialize Inputs
        rst_ni          = 0;
        mem_req_i       = '0;
        tx_fifo_count   = 0;
        rx_fifo_count   = 0;
        tx_busy         = 0;
        rx_busy         = 0;
        tx_data_ready_i = 1; // Assume TX FIFO is always ready for tests
        rx_data_i       = 0;
        rx_data_valid_i = 0;

        // Apply Reset
        #20;
        rst_ni = 1;
        #10;
        $display("\n===============================================");
        $display("          UART REGIF TESTBENCH STARTED         ");
        $display("===============================================\n");

        // -----------------------------------------------------
        // TEST 1: Register Read/Write (CFG Register)
        // -----------------------------------------------------
        $display("[TEST 1] Writing to CFG Register (0x04)...");
        // Write: baud_div = 16'h1234, num_bits = 2'd3 (17:16), parity_en = 1 (18)
        write_reg(ADDR_CFG, 32'h0005_1234, 4'b1111);
        
        $display("[TEST 1] Reading from CFG Register (0x04)...");
        read_reg(ADDR_CFG, read_data, read_err);
        if (read_data[15:0] == 16'h1234 && read_err == 0)
            $display("  -> SUCCESS: CFG register updated correctly.\n");
        else
            $display("  -> FAILED: CFG register read mismatch! Data: %h\n", read_data);

        // -----------------------------------------------------
        // TEST 2: Status Register Read (Read-Only)
        // -----------------------------------------------------
        $display("[TEST 2] Verifying STATUS Register (0x08)...");
        tx_busy       = 1'b1;
        rx_fifo_count = 10'd5;
        
        read_reg(ADDR_STATUS, read_data, read_err);
        // tx_busy is at bit 20, rx_fifo_count is at bits 19:10
        if (read_data[20] == 1'b1 && read_data[19:10] == 10'd5 && read_err == 0)
            $display("  -> SUCCESS: STATUS register read correctly.\n");
        else
            $display("  -> FAILED: STATUS register read mismatch!\n");

        // -----------------------------------------------------
        // TEST 3: TX FIFO Push Operation
        // -----------------------------------------------------
        $display("[TEST 3] Writing to TXD Register (0x0C)...");
        write_reg(ADDR_TXD, 32'h0000_00AA, 4'b1111);
        
        if (tx_data_valid_o == 1'b1 && tx_data_o == 8'hAA)
            $display("  -> SUCCESS: TX FIFO push verified (Data: %h).\n", tx_data_o);
        else
            $display("  -> FAILED: TX FIFO push signal not asserted!\n");

        // -----------------------------------------------------
        // TEST 4: RX FIFO Pop Operation
        // -----------------------------------------------------
        $display("[TEST 4] Reading from RXD Register (0x10)...");
        rx_data_valid_i = 1'b1; // Simulate RX FIFO having data
        rx_data_i       = 8'h55; // Dummy RX data
        
        read_reg(ADDR_RXD, read_data, read_err);
        if (rx_data_ready_o == 1'b1 && read_data[7:0] == 8'h55 && read_err == 0)
            $display("  -> SUCCESS: RX FIFO pop verified (Data: %h).\n", read_data[7:0]);
        else
            $display("  -> FAILED: RX FIFO pop mismatch!\n");
        
        rx_data_valid_i = 1'b0;

        // -----------------------------------------------------
        // TEST 5: Error Handling (Write to Read-Only Register)
        // -----------------------------------------------------
        $display("[TEST 5] Attempting to Write to STATUS Register (0x08)...");
        write_reg(ADDR_STATUS, 32'hFFFF_FFFF, 4'b1111);
        
        if (mem_resp_o.error == 1'b1)
            $display("  -> SUCCESS: Write to Read-Only register correctly triggered ERROR.\n");
        else
            $display("  -> FAILED: Write to Read-Only register did not trigger ERROR!\n");

        $display("===============================================");
        $display("            ALL TESTS COMPLETED                ");
        $display("===============================================\n");

        #20;
        $finish;
    end

endmodule