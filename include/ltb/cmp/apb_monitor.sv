`ifndef __GUARD_APB_MONITOR_SV__
`define __GUARD_APB_MONITOR_SV__ 0

`include "ltb/obj/apb_rsp_item.sv"

class apb_monitor;

  virtual apb_if intf;
  mailbox #(apb_rsp_item) mbx;


  virtual function set_interface(virtual apb_if intf);
    this.intf = intf;
  endfunction


  virtual function set_mailbox(mailbox #(apb_rsp_item) mbx);
    this.mbx = mbx;
  endfunction


  virtual task run();
    fork
      forever begin

        apb_rsp_item item;

        logic [31:0] addr;
        logic        write;
        logic [31:0] data;
        logic        slverr;

        // Monitor one completed APB transaction
        intf.get_transaction(addr, write, data, slverr);

        // Create APB response item
        item = new();

        // Put monitored values into response item
        item.addr   = addr[4:0];
        item.we     = write;
        item.data   = data;
        item.slverr = slverr;

        // Send response item to monitor output mailbox
        mbx.put(item);

      end
    join_none
  endtask

endclass

`endif