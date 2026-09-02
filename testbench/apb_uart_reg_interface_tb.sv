`timescale 1ns/1ps

import mem_if_pkg::*;
import uart_regif_pkg::*;

module apb_uart_reg_interface_tb;

    // =========================================================
    // 1: Signal Declarations & Clock/Reset
    // =========================================================
    logic clk_i;
    logic rst_ni;

    mem_req_t     req_i;
    mem_resp_t    resp_o;
    uart_ctrl_t   ctrl_o;
    uart_cfg_t    cfg_o;
    uart_intr_t   intr_o;
    uart_status_t status_i;

    logic [7:0] tx_data_o;
    logic       tx_push_o;
    logic [7:0] rx_data_i;
    logic       rx_pop_o;

    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz Clock
    end

    // =========================================================
    // 2: DUT Instantiation
    // =========================================================
    apb_uart_reg_interface dut (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .req_i      (req_i),
        .resp_o     (resp_o),
        .ctrl_o     (ctrl_o),
        .cfg_o      (cfg_o),
        .intr_o     (intr_o),
        .status_i   (status_i),
        .tx_data_o  (tx_data_o),
        .tx_push_o  (tx_push_o),
        .rx_data_i  (rx_data_i),
        .rx_pop_o   (rx_pop_o)
    );

    // =========================================================
    // 3: Bus Access Tasks (Simplifies Reading/Writing)
    // =========================================================
    task automatic write_reg(input logic [7:0] addr, input logic [31:0] data);
        @(posedge clk_i);
        req_i.valid = 1'b1;
        req_i.write = 1'b1;
        req_i.addr  = addr;
        req_i.wdata = data;
        
        wait(resp_o.ready);
        @(posedge clk_i);
        req_i.valid = 1'b0;
        req_i.write = 1'b0;
    endtask

    task automatic read_reg(input logic [7:0] addr, output logic [31:0] rdata, output logic err);
        @(posedge clk_i);
        req_i.valid = 1'b1;
        req_i.write = 1'b0;
        req_i.addr  = addr;
        
        wait(resp_o.ready);
        rdata = resp_o.rdata;
        err   = resp_o.error;
        
        @(posedge clk_i);
        req_i.valid = 1'b0;
    endtask

    // =========================================================
    // 4: Main Test Sequence
    // =========================================================
    logic [31:0] read_data;
    logic        read_err;

    initial begin
        // Initialize Default Values
        rst_ni   = 1'b0;
        req_i    = '0;
        status_i = '0;
        rx_data_i = 8'h00;

        $display("\n===============================================");
        $display("   STARTING UART REGISTER INTERFACE TESTS      ");
        $display("===============================================\n");

        // ---------------------------------------------------------
        // Task: Reset & Default Value Tests
        // ---------------------------------------------------------
        #20 rst_ni = 1'b1; // Release Reset
        @(posedge clk_i);
        
        if (cfg_o.baud_div == 16'h28B0 && ctrl_o.tx_en == 1'b0)
            $display("[PASS] TC 1 & 2: Reset values are correctly assigned.");
        else
            $display("[FAIL] TC 1 & 2: Reset values mismatch!");

        // ---------------------------------------------------------
        // Task: Register Read/Write Data Path Test
        // ---------------------------------------------------------
        // Write to CFG (0x04)
        write_reg(8'h04, 32'h0007_AABB); 
        read_reg(8'h04, read_data, read_err);
        
        if (read_data[15:0] == 16'hAABB && read_err == 1'b0)
            $display("[PASS] TC 3: Write and Read-back successful on CFG register.");
        else
            $display("[FAIL] TC 3: Data mismatch on CFG register.");

        // ---------------------------------------------------------
        // Task: Read-Only Violation Test
        // ---------------------------------------------------------
        write_reg(8'h08, 32'hFFFF_FFFF); // Try writing to STATUS (0x08)
        if (resp_o.error == 1'b1)
            $display("[PASS] TC 5: Read-only violation correctly triggered error.");
        else
            $display("[FAIL] TC 5: No error on writing to read-only register!");

        // ---------------------------------------------------------
        // Task: Invalid Address Test
        // ---------------------------------------------------------
        write_reg(8'h99, 32'h1234_5678); // 0x99 is not mapped
        if (resp_o.error == 1'b1)
            $display("[PASS] TC 6: Invalid address correctly triggered error.");
        else
            $display("[FAIL] TC 6: No error on invalid address!");

        // ---------------------------------------------------------
        // Task: Pulse Generation Test
        // ---------------------------------------------------------
        // Write 1 to tx_flush (bit 2) of CTRL register
        write_reg(8'h00, 32'h0000_0004); 
        
        // Wait one cycle and check if it auto-clears
        @(posedge clk_i);
        if (ctrl_o.tx_flush == 1'b0)
            $display("[PASS] TC 7: Flush signal automatically cleared (Pulse generated).");
        else
            $display("[FAIL] TC 7: Flush signal did NOT auto-clear!");

        // ---------------------------------------------------------
        // Task: TX FIFO Push Test
        // ---------------------------------------------------------
        write_reg(8'h0C, 32'h0000_00CD); // ADDR_TXD
        if (tx_data_o == 8'hCD && tx_push_o == 1'b1)
            $display("[PASS] TC 8: TX FIFO push signal and data generated correctly.");
        else
            $display("[FAIL] TC 8: TX FIFO push failed!");

        // ---------------------------------------------------------
        // Task: RX FIFO Pop Test
        // ---------------------------------------------------------
        rx_data_i = 8'h55; // Provide dummy data from hardware
        read_reg(8'h10, read_data, read_err); // Read from ADDR_RXD
        
        if (read_data[7:0] == 8'h55 && rx_pop_o == 1'b1)
            $display("[PASS] TC 9: RX FIFO pop signal and data read correctly.");
        else
            $display("[FAIL] TC 9: RX FIFO pop failed!");

        $display("\n===============================================");
        $display("              ALL TESTS COMPLETED              ");
        $display("===============================================\n");

        #20 $finish;
    end

endmodule