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

  task automatic drive_bit(input logic val);
    rx_o = val;
    #80;                 
  endtask

  task automatic send(input logic [7:0] data);
    int i;
    drive_bit(0);                    
    for (i = 0; i < 8; i++)
      drive_bit(data[i]);           
    drive_bit(1);                    
    #80;
  endtask


  initial begin
    // --- Background Clock Generation ---
    clk_i = 0;
    fork
      forever #5 clk_i = ~clk_i; // 100MHz clock (10ns period)
    join_none

    // --- Initialization & Reset ---
    arst_ni       = 0;
    rx_o          = 1;       // UART idle state is high
    num_bits_i    = 2'b11;   // 8 data bits
    parity_en_i   = 0;
    parity_type_i = 0;

    #20 arst_ni = 1;
    #20;

    $display("\n--- Starting UART Receiver Verification ---\n");

    // --- TEST 1: 8N1 (8 data bits, No Parity) ---
    $display("[TEST 1] Sending 8'hA5 (No Parity)...");
    fork
      begin
        send_uart_byte(8'hA5, 2'b11, 0, 0); // Send Data
      end
      begin
        // Monitor for valid data pulse
        @(posedge clk_i iff data_valid_o);
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
        @(posedge clk_i iff data_valid_o);
        if (data_o === 8'h3C) $display(" -> PASS: Received 8'h3C");
        else $display(" -> FAIL: Expected 8'h3C, Got 8'h%h", data_o);
      end
    join

    $dumpfile("uart_receiver_tb.vcd");
    $dumpvars(0, uart_receiver_tb);

    arst_ni = 0;
    clk_i   = 0;
    rx_o    = 1;
    num_bits_i = 2'b11;             
    parity_en_i = 0;
    parity_type_i = 0;

    #100;
    arst_ni = 1;
    #100;

    // clock
    fork
      forever #5 clk_i = ~clk_i;
    join_none

    @(posedge clk_i);

    send(8'hA5);
    send(8'hFF);
    send(8'h00);

    $finish;

    // --- Finish Simulation ---
    #100;
    $display("\n--- Verification Complete ---\n");
    $finish;
  end



always @(posedge clk_i)
    if (data_valid_o)
      $display("[%0t] got 0x%02h", $time, data_o);

endmodule