`timescale 1ns/1ps

module apb_uart_top_tb;

    logic        clk_i, arst_ni;
    logic        psel_i, penable_i, pwrite_i;
    logic [31:0] paddr_i, pwdata_i;
    logic [3:0]  pstrb_i;
    logic        pready_o, perror_o;
    logic [31:0] prdata_o;
    logic        tx_pin, rx_pin;

    localparam int BAUD_PERIOD = 160; 

    apb_uart_top #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) dut (
        .clk_i(clk_i), .arst_ni(arst_ni),
        .psel_i(psel_i), .penable_i(penable_i), .pwrite_i(pwrite_i),
        .paddr_i(paddr_i), .pwdata_i(pwdata_i), .pstrb_i(pstrb_i),
        .pready_o(pready_o), .prdata_o(prdata_o), .perror_o(perror_o),
        .tx_o(tx_pin), .rx_i(rx_pin) 
    );

    // BUG FIX: Added #1 delay to completely prevent Race Conditions!
    task automatic apb_write(input logic [31:0] addr, input logic [31:0] data);
        @(posedge clk_i); #1; 
        psel_i = 1; penable_i = 0; pwrite_i = 1; paddr_i = addr; pwdata_i = data; pstrb_i = 4'hF;
        @(posedge clk_i); #1;
        penable_i = 1; wait(pready_o);
        @(posedge clk_i); #1;
        psel_i = 0; penable_i = 0;
    endtask

    task automatic apb_read(input logic [31:0] addr, output logic [31:0] data);
        @(posedge clk_i); #1;
        psel_i = 1; penable_i = 0; pwrite_i = 0; paddr_i = addr;
        @(posedge clk_i); #1;
        penable_i = 1; wait(pready_o);
        data = prdata_o;
        @(posedge clk_i); #1;
        psel_i = 0; penable_i = 0;
    endtask

    task automatic bfm_monitor_tx(output logic [7:0] captured_data);
        $display("[BFM] Monitoring TX pin for Start bit...");
        
        // BUG FIX: Timeout logic added to prevent XSim Crash!
        fork
            begin
                @(negedge tx_pin); 
            end
            begin
                #50000;
                $display("FATAL: Timeout! TX pin never went low.");
                $finish;
            end
        join_any
        disable fork; // Stop the timeout if start bit is found

        if (tx_pin == 0) $display("[BFM] Start bit verified.");
        
        #(BAUD_PERIOD / 2); // Wait half a period to center sample
        for (int i = 0; i < 8; i++) begin
            #(BAUD_PERIOD);
            captured_data[i] = tx_pin;
        end
        #(BAUD_PERIOD);
        if (tx_pin == 1) $display("[BFM] Stop bit verified.");
    endtask

    task automatic bfm_drive_rx(input logic [7:0] send_data);
        $display("[BFM] Driving 0x%h into RX pin...", send_data);
        rx_pin = 0; 
        #(BAUD_PERIOD);
        for (int i = 0; i < 8; i++) begin
            rx_pin = send_data[i]; 
            #(BAUD_PERIOD);
        end
        rx_pin = 1; 
        #(BAUD_PERIOD);
    endtask

    logic [7:0]  serial_captured;
    logic [31:0] apb_read_data;

    initial begin
        $dumpfile("apb_uart_wave.vcd");
        $dumpvars(0, apb_uart_top_tb);

        clk_i = 0; fork forever #5 clk_i = ~clk_i; join_none 
        arst_ni = 0; rx_pin = 1; 
        psel_i = 0; penable_i = 0; pwrite_i = 0; paddr_i = 0; pwdata_i = 0;

        #30 arst_ni = 1;
        $display("\n[System] Reset De-asserted.");

        apb_write(32'h04, 32'h0003_0010); 
        apb_write(32'h00, 32'h0000_0003); 

        $display("\n--- Starting TX Verification ---");
        fork
            begin
                $display("[CPU] Writing 0xCD to APB TXD (0x0C)");
                apb_write(32'h0C, 32'h0000_00CD);
            end
            begin
                bfm_monitor_tx(serial_captured);
            end
        join

        if (serial_captured == 8'hCD)
            $display(">>> [PASS] TX Test: BFM correctly caught 0xCD from hardware! <<<");
        else
            $display(">>> [FAIL] TX Test: BFM caught 0x%h, expected 0xCD <<<", serial_captured);

        #500; 
        $display("\n--- Starting RX Verification ---");
        bfm_drive_rx(8'hA5);
        #500; 

        $display("[CPU] Reading from APB RXD (0x10)");
        apb_read(32'h10, apb_read_data);

        if (apb_read_data[7:0] == 8'hA5)
            $display(">>> [PASS] RX Test: APB successfully read 0xA5 from hardware! <<<\n");
        else
            $display(">>> [FAIL] RX Test: APB read 0x%h, expected 0xA5 <<<\n", apb_read_data[7:0]);

        #100;
        $finish;
    end
endmodule