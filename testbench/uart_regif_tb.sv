`timescale 1ns/1ps

module uart_regif_tb;

    import uart_regif_pkg::*;

    localparam int ADDR_WIDTH  = 32;
    localparam int DATA_WIDTH  = 32;
    localparam int WSTRB_WIDTH = DATA_WIDTH / 8;

    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Flat memory interface signals
    logic                    mem_valid_sig;
    logic                    mem_write_sig;
    logic [ADDR_WIDTH-1:0]   mem_addr_sig;
    logic [DATA_WIDTH-1:0]   mem_wdata_sig;
    logic [WSTRB_WIDTH-1:0]  mem_wstrb_sig;

    logic                    mem_ready_sig;
    logic [DATA_WIDTH-1:0]   mem_rdata_sig;
    logic                    mem_error_sig;

    logic [9:0] tx_fifo_count;
    logic [9:0] rx_fifo_count;

    logic tx_busy;
    logic rx_busy;

    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_ready;

    uart_ctrl_t ctrl;
    uart_cfg_t  cfg;
    uart_intr_t intr;

    integer pass_count;
    integer fail_count;

    uart_regif #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) DUT (
        .clk             (clk),
        .arst_n          (rst_n),
        .mreq            (mem_valid_sig),
        .mwe             (mem_write_sig),
        .maddr           (mem_addr_sig),
        .mwdata          (mem_wdata_sig),
        .mstrb           (mem_wstrb_sig),
        .mack            (mem_ready_sig),
        .mrdata          (mem_rdata_sig),
        .mresp           (mem_error_sig),
        .tx_fifo_count   (tx_fifo_count),
        .rx_fifo_count   (rx_fifo_count),
        .tx_busy         (tx_busy),
        .rx_busy         (rx_busy),
        .tx_data_o       (tx_data),
        .tx_data_valid_o (tx_valid),
        .tx_data_ready_i (tx_ready),
        .rx_data_i       (rx_data),
        .rx_data_valid_i (rx_valid),
        .rx_data_ready_o (rx_ready),
        .ctrl_o          (ctrl),
        .cfg_o           (cfg),
        .intr_o          (intr)
    );

    task automatic mem_write(input logic [7:0] addr, input logic [31:0] data);
    begin
        @(posedge clk);
        mem_valid_sig <= 1'b1;
        mem_write_sig <= 1'b1;
        mem_addr_sig  <= 32'(addr);
        mem_wdata_sig <= data;
        mem_wstrb_sig <= 4'hF;
        @(posedge clk);
        #1;
        mem_valid_sig <= 1'b0;
    end
    endtask

    task automatic mem_read(input logic [7:0] addr, output logic [31:0] data);
    begin
        @(posedge clk);
        mem_valid_sig <= 1'b1;
        mem_write_sig <= 1'b0;
        mem_addr_sig  <= 32'(addr);
        mem_wdata_sig <= 32'h0;
        mem_wstrb_sig <= 4'h0;
        @(posedge clk);
        #1;
        data = mem_rdata_sig;
        mem_valid_sig <= 1'b0;
    end
    endtask

    task reset_test();
    begin
        $display("\n[TEST 1] RESET VALUES");
        if((ctrl == CTRL_RST) && (cfg == CFG_RST) && (intr == INTR_RST)) begin
            $display("PASS : Reset values correct"); pass_count++;
        end else begin
            $display("FAIL : Reset values wrong"); fail_count++;
        end
    end
    endtask

    task ctrl_write_test();
    begin
        $display("\n[TEST 2] CTRL WRITE");
        mem_write(ADDR_CTRL, 32'h00000003);
        if(ctrl.tx_en && ctrl.rx_en) begin
            $display("PASS : CTRL write successful"); pass_count++;
        end else begin
            $display("FAIL : CTRL write failed"); fail_count++;
        end
    end
    endtask

    task cfg_write_test();
    begin
        $display("\n[TEST 3] CFG WRITE");
        mem_write(ADDR_CFG, 32'h00001234);
        if(cfg.baud_div == 16'h1234) begin
            $display("PASS : CFG write successful"); pass_count++;
        end else begin
            $display("FAIL : CFG write failed"); fail_count++;
        end
    end
    endtask

    task ctrl_read_test();
        logic [31:0] rdata;
    begin
        $display("\n[TEST 4] CTRL READ");
        mem_read(ADDR_CTRL, rdata);
        if(rdata == ctrl) begin
            $display("PASS : CTRL read successful"); pass_count++;
        end else begin
            $display("FAIL : CTRL read failed"); fail_count++;
        end
    end
    endtask

    task status_read_test();
        logic [31:0] rdata;
    begin
        $display("\n[TEST 5] STATUS READ");
        mem_read(ADDR_STATUS, rdata);
        if((rdata[20] == tx_busy) && (rdata[21] == rx_busy)) begin
            $display("PASS : STATUS read successful"); pass_count++;
        end else begin
            $display("FAIL : STATUS read failed"); fail_count++;
        end
    end
    endtask

    task txd_write_test();
    begin
        $display("\n[TEST 6] TXD WRITE PATH");
        @(posedge clk);
        mem_valid_sig = 1'b1;
        mem_write_sig = 1'b1;
        mem_addr_sig  = 32'(ADDR_TXD);
        mem_wdata_sig = 32'h000000A5;
        mem_wstrb_sig = 4'hF;
        #1;
        if((tx_data == 8'hA5) && tx_valid) begin
            $display("PASS : TX path working"); pass_count++;
        end else begin
            $display("FAIL : TX path failed"); fail_count++;
        end
        @(posedge clk);
        mem_valid_sig = 1'b0;
    end
    endtask

    task rxd_read_test();
        logic [31:0] rdata;
    begin
        $display("\n[TEST 7] RXD READ PATH");
        mem_read(ADDR_RXD, rdata);
        if(rdata[7:0] == rx_data) begin
            $display("PASS : RX path working"); pass_count++;
        end else begin
            $display("FAIL : RX path failed"); fail_count++;
        end
    end
    endtask

    task invalid_address_test();
        logic [31:0] rdata;
    begin
        $display("\n[TEST 8] INVALID ADDRESS");
        mem_read(8'h80, rdata);
        if(mem_error_sig) begin
            $display("PASS : Invalid address detected"); pass_count++;
        end else begin
            $display("FAIL : Invalid address not detected"); fail_count++;
        end
    end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        mem_valid_sig = 1'b0;
        mem_write_sig = 1'b0;
        mem_addr_sig  = 32'h0;
        mem_wdata_sig = 32'h0;
        mem_wstrb_sig = 4'h0;
        tx_fifo_count = 10'd5;
        rx_fifo_count = 10'd2;
        tx_busy = 1'b0;
        rx_busy = 1'b1;
        tx_ready = 1'b1;
        rx_data  = 8'h55;
        rx_valid = 1'b1;

        rst_n = 1'b0;
        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        reset_test();
        ctrl_write_test();
        cfg_write_test();
        ctrl_read_test();
        status_read_test();
        txd_write_test();
        rxd_read_test();
        invalid_address_test();

        $display("\n==============================");
        $display("   UART REGIF TEST SUMMARY");
        $display("==============================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if(fail_count == 0)
            $display("ALL TESTS PASSED\n");
        else
            $display("TEST FAILED\n");

        $finish;
    end

endmodule
