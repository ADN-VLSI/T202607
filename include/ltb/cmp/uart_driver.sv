`ifndef __GUARD_UART_DRIVER_SV__
`define __GUARD_UART_DRIVER_SV__ 0

`include "ltb/obj/uart_seq_item.sv"

class uart_driver;

  virtual uart_if intf;
  mailbox #(uart_seq_item) mbx;


  virtual function automatic void set_interface(virtual uart_if intf);
    this.intf = intf;
  endfunction


  virtual function automatic void set_mailbox(mailbox #(uart_seq_item) mbx);
    this.mbx = mbx;
  endfunction


  virtual task run();
    fork
      forever begin

        uart_seq_item item;

        // Get item from generator mailbox
        mbx.peek(item);

        // Drive one UART frame
        intf.send(
          item.data,
          item.baud_rate,
          item.parity_en,
          item.parity_type,
          item.extra_stop,
          item.data_bits
        );

        // Remove completed item
        mbx.get(item);

      end
    join_none
  endtask

endclass

`endif