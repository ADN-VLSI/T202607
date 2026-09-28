`ifndef __GUARD_UART_RSP_ITEM_SV__
`define __GUARD_UART_RSP_ITEM_SV__ 0

`include "ltb/obj/uart_seq_item.sv"

class uart_rsp_item extends uart_seq_item;

  bit parity;


  virtual function automatic string to_string();
    return $sformatf(
      "%s parity=%0b",
      super.to_string(),
      parity
    );
  endfunction

endclass

`endif