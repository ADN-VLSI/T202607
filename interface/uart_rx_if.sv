`timescale 1ns/1ps
interface uart_rx_if;

  /////////////////////////////////////////////////////////
  // SIGNALS
  /////////////////////////////////////////////////////////
  tri1 line;

  /////////////////////////////////////////////////////////
  // CONFIGURATION
  /////////////////////////////////////////////////////////
  int  baud_rate   = 9600;
  bit  parity_en   = 0;
  bit  parity_type = 0;
  bit  extra_stop  = 0;
  int  data_bits   = 8;

  /////////////////////////////////////////////////////////
  // RECEIVE METHOD
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

    // Clear output data buffer
    data = 0;

    wait (line == 0);  // Wait for start bit
    
    // Start bit check (sample mid-bit)
    #(tp / 2);
    if (line != 0) begin
      $error("UART: Start bit not detected. Potential baud rate mismatch / protocol violation.");
    end

    // Data bits sampling
    for (int i = 0; i < data_bits; i++) begin
      #(tp);
      data[i] = line;
    end

    // Parity bit sampling
    if (parity_en) begin
      #(tp);
      parity = line;
    end

    // Stop bit check
    #(tp);
    if (line != 1) begin
      $error("UART: Stop bit not detected. Framing error.");
    end

  endtask

endinterface