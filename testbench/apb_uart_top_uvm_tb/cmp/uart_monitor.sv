`ifndef __GUARD_UART_MONITOR_SV__
`define __GUARD_UART_MONITOR_SV__ 0

`include "apb_uart_top_uvm_tb/obj/uart_rsp_item.sv"

class uart_monitor extends uvm_monitor;

  `uvm_component_utils(uart_monitor)

  uvm_analysis_port #(uart_rsp_item) ap;

  function new (string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual uart_if intf;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "tx_intf", intf) &&
        !uvm_config_db#(virtual uart_if)::get(this, "", "rx_intf", intf) &&
        !uvm_config_db#(virtual uart_if)::get(this, "", "uart_intf", intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      forever begin
        uart_rsp_item item;
        int data;
        bit parity;

        item = new();
        intf.recv(data, parity);

        item.data        = data[7:0];
        item.parity      = parity;
        item.baud_rate   = intf.baud_rate;
        item.parity_en   = intf.parity_en;
        item.parity_type = intf.parity_type;
        item.extra_stop  = intf.extra_stop;
        item.data_bits   = intf.data_bits;

        ap.write(item);
      end
    join_none
  endtask

endclass

`endif
