interface uartsend_if;

  tri1 line;

  int  baud_rate   = 9600; // 19200 115200
  bit  parity_en   = 0;    // 0:disabled 1:enabled
  bit  parity_type = 0;    // 0:even 1:odd
  bit  extra_stop  = 0;    // 0:disabled 1:enabled
  int  data_bits   = 8;    // 5, 6, 7, 8

  /////////////////////////////////////////////////////////
  // CONTROL BITS & DRIVE
  /////////////////////////////////////////////////////////
  bit  drv;
  bit  val;

  assign line = drv ? val : 'z;

  /////////////////////////////////////////////////////////
  // METHOD
  /////////////////////////////////////////////////////////
  /* verilog_format: off */
  task automatic send(
    input int data,
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

    drv <= 1;

    // START BIT
    val <= 0;
    #(tp);

    // DATA BITS (LSB First)
    for (int i = 0; i < data_bits; i++) begin
      val <= data[i];
      #(tp);
    end

    // PARITY BIT
    if (parity_en) begin
      bit parity_bit;
      parity_bit = ^data[data_bits-1:0];
      val <= parity_type ? ~parity_bit : parity_bit;
      #(tp);
    end

    // STOP BITS
    for (int i = 0; i <= extra_stop; i++) begin
      val <= 1;
      #(tp);
    end

    drv <= 0; // Release the line back to 'z (tri1 pulls it to 1)

  endtask

endinterface