`ifndef __GUARD_GENERATOR_SV__
`define __GUARD_GENERATOR_SV__ 0

`include "ltb/obj/apb_seq_item.sv"
`include "ltb/obj/uart_seq_item.sv"

import uart_regif_pkg::ADDR_TXD;

class generator;

  mailbox #(apb_seq_item)  apb_mbx;
  mailbox #(uart_seq_item) uart_mbx;


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual function automatic void set_apb_mailbox(
      mailbox #(apb_seq_item) mbx
  );
    this.apb_mbx = mbx;
  endfunction


  virtual function automatic void set_uart_mailbox(
      mailbox #(uart_seq_item) mbx
  );
    this.uart_mbx = mbx;
  endfunction


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // APB WRITE
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic apb_write(
      input logic [4:0]  addr,
      input logic [31:0] data
  );

    apb_seq_item item;

    item = new();

    if (!item.randomize() with {
      item.we   == 1'b1;
      item.addr == local::addr;
      item.data == local::data;
    }) $fatal(1, "generator::apb_write randomization failed");

    apb_mbx.put(item);

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // APB READ
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic apb_read(
      input logic [4:0] addr
  );

    apb_seq_item item;

    item = new();

    if (!item.randomize() with {
      item.we   == 1'b0;
      item.addr == local::addr;
    }) $fatal(1, "generator::apb_read randomization failed");

    apb_mbx.put(item);

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RANDOM APB
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic random_apb_sequence(
      input int length = 10
  );

    repeat (length) begin

      apb_seq_item item;

      item = new();
      if (!item.randomize())
        $fatal(1, "generator::random_apb_sequence randomization failed");

      apb_mbx.put(item);

    end

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // UART SEND
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic uart_send(
      input logic [7:0] data,
      input int         baud_rate   = 115200,
      input bit         parity_en   = 0,
      input bit         parity_type = 0,
      input bit         extra_stop  = 0,
      input int         data_bits   = 8
  );

    uart_seq_item item;

    item = new();

    if (!item.randomize() with {
      item.data        == local::data;
      item.baud_rate   == local::baud_rate;
      item.parity_en   == local::parity_en;
      item.parity_type == local::parity_type;
      item.extra_stop  == local::extra_stop;
      item.data_bits   == local::data_bits;
    }) $fatal(1, "generator::uart_send randomization failed");

    uart_mbx.put(item);

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RANDOM UART TX (via APB TXD)
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic random_uart_tx();

    apb_seq_item item;

    item = new();

    if (!item.randomize() with {
      item.we   == 1'b1;
      item.addr == ADDR_TXD;
    }) $fatal(1, "generator::random_uart_tx randomization failed");

    apb_mbx.put(item);

  endtask


endclass

`endif