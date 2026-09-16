`ifndef __GUARD_UART_MONITOR_SV__
`define __GUARD_UART_MONITOR_SV__ 0

`include "ltb/obj/uart_rsp_item.sv"

class uart_monitor;

  virtual uart_if intf;
  mailbox #(uart_rsp_item) mbx;


  virtual function automatic void set_interface(virtual uart_if intf);
    this.intf = intf;
  endfunction


  virtual function automatic void set_mailbox(mailbox #(uart_rsp_item) mbx);
    this.mbx = mbx;
  endfunction


  virtual task run();
    fork
      forever begin

        uart_rsp_item item;

        int data;
        bit parity;


        // Create UART response item
        item = new();


        // Monitor one UART frame
        intf.recv(data, parity);


        // Store received information
        item.data        = data[7:0];
        item.parity      = parity;
        item.baud_rate   = intf.baud_rate;
        item.parity_en   = intf.parity_en;
        item.parity_type = intf.parity_type;
        item.extra_stop  = intf.extra_stop;
        item.data_bits   = intf.data_bits;


        // Send response item to scoreboard mailbox
        mbx.put(item);

      end
    join_none
  endtask

endclass

`endif