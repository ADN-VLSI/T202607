`ifndef __GUARD_APB_MONITOR_SV__
`define __GUARD_APB_MONITOR_SV__ 0

`include "apb_uart_top_uvm_tb/obj/apb_rsp_item.sv"

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  uvm_analysis_port #(apb_rsp_item) ap;

  function new (string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual apb_if intf;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "apb_intf", intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      forever begin
        apb_rsp_item item;
        item = new();
        intf.get_transaction(item.addr, item.we, item.data, item.slverr);
        ap.write(item);
      end
    join_none
  endtask

endclass

`endif
