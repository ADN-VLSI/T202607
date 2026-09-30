`ifndef __GUARD_APB_DRIVER_SV__
`define __GUARD_APB_DRIVER_SV__ 0

`include "apb_uart_top_uvm_tb/obj/apb_seq_item.sv"

class apb_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_driver)

  function new (string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual apb_if intf;

  virtual function void connect_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_intf", intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      forever begin
        int dummy_data;
        int dummy_resp;
        seq_item_port.get_next_item(req);
        phase.raise_objection(this);
        intf.do_transaction(req.addr, req.we, req.data, dummy_data, dummy_resp);
        phase.drop_objection(this);
        seq_item_port.item_done();
      end
    join_none
  endtask

endclass

`endif
