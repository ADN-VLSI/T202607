`timescale 1ns/1ps
interface uart_tx_if;

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
  // CONTROL BITS
  /////////////////////////////////////////////////////////
  bit  drv;
  bit  val;

  /////////////////////////////////////////////////////////
  // DRIVE LOGIC
  /////////////////////////////////////////////////////////
  assign line = drv ? val : 'z;

  /////////////////////////////////////////////////////////
  // TRANSMIT METHOD
  /////////////////////////////////////////////////////////
  /* verilog_format: off */
  task automatic send(
    input int data,
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

    drv <= 1;

    // START BIT
    val <= 0;
    #(tp);

    // DATA BITS
    for (int i = 0; i < data_bits; i++) begin
      val <= data[i];
      #(tp);
    end

    // PARITY BIT
    if (parity_en) begin
      bit parity_bit;
      for (int i = 0; i < data_bits; i++) begin
        parity_bit ^= data[i];
      end
      val <= parity_type ? ~parity_bit : parity_bit;
      #(tp);
    end

    // STOP BITS
    for (int i = 0; i <= extra_stop; i++) begin
      val <= 1;
      #(tp);
    end

    drv <= 0;

  endtask

endinterface