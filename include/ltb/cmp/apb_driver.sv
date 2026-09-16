`ifndef __GUARD_APB_DRIVER_SV__
`define __GUARD_APB_DRIVER_SV__ 0

`include "ltb/obj/apb_seq_item.sv"

class apb_driver;

  virtual apb_if intf;
  mailbox #(apb_seq_item) mbx;

  virtual function automatic void set_interface(virtual apb_if intf);
    this.intf = intf;
  endfunction

  virtual function automatic void set_mailbox(mailbox#(apb_seq_item) mbx);
    this.mbx = mbx;
  endfunction

  virtual task run();
    fork
      forever begin
        apb_seq_item item;
        int dummy_data;
        int dummy_resp;
        mbx.peek(item);
        intf.do_transaction(item.addr, item.we, item.data, dummy_data, dummy_resp);
        mbx.get(item);
      end
    join_none
  endtask

endclass

`endif
