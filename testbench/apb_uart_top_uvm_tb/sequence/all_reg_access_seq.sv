`ifndef __GUARD_ALL_REG_ACCESS_SEQ_SV__
`define __GUARD_ALL_REG_ACCESS_SEQ_SV__ 0

`include "apb_uart_top_uvm_tb/obj/apb/apb_seq_item.sv"

class all_reg_access_seq extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(all_reg_access_seq)

  function new(string name = "all_reg_access_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_seq_item req;

    // Check reset values of all readable/writable registers.
    `uvm_do_with(req, {we == 0; addr == ADDR_CTRL;})
    `uvm_do_with(req, {we == 0; addr == ADDR_CFG;})
    `uvm_do_with(req, {we == 0; addr == ADDR_INTR;})

    // CTRL flush bits are self-clearing; only TX_EN and RX_EN remain set.
    `uvm_do_with(req, {we == 1; addr == ADDR_CTRL; data == 32'h0000_000F;})
    `uvm_do_with(req, {we == 0; addr == ADDR_CTRL;})

    `uvm_do_with(req, {we == 1; addr == ADDR_CFG; data == 32'h0003_0364;})
    `uvm_do_with(req, {we == 0; addr == ADDR_CFG;})

    `uvm_do_with(req, {we == 1; addr == ADDR_INTR; data == 32'h0000_000F;})
    `uvm_do_with(req, {we == 0; addr == ADDR_INTR;})
  endtask

endclass : all_reg_access_seq

`endif
