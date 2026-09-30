`ifndef __GUARD_UART_AGENT_SV__
`define __GUARD_UART_AGENT_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/uart_driver.sv"
`include "apb_uart_top_uvm_tb/cmp/uart_monitor.sv"

class uart_agent extends uvm_agent;

  `uvm_component_utils(uart_agent)

  function new (string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  uvm_analysis_port #(uart_rsp_item) ap;

  uvm_sequencer     #(uart_seq_item) sqr;
  uart_driver                        dvr;
  uart_monitor                       mon;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    mon = uart_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = uvm_sequencer#(uart_seq_item)::type_id::create("sqr", this);
      dvr = uart_driver::type_id::create("dvr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    mon.ap.connect(ap);
    if (get_is_active() == UVM_ACTIVE) begin
      dvr.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass

`endif
