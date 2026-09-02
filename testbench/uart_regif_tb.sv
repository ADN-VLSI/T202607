`timescale 1ns/1ps
import uart_regif_pkg::*;

module uart_regif_tb;

    // ---------------------------------------------------------
    // Clock and Reset
    // ---------------------------------------------------------
    logic clk;
    logic arst_n;

    // ---------------------------------------------------------
    // Memory Interface Signals
    // ---------------------------------------------------------
    logic        mreq;
    logic        mwe;
    logic [31:0] maddr;
    logic [31:0] mwdata;
    logic [3:0]  mstrb;

    logic        mack;
    logic [31:0] mrdata;
    logic        mresp;

    // ---------------------------------------------------------
    // Hardware Status & Datapath
    // ---------------------------------------------------------
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

    int pass_count = 0;
    int fail_count = 0;

    // ---------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------
    uart_regif #(
        .ADDR_WIDTH  (32),
        .DATA_WIDTH  (32),
        .WSTRB_WIDTH (4)
    ) dut (
        .clk             (clk),
        .arst_n          (arst_n),
        .mreq            (mreq),
        .mwe             (mwe),
        .maddr           (maddr),
        .mwdata          (mwdata),
        .mstrb           (mstrb),
        .mack            (mack),
        .mrdata          (mrdata),
        .mresp           (mresp),
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
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // ---------------------------------------------------------
    // Bus Access Tasks
    // ---------------------------------------------------------
    task automatic write_reg(
        input logic [31:0] addr, 
        input logic [31:0] data, 
        input logic [3:0]  strb = 4'b1111
    );
        @(posedge clk);
        mreq   <= 1'b1;
        mwe    <= 1'b1;
        maddr  <= addr;
        mwdata <= data;
        mstrb  <= strb;
        
        do @(posedge clk); while (!mack);
        mreq   <= 1'b0;
        mwe    <= 1'b0;
    endtask

    task automatic read_reg(
        input  logic [31:0] addr, 
        output logic [31:0] rdata, 
        output logic        error
    );
        @(posedge clk);
        mreq   <= 1'b1;
        mwe    <= 1'b0;
        maddr  <= addr;
        mstrb  <= 4'b0000;
        
        do @(posedge clk); while (!mack);
        rdata = mrdata;
        error = mresp;
        
        mreq   <= 1'b0;
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
        arst_n          = 0;
        mreq            = 0;
        mwe             = 0;
        maddr           = '0;
        mwdata          = '0;
        mstrb           = '0;
        tx_fifo_count   = 0;
        rx_fifo_count   = 0;
        tx_busy         = 0;
        rx_busy         = 0;
        tx_data_ready_i = 1;
        rx_data_i       = 0;
        rx_data_valid_i = 0;

        // Apply Reset
        #20;
        arst_n = 1;
        #20;
        $display("\n===============================================");
        $display("          UART REGIF UNIT TESTBENCH            ");
        $display("===============================================");

        // -----------------------------------------------------
        // TEST 1: Register Read/Write (CFG Register)
        // -----------------------------------------------------
        $display("\n[TEST 1] Writing & Reading CFG Register (0x04)...");
        write_reg(ADDR_CFG, 32'h0005_1234, 4'b1111);
        read_reg(ADDR_CFG, read_data, read_err);
        if (read_data[15:0] == 16'h1234 && read_err == 0) begin
            $display("  -> PASS: CFG register write/read verified.");
            pass_count++;
        end else begin
            $display("  -> FAIL: CFG read mismatch! Data: 0x%h, Err: %b", read_data, read_err);
            fail_count++;
        end

        // -----------------------------------------------------
        // TEST 2: Byte Strobe Masking (WSTRB)
        // -----------------------------------------------------
        $display("\n[TEST 2] Testing Byte-Strobe Masking on CFG Register...");
        write_reg(ADDR_CFG, 32'h0000_AB00, 4'b0010);
        read_reg(ADDR_CFG, read_data, read_err);
        if (read_data[15:0] == 16'hAB34) begin
            $display("  -> PASS: Byte strobe successfully modified only byte 1 (0xAB34).");
            pass_count++;
        end else begin
            $display("  -> FAIL: Byte strobe mismatch! Expected 0xAB34, got 0x%h", read_data[15:0]);
            fail_count++;
        end

        // -----------------------------------------------------
        // TEST 3: Status Register Read (Read-Only)
        // -----------------------------------------------------
        $display("\n[TEST 3] Verifying STATUS Register (0x08)...");
        tx_busy       = 1'b1;
        rx_fifo_count = 10'd5;
        read_reg(ADDR_STATUS, read_data, read_err);
        if (read_data[20] == 1'b1 && read_data[19:10] == 10'd5 && read_err == 0) begin
            $display("  -> PASS: STATUS register correctly reflects hardware states.");
            pass_count++;
        end else begin
            $display("  -> FAIL: STATUS register read mismatch! Data: 0x%h", read_data);
            fail_count++;
        end

        // -----------------------------------------------------
        // TEST 4: TX FIFO Push Operation
        // -----------------------------------------------------
        $display("\n[TEST 4] Testing TX FIFO Push Handshake (0x0C)...");
        write_reg(ADDR_TXD, 32'h0000_00AA, 4'b1111);
        if (tx_data_valid_o == 1'b1 && tx_data_o == 8'hAA) begin
            $display("  -> PASS: TX FIFO push verified (Data: 0x%h).", tx_data_o);
            pass_count++;
        end else begin
            $display("  -> FAIL: TX FIFO push signals incorrect!");
            fail_count++;
        end

        // -----------------------------------------------------
        // TEST 5: RX FIFO Pop Operation
        // -----------------------------------------------------
        $display("\n[TEST 5] Testing RX FIFO Pop Handshake (0x10)...");
        rx_data_valid_i = 1'b1;
        rx_data_i       = 8'h55;
        read_reg(ADDR_RXD, read_data, read_err);
        if (rx_data_ready_o == 1'b1 && read_data[7:0] == 8'h55 && read_err == 0) begin
            $display("  -> PASS: RX FIFO pop verified (Data: 0x%h).", read_data[7:0]);
            pass_count++;
        end else begin
            $display("  -> FAIL: RX FIFO pop mismatch!");
            fail_count++;
        end
        rx_data_valid_i = 1'b0;

        // -----------------------------------------------------
        // TEST 6: Flush Pulse Auto-Clearing
        // -----------------------------------------------------
        $display("\n[TEST 6] Testing CTRL Flush Pulse Auto-Clearing...");
        write_reg(ADDR_CTRL, 32'h0000_000F, 4'b1111);
        @(posedge clk);
        read_reg(ADDR_CTRL, read_data, read_err);
        if (read_data[3:2] == 2'b00 && read_data[1:0] == 2'b11) begin
            $display("  -> PASS: Flush pulses auto-cleared, enable bits retained (0x%h).", read_data);
            pass_count++;
        end else begin
            $display("  -> FAIL: Flush pulses did not auto-clear! Data: 0x%h", read_data);
            fail_count++;
        end

        // -----------------------------------------------------
        // TEST 7: Invalid Address Error
        // -----------------------------------------------------
        $display("\n[TEST 7] Testing Invalid Address Error Detection...");
        read_reg(32'h0000_00FC, read_data, read_err);
        if (read_err == 1'b1) begin
            $display("  -> PASS: Invalid address generated error response.");
            pass_count++;
        end else begin
            $display("  -> FAIL: Invalid address did not trigger error response!");
            fail_count++;
        end

        $display("\n===============================================");
        $display("           TEST RESULTS SUMMARY                ");
        $display("===============================================");
        $display("PASS = %0d, FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0) $display("ALL UART REGIF UNIT TESTS PASSED!\n");
        $display("===============================================\n");

        #20;
        $finish;
    end

endmodule