module uart_receiver_tb;

logic       arst_ni;
logic       clk_i;

logic       rx_i;

logic [1:0] num_bits_i;
logic       parity_en_i;
logic       parity_type_i;
logic       extra_stop_i;

logic [7:0] data_o;
logic       data_valid_o;
logic       parity_error_o;
logic       frame_error_o;


//////////////////////////////////////////////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////////////////////////////////////////////

uart_receiver u_dut (
    .arst_ni        (arst_ni),
    .clk_i          (clk_i),

    .rx_i           (rx_i),

    .num_bits_i     (num_bits_i),
    .parity_en_i    (parity_en_i),
    .parity_type_i  (parity_type_i),
    .extra_stop_i   (extra_stop_i),

    .data_o         (data_o),
    .data_valid_o   (data_valid_o),
    .parity_error_o (parity_error_o),
    .frame_error_o  (frame_error_o)
);


//////////////////////////////////////////////////////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////////////////////////////////////////////////////

initial begin

    clk_i = 1'b0;

    forever #5ns clk_i = ~clk_i;

end


//////////////////////////////////////////////////////////////////////////////////////////////////
// SEND UART FRAME
//////////////////////////////////////////////////////////////////////////////////////////////////

task automatic send (
    input logic [7:0] data,
    input logic [1:0] num_bits    = 2'b11,
    input logic       parity_en   = 1'b0,
    input logic       parity_type = 1'b0,
    input logic       extra_stop  = 1'b0
);

    logic parity;
    integer i;

begin

    // Configure receiver

    num_bits_i    <= num_bits;
    parity_en_i   <= parity_en;
    parity_type_i <= parity_type;
    extra_stop_i  <= extra_stop;

    // Calculate parity
    parity = ^data;

    // Wait for falling edge before start bit
    @(negedge clk_i);

    //////////////////////////////////////////////////////////////////////
    // START BIT
    //////////////////////////////////////////////////////////////////////

    rx_i <= 1'b0;

    @(negedge clk_i);

    //////////////////////////////////////////////////////////////////////
    // DATA BITS
    //////////////////////////////////////////////////////////////////////

    for (i = 0; i < (5 + num_bits); i = i + 1) begin

        rx_i <= data[i];

        @(negedge clk_i);

    end

    //////////////////////////////////////////////////////////////////////
    // PARITY
    //////////////////////////////////////////////////////////////////////

    if (parity_en) begin

        if (parity_type)
            rx_i <= ~parity;
        else
            rx_i <= parity;

        @(negedge clk_i);

    end

    //////////////////////////////////////////////////////////////////////
    // STOP BIT
    //////////////////////////////////////////////////////////////////////

    rx_i <= 1'b1;

    @(negedge clk_i);

    //////////////////////////////////////////////////////////////////////
    // EXTRA STOP
    //////////////////////////////////////////////////////////////////////

    if (extra_stop) begin

        rx_i <= 1'b1;

        @(negedge clk_i);

    end

    //////////////////////////////////////////////////////////////////////
    // IDLE
    //////////////////////////////////////////////////////////////////////

    rx_i <= 1'b1;

    // Wait for receiver to report valid data
    @(posedge clk_i);

    if (data_valid_o) begin

        if (data_o == data) begin

            $display(
                "[PASS] DATA = %02h",
                data_o
            );

        end
        else begin

            $display(
                "[FAIL] EXPECTED = %02h RECEIVED = %02h",
                data,
                data_o
            );

        end

    end
    else begin

        $display("[FAIL] data_valid_o not asserted");

    end

    if (parity_error_o)
        $display("[ERROR] Parity error");

    if (frame_error_o)
        $display("[ERROR] Frame error");

end

endtask


//////////////////////////////////////////////////////////////////////////////////////////////////
// TEST
//////////////////////////////////////////////////////////////////////////////////////////////////

initial begin

    $dumpfile("uart_receiver_tb.vcd");
    $dumpvars(0, uart_receiver_tb);


    //////////////////////////////////////////////////////////////////////
    // INITIAL VALUES
    //////////////////////////////////////////////////////////////////////

    arst_ni       = 1'b0;
    rx_i          = 1'b1;

    num_bits_i    = 2'b00;
    parity_en_i   = 1'b0;
    parity_type_i = 1'b0;
    extra_stop_i  = 1'b0;


    //////////////////////////////////////////////////////////////////////
    // RESET
    //////////////////////////////////////////////////////////////////////

    #100ns;

    arst_ni = 1'b1;

    @(posedge clk_i);


    //////////////////////////////////////////////////////////////////////
    // TEST 1
    // 5-bit, no parity
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 1: 5-bit");

    send(
        8'h15,
        2'b00,
        1'b0,
        1'b0,
        1'b0
    );


    //////////////////////////////////////////////////////////////////////
    // TEST 2
    // 6-bit, no parity
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 2: 6-bit");

    send(
        8'h2A,
        2'b01,
        1'b0,
        1'b0,
        1'b0
    );


    //////////////////////////////////////////////////////////////////////
    // TEST 3
    // 7-bit + parity
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 3: 7-bit + parity");

    send(
        8'h55,
        2'b10,
        1'b1,
        1'b0,
        1'b0
    );


    //////////////////////////////////////////////////////////////////////
    // TEST 4
    // 8-bit + parity
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 4: 8-bit + parity");

    send(
        8'hA5,
        2'b11,
        1'b1,
        1'b0,
        1'b0
    );


    //////////////////////////////////////////////////////////////////////
    // TEST 5
    // 8-bit + inverted parity
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 5: 8-bit + inverted parity");

    send(
        8'hFF,
        2'b11,
        1'b1,
        1'b1,
        1'b0
    );


    //////////////////////////////////////////////////////////////////////
    // TEST 6
    // 8-bit + parity + extra stop
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("TEST 6: 8-bit + parity + extra stop");

    send(
        8'h00,
        2'b11,
        1'b1,
        1'b0,
        1'b1
    );


    //////////////////////////////////////////////////////////////////////
    // BACK-TO-BACK
    //////////////////////////////////////////////////////////////////////

    $display("");
    $display("====================================");
    $display("BACK-TO-BACK TEST");
    $display("====================================");

    send(8'hA5, 2'b11, 1'b1, 1'b0, 1'b0);
    send(8'hFF, 2'b11, 1'b1, 1'b0, 1'b0);
    send(8'h00, 2'b11, 1'b1, 1'b0, 1'b0);
    send(8'h55, 2'b11, 1'b1, 1'b0, 1'b0);


    //////////////////////////////////////////////////////////////////////
    // FINISH
    //////////////////////////////////////////////////////////////////////

    #100ns;

    $display("");
    $display("====================================");
    $display("UART RECEIVER TEST COMPLETE");
    $display("====================================");

    $finish;

end

endmodule