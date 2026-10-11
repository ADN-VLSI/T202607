`ifndef __GUARD_UART_RSP_ITEM_SV__
`define __GUARD_UART_RSP_ITEM_SV__ 0

`include "apb_uart_top_uvm_tb/obj/uart/uart_seq_item.sv"

class uart_rsp_item extends uart_seq_item;

  // rand logic [7:0] data;
  // rand int         baud_rate;
  // rand bit         parity_en;
  // rand bit         parity_type;
  // rand bit         extra_stop;
  // rand int         data_bits;
  bit parity;

  `uvm_object_utils_begin(uart_rsp_item)
    `uvm_field_int(data,        UVM_ALL_ON)
    `uvm_field_int(baud_rate,   UVM_ALL_ON)
    `uvm_field_int(parity_en,   UVM_ALL_ON)
    `uvm_field_int(parity_type, UVM_ALL_ON)
    `uvm_field_int(extra_stop,  UVM_ALL_ON)
    `uvm_field_int(data_bits,   UVM_ALL_ON)
    `uvm_field_int(parity,      UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "uart_rsp_item");
    super.new(name);
  endfunction

  virtual function automatic string to_string();
    // "data=0x%02h baud_rate=%-7d parity_en=%0b parity_type=%0b extra_stop=%0b data_bits=%0d",
    return $sformatf("%s parity=%0b", super.to_string(), parity);
  endfunction

endclass

`endif
