`timescale 1ns/1ps

module apb_uart_register_interface_tb;

    import uart_regif_pkg::*;

    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---------------- APB slave-driving signals ----------------
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [3:0]  pstrb;

    logic        pready;
    logic [31:0] prdata;
    logic        perror;

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

    apb_uart_register_interface DUT (
        .clk_i           (clk),
        .rst_ni          (rst_n),

        .psel_i          (psel),
        .penable_i       (penable),
        .pwrite_i        (pwrite),
        .paddr_i         (paddr),
        .pwdata_i        (pwdata),
        .pstrb_i         (pstrb),

        .pready_o        (pready),
        .prdata_o        (prdata),
        .perror_o        (perror),

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

    // ---------------- APB driver tasks (SETUP -> ACCESS) ----------------
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
        @(posedge clk);          // zero-wait-state slave: PREADY already high here
        #1;                      // let DUT's NBA-scheduled register update settle
        psel    <= 1'b0;
        penable <= 1'b0;
    end
    endtask

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
        #1;                      // let combinational prdata path settle before sampling
        data = prdata;
        psel    <= 1'b0;
        penable <= 1'b0;
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
        apb_write(ADDR_CTRL, 32'h00000003);
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
        apb_write(ADDR_CFG, 32'h00001234);
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
        apb_read(ADDR_CTRL, rdata);
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
        apb_read(ADDR_STATUS, rdata);
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
        psel    = 1'b1;
        penable = 1'b0;
        pwrite  = 1'b1;
        paddr   = 32'(ADDR_TXD);
        pwdata  = 32'h000000A5;
        pstrb   = 4'hF;
        @(posedge clk);
        penable = 1'b1;
        #1;
        if((tx_data == 8'hA5) && tx_valid) begin
            $display("PASS : TX path working"); pass_count++;
        end else begin
            $display("FAIL : TX path failed"); fail_count++;
        end
        @(posedge clk);
        psel    = 1'b0;
        penable = 1'b0;
    end
    endtask

    task rxd_read_test();
        logic [31:0] rdata;
    begin
        $display("\n[TEST 7] RXD READ PATH");
        apb_read(ADDR_RXD, rdata);
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
        apb_read(8'h80, rdata);
        if(perror) begin
            $display("PASS : Invalid address detected"); pass_count++;
        end else begin
            $display("FAIL : Invalid address not detected"); fail_count++;
        end
    end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 32'h0;
        pwdata  = 32'h0;
        pstrb   = 4'h0;

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

        $display("\n==========================================");
        $display(" APB_UART_REGISTER_INTERFACE TEST SUMMARY");
        $display("==========================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if(fail_count == 0)
            $display("ALL TESTS PASSED\n");
        else
            $display("TEST FAILED\n");

        $finish;
    end

endmodule
