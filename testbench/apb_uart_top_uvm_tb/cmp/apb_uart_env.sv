`ifndef __GUARD_APB_UART_ENV_SV__
`define __GUARD_APB_UART_ENV_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/apb_agent.sv"

class apb_uart_env extends uvm_env;

  `uvm_component_utils(apb_uart_env)

  function new (string name = "apb_uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_agent                    apb;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb = apb_agent::type_id::create("apb", this);
  endfunction

endclass

`endif
