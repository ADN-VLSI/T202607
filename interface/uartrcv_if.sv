interface uartrcv_if;

  /////////////////////////////////////////////////////////
  // SIGNALS
  /////////////////////////////////////////////////////////
  tri1 line; // Receiver observes this line; it does not drive it

  /////////////////////////////////////////////////////////
  // CONFIGURATION
  /////////////////////////////////////////////////////////
  int  baud_rate   = 9600; // 19200 115200
  bit  parity_en   = 0;    // 0:disabled 1:enabled
  bit  parity_type = 0;    // 0:even 1:odd
  bit  extra_stop  = 0;    // 0:disabled 1:enabled
  int  data_bits   = 8;    // 5, 6, 7, 8

  /////////////////////////////////////////////////////////
  // METHOD: RECEIVE
  /////////////////////////////////////////////////////////
  /* verilog_format: off */
  task automatic recv(
    output int data,
    output bit parity,
    input int BAUD_RATE = baud_rate,
    input bit PARITY_EN = parity_en,
    input bit PARITY_TYPE = parity_type,
    input bit EXTRA_STOP = extra_stop,
    input int DATA_BITS = data_bits
  );
  /* verilog_format: on */

    realtime tp;
    tp = 1s / BAUD_RATE;

    baud_rate   = BAUD_RATE;
    parity_en   = PARITY_EN;
    parity_type = PARITY_TYPE;
    extra_stop  = EXTRA_STOP;
    data_bits   = DATA_BITS;

    wait (line == 0);  // Wait for the falling edge of the start bit
    
    // Start bit check (sample at the middle of the bit period)
    #(tp / 2);
    if (line != 0) begin
      $error("UART RX: Start bit not detected. Probably Baud rate mismatch / protocol violation");
    end

    // Data bits
    for (int i = 0; i < data_bits; i++) begin
      #(tp);
      data[i] = line;
    end

    // Parity bit
    if (parity_en) begin
      #(tp);
      parity = line;
    end

    // Stop bit
    #(tp);
    if (line != 1) begin
      $error("UART RX: Stop bit not detected. Probably Baud rate mismatch / protocol violation / configuration mismatch");
    end

  endtask

endinterface