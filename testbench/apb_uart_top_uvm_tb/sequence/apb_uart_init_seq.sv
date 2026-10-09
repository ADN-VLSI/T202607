`ifndef __GUARD_APB_UART_INIT_SEQ_SV__
`define __GUARD_APB_UART_INIT_SEQ_SV__ 0

`include "apb_uart_top_uvm_tb/obj/apb/apb_seq_item.sv"

class apb_uart_init_seq extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(apb_uart_init_seq)

  function new(string name = "apb_uart_init_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_seq_item req;
    `uvm_do_with(req, {we == 1; addr == 'h00; data == 'b110;})
    `uvm_do_with(req, {we == 1; addr == 'h00; data == 'b000;})
    `uvm_do_with(req, {we == 1; addr == 'h04; data == 32'h0003_0364;})
    `uvm_do_with(req, {we == 1; addr == 'h00; data == 'b001;})
  endtask

endclass : apb_uart_init_seq

`endif
