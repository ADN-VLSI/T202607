`ifndef __GUARD_UART_SEQ_ITEM_SV__
`define __GUARD_UART_SEQ_ITEM_SV__ 0

class uart_seq_item;

  rand logic [7:0] data;
  rand int         baud_rate;
  rand bit         parity_en;
  rand bit         parity_type;
  rand bit         extra_stop;
  rand int         data_bits;


  constraint baud_rate_c {
  baud_rate inside {[9600:115200]};
 }


  constraint data_bits_c {
    data_bits inside {5, 6, 7, 8};
    soft data_bits == 8;
  }


  virtual function automatic string to_string();
    return $sformatf(
      "data=0x%02h baud_rate=%0d parity_en=%0b parity_type=%0b extra_stop=%0b data_bits=%0d",
      data,
      baud_rate,
      parity_en,
      parity_type,
      extra_stop,
      data_bits
    );
  endfunction


  virtual function automatic void display();
    $display("%s", to_string());
  endfunction

endclass

`endif