`ifndef __GUARD_APB_MONITOR_SV__
`define __GUARD_APB_MONITOR_SV__ 0

`include "ltb/obj/apb_rsp_item.sv"

class apb_monitor;

  virtual apb_if intf;
  mailbox #(apb_rsp_item) mbx;


  virtual function automatic void set_interface(virtual apb_if intf);
    this.intf = intf;
  endfunction


  virtual function automatic void set_mailbox(mailbox #(apb_rsp_item) mbx);
    this.mbx = mbx;
  endfunction


  virtual task run();
    fork
      forever begin

        apb_rsp_item item;

        // Create APB response item
        item = new();

        // Monitor one completed APB transaction
        intf.get_transaction(item.addr, item.we, item.data, item.slverr);

        // Send response item to monitor output mailbox
        mbx.put(item);

      end
    join_none
  endtask

endclass

`endif