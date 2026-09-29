`ifndef __GUARD_APB_UART_ENV_SV__
`define __GUARD_APB_UART_ENV_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/apb_agent.sv"
`include "apb_uart_top_uvm_tb/cmp/uart_agent.sv"

class apb_uart_env extends uvm_env;

  `uvm_component_utils(apb_uart_env)

  function new (string name = "apb_uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_agent                    apb;
  uart_agent                   tx;
  uart_agent                   rx;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "tx", "is_active", UVM_PASSIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "rx", "is_active", UVM_ACTIVE);

    apb = apb_agent::type_id::create("apb", this);
    tx  = uart_agent::type_id::create("tx", this);
    rx  = uart_agent::type_id::create("rx", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb.dvr.seq_item_port.connect(apb.sqr.seq_item_export);
  endfunction

endclass

`endif
