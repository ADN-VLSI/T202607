// ==============================================================================================
// #  | Test task                   | What it tests
// ===+=============================+============================================================
// 1  | test_reset                  | Reset/default CTRL state
// 2  | test_cfg_register           | CFG register APB write/read
// 3  | test_ctrl_register          | CTRL register APB write/read
// 4  | test_single_byte_loopback   | Send A5, receive A5
// 5  | test_data_patterns          | Loopback 00, FF, 55, AA
// 6  | test_multiple_byte_loopback | Multiple bytes maintain FIFO order
// 7  | test_status_register        | Read and check FIFO/status information
// 8  | test_ctrl_disable_enable    | Write 00 then 03 to CTRL and verify readback
// 9  | test_cfg_change             | Change baud_div and verify CFG readback
// 10 | test_repeated_same_byte     | Send same byte several times and receive it several times
// ==============================================================================================

module apb_uart_top_tb;

    import uart_regif_pkg::*;

    logic clk;
    logic arst_n;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [3:0]  pstrb;
    logic        pready;
    logic [31:0] prdata;
    logic        perror;
    logic tx;
    logic rx;
    logic intr;

    integer pass_count;
    integer fail_count;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

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

    task automatic reset_dut;
    begin
        arst_n  = 1'b0;
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 32'h0;
        pwdata  = 32'h0;
        pstrb   = 4'h0;
        repeat (5) @(posedge clk);
        arst_n = 1'b1;
        repeat (5) @(posedge clk);
    end
    endtask

    task automatic apb_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );
    begin
        @(posedge clk);
        psel    <= 1'b1;
        penable <= 1'b0;
        pwrite  <= 1'b1;
        paddr   <= addr;
        pwdata  <= data;
        pstrb   <= 4'hF;

        @(posedge clk);
        penable <= 1'b1;

        do begin
            @(posedge clk);
        end while (!pready);

        #1;
        psel    <= 1'b0;
        penable <= 1'b0;
        pwrite  <= 1'b0;
    end
    endtask

    task automatic apb_read(
        input  logic [31:0] addr,
        output logic [31:0] data
    );
    begin
        @(posedge clk);
        psel    <= 1'b1;
        penable <= 1'b0;
        pwrite  <= 1'b0;
        paddr   <= addr;
        pwdata  <= 32'h0;
        pstrb   <= 4'h0;

        @(posedge clk);
        penable <= 1'b1;

        do begin
            @(posedge clk);
        end while (!pready);

        #1;
        data = prdata;
        psel    <= 1'b0;
        penable <= 1'b0;
    end
    endtask

    task automatic test_reset;
        logic [31:0] rdata;
    begin
        $display("TEST 1 : RESET");
        reset_dut();
        apb_read(ADDR_CTRL, rdata);
        if (rdata == 32'h0000_0000) begin
            $display("PASS : CTRL reset value = 0x%08h", rdata);
            pass_count++;
        end else begin
            $display("FAIL : CTRL reset value = 0x%08h, expected 0", rdata);
            fail_count++;
        end
    end
    endtask

    task automatic test_cfg_register;
        logic [31:0] rdata;
        logic [31:0] cfg_value;
    begin
        $display("TEST 2 : CFG REGISTER WRITE / READ");
        cfg_value = 32'h0003_0010;
        apb_write(ADDR_CFG, cfg_value);
        apb_read(ADDR_CFG, rdata);
        if (rdata == cfg_value) begin
            $display("PASS : CFG expected = %08h, received = %08h", cfg_value, rdata);
            pass_count++;
        end else begin
            $display("FAIL : CFG expected = %08h, received = %08h", cfg_value, rdata);
            fail_count++;
        end
    end
    endtask

    task automatic test_ctrl_register;
        logic [31:0] rdata;
    begin
        $display("TEST 3 : CTRL REGISTER WRITE / READ");
        apb_write(ADDR_CTRL, 32'h0000_0003);
        apb_read(ADDR_CTRL, rdata);
        if (rdata[1:0] == 2'b11) begin
            $display("PASS : TX enable = %0b, RX enable = %0b", rdata[0], rdata[1]);
            pass_count++;
        end else begin
            $display("FAIL : CTRL[1:0] = %02b, expected 11", rdata[1:0]);
            fail_count++;
        end
    end
    endtask

    task automatic test_single_byte_loopback;
        logic [31:0] rdata;
    begin
        $display("TEST 4 : SINGLE BYTE UART LOOPBACK");
        apb_write(ADDR_TXD, 32'h0000_00A5);
        repeat (500) @(posedge clk);
        apb_read(ADDR_RXD, rdata);
        if (rdata[7:0] == 8'hA5) begin
            $display("PASS : TX = A5, RX = %02h", rdata[7:0]);
            pass_count++;
        end else begin
            $display("FAIL : TX = A5, RX = %02h", rdata[7:0]);
            fail_count++;
        end
    end
    endtask

    task automatic test_data_patterns;
        logic [31:0] rdata;
        logic [7:0] patterns [0:3];
    begin
        $display("TEST 5 : DIFFERENT UART DATA PATTERNS");
        patterns[0] = 8'h00;
        patterns[1] = 8'hFF;
        patterns[2] = 8'h55;
        patterns[3] = 8'hAA;

        for (int i = 0; i < 4; i++) begin
            apb_write(ADDR_TXD, {24'h0, patterns[i]});
            repeat (500) @(posedge clk);
            apb_read(ADDR_RXD, rdata);
            if (rdata[7:0] == patterns[i]) begin
                $display("PASS : TX = %02h, RX = %02h", patterns[i], rdata[7:0]);
                pass_count++;
            end else begin
                $display("FAIL : TX = %02h, RX = %02h", patterns[i], rdata[7:0]);
                fail_count++;
            end
        end
    end
    endtask

    task automatic test_multiple_byte_loopback;
        logic [31:0] rdata;
        logic [7:0] test_data [0:3];
    begin
        $display("TEST 6 : MULTIPLE BYTE LOOPBACK");
        test_data[0] = 8'h12;
        test_data[1] = 8'h34;
        test_data[2] = 8'h56;
        test_data[3] = 8'h78;

        for (int i = 0; i < 4; i++) begin
            apb_write(ADDR_TXD, {24'h0, test_data[i]});
        end

        repeat (2000) @(posedge clk);

        for (int i = 0; i < 4; i++) begin
            apb_read(ADDR_RXD, rdata);
            if (rdata[7:0] == test_data[i]) begin
                $display("PASS : Byte %0d : TX = %02h, RX = %02h", i, test_data[i], rdata[7:0]);
                pass_count++;
            end else begin
                $display("FAIL : Byte %0d : TX = %02h, RX = %02h", i, test_data[i], rdata[7:0]);
                fail_count++;
            end
        end
    end
    endtask

    task automatic test_status_register;
        logic [31:0] rdata;
    begin
        $display("TEST 7 : STATUS REGISTER");
        apb_read(ADDR_STATUS, rdata);
        $display("STATUS = 0x%08h", rdata);
        $display("TX FIFO count = %0d", rdata[9:0]);
        $display("RX FIFO count = %0d", rdata[19:10]);
        $display("TX busy = %0b", rdata[20]);
        $display("RX busy = %0b", rdata[21]);

        if (rdata[19:10] == 10'd0) begin
            $display("PASS : RX FIFO is empty after reading all data");
            pass_count++;
        end else begin
            $display("FAIL : RX FIFO count = %0d, expected 0", rdata[19:10]);
            fail_count++;
        end
    end
    endtask

    task automatic test_ctrl_disable_enable;
        logic [31:0] rdata;
    begin
        $display("TEST 8 : CTRL DISABLE / ENABLE");
        apb_write(ADDR_CTRL, 32'h0000_0000);
        apb_read(ADDR_CTRL, rdata);

        if (rdata[1:0] == 2'b00) begin
            $display("PASS : TX and RX disabled correctly");
            pass_count++;
        end else begin
            $display("FAIL : Expected CTRL[1:0] = 00, got %02b", rdata[1:0]);
            fail_count++;
        end

        apb_write(ADDR_CTRL, 32'h0000_0003);
        apb_read(ADDR_CTRL, rdata);

        if (rdata[1:0] == 2'b11) begin
            $display("PASS : TX and RX enabled correctly");
            pass_count++;
        end else begin
            $display("FAIL : Expected CTRL[1:0] = 11, got %02b", rdata[1:0]);
            fail_count++;
        end
    end
    endtask

    task automatic test_cfg_change;
        logic [31:0] rdata;
    begin
        $display("TEST 9 : CHANGE BAUD CONFIGURATION");
        apb_write(ADDR_CFG, 32'h0003_0020);
        apb_read(ADDR_CFG, rdata);

        if (rdata[15:0] == 16'h0020) begin
            $display("PASS : baud_div changed to %0d", rdata[15:0]);
            pass_count++;
        end else begin
            $display("FAIL : Expected baud_div = 32, got %0d", rdata[15:0]);
            fail_count++;
        end

        apb_write(ADDR_CFG, 32'h0003_0010);
    end
    endtask

    task automatic test_repeated_same_byte;
        logic [31:0] rdata;
    begin
        $display("TEST 10 : REPEATED SAME BYTE");
        for (int i = 0; i < 4; i++) begin
            apb_write(ADDR_TXD, 32'h0000_005A);
        end

        repeat (2000) @(posedge clk);

        for (int i = 0; i < 4; i++) begin
            apb_read(ADDR_RXD, rdata);
            if (rdata[7:0] == 8'h5A) begin
                $display("PASS : Byte %0d received = %02h", i, rdata[7:0]);
                pass_count++;
            end else begin
                $display("FAIL : Byte %0d expected 5A, got %02h", i, rdata[7:0]);
                fail_count++;
            end
        end
    end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        arst_n  = 1'b0;
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 32'h0;
        pwdata  = 32'h0;
        pstrb   = 4'h0;

        $dumpfile("sim.vcd");
        $dumpvars(0, apb_uart_top_tb);

        $display("APB UART LINEAR TESTBENCH");

        test_reset();
        test_cfg_register();
        test_ctrl_register();
        test_single_byte_loopback();
        test_data_patterns();
        test_multiple_byte_loopback();
        test_status_register();
        test_ctrl_disable_enable();
        test_cfg_change();
        test_repeated_same_byte();

        $display("FINAL TEST SUMMARY");
        $display("TOTAL PASS = %0d", pass_count);
        $display("TOTAL FAIL = %0d", fail_count);

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end

        $finish;
    end

endmodule : apb_uart_top_tb