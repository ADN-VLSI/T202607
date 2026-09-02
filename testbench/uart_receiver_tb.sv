module uart_receiver_tb;

  logic       arst_ni;
  logic       clk_i;
  logic [1:0] num_bits_i;
  logic       parity_en_i;
  logic       parity_type_i;
  logic       rx_o;

  logic [7:0] data_o;
  logic       data_valid_o;

  // Instantiate the Device Under Test (DUT)
  uart_receiver #(.OVERSAMPLE(8)) dut (.*);

  // --- Task to simulate a UART Transmitter ---
  task automatic send_uart_byte(input logic [7:0] data, input logic [1:0] num_bits,
                                input logic parity_en, input logic parity_type);
    int   bit_clocks = 8;  // Matches OVERSAMPLE = 8
    int   total_bits = 5 + num_bits;  // e.g., num_bits=3 means 8 data bits
    logic parity_bit;

    // Calculate parity over the data bits being sent
    parity_bit = parity_type;
    for (int i = 0; i < total_bits; i++) begin
      parity_bit ^= data[i];
    end

    // 1. Start bit (Drive line low)
    rx_o = 0;
    repeat (bit_clocks) @(posedge clk_i);

    // 2. Data bits (Send LSB first)
    for (int i = 0; i < total_bits; i++) begin
      rx_o = data[i];
      repeat (bit_clocks) @(posedge clk_i);
    end

    // 3. Parity bit (if enabled)
    if (parity_en) begin
      rx_o = parity_bit;
      repeat (bit_clocks) @(posedge clk_i);
    end

    // 4. Stop bit (Drive line high)
    rx_o = 1;
    repeat (bit_clocks) @(posedge clk_i);

    // Idle space between frames
    repeat (bit_clocks) @(posedge clk_i);
  endtask

  initial begin
    // --- Background Clock Generation ---
    clk_i = 0;
    fork
      forever #5 clk_i = ~clk_i;  // 100MHz clock (10ns period)
    join_none

    // --- Initialization & Reset ---
    arst_ni       = 0;
    rx_o          = 1;  // UART idle state is high
    num_bits_i    = 2'b11;  // 8 data bits
    parity_en_i   = 0;
    parity_type_i = 0;

    #20 arst_ni = 1;
    #20;

    $display("\n--- Starting UART Receiver Verification ---\n");

    // --- TEST 1: 8N1 (8 data bits, No Parity) ---
    $display("[TEST 1] Sending 8'hA5 (No Parity)...");
    fork
      begin
        send_uart_byte(8'hA5, 2'b11, 0, 0);  // Send Data
      end
      begin
        // Monitor for valid data pulse
        wait (data_valid_o);
        if (data_o === 8'hA5) $display(" -> PASS: Received 8'hA5");
        else $display(" -> FAIL: Expected 8'hA5, Got 8'h%h", data_o);
      end
    join

    #50;

    // --- TEST 2: 8E1 (8 data bits, Even Parity) ---
    $display("[TEST 2] Sending 8'h3C (Even Parity)...");
    num_bits_i    = 2'b11;
    parity_en_i   = 1;
    parity_type_i = 0;
    fork
      begin
        send_uart_byte(8'h3C, 2'b11, 1, 0);
      end
      begin
        wait (data_valid_o);
        if (data_o === 8'h3C) $display(" -> PASS: Received 8'h3C");
        else $display(" -> FAIL: Expected 8'h3C, Got 8'h%h", data_o);
      end
    join

    // --- TEST 3: 8O1 (8 data bits, Odd Parity) ---
    $display("[TEST 3] Sending 8'h5A (Odd Parity)...");
    num_bits_i    = 2'b11;
    parity_en_i   = 1;
    parity_type_i = 1;
    fork
      begin
        send_uart_byte(8'h5A, 2'b11, 1, 1);
      end
      begin
        wait (data_valid_o);
        if (data_o === 8'h5A) $display(" -> PASS: Received 8'h5A");
        else $display(" -> FAIL: Expected 8'h5A, Got 8'h%h", data_o);
      end
    join

    // --- Finish Simulation ---
    #100;
    $display("\n--- Verification Complete ---\n");
    $finish;
  end

endmodule
