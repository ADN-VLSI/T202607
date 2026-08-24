interface uart_rx_if;

  /////////////////////////////////////////////////////////
  // SIGNALS & BUS
  /////////////////////////////////////////////////////////
  tri1 line;

  /////////////////////////////////////////////////////////
  // CONFIGURATION PARAMETERS
  /////////////////////////////////////////////////////////
  int  baud_rate   = 9600;
  bit  parity_en   = 0;
  bit  parity_type = 0;
  bit  extra_stop  = 0;
  int  data_bits   = 8;

  /////////////////////////////////////////////////////////
  // RECEIVER TASK
  /////////////////////////////////////////////////////////
  /* verilog_format: off */
  task automatic recv(
    output int data,
    output bit parity,
    input int BAUD_RATE   = baud_rate,
    input bit PARITY_EN   = parity_en,
    input bit PARITY_TYPE = parity_type,
    input bit EXTRA_STOP  = extra_stop,
    input int DATA_BITS   = data_bits
  );
  /* verilog_format: on */

    realtime tp;

    tp = 1s / BAUD_RATE;

    baud_rate   = BAUD_RATE;
    parity_en   = PARITY_EN;
    parity_type = PARITY_TYPE;
    extra_stop  = EXTRA_STOP;
    data_bits   = DATA_BITS;

    // Reset received data buffer
    data = 0;

    // Wait for falling edge of Start Bit
    wait (line == 0);  
    
    // Check Start Bit at mid-bit offset
    #(tp / 2);
    if (line != 0) begin
      $error("UART RX: Glitch or Start bit mismatch detected!");
    end

    // Sample Data Bits at mid-bit center
    for (int i = 0; i < data_bits; i++) begin
      #(tp);
      data[i] = line;
    end

    // Sample Parity Bit (if enabled)
    if (parity_en) begin
      #(tp);
      parity = line;
    end

    // Verify Stop Bit
    #(tp);
    if (line != 1) begin
      $error("UART RX: Stop bit error (Framing Fault)!");
    end

  endtask

endinterface