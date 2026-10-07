`ifndef __GUARD_APB_UART_ENV_SV__
`define __GUARD_APB_UART_ENV_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/apb_agent.sv"
`include "apb_uart_top_uvm_tb/cmp/uart_agent.sv"
`include "apb_uart_top_uvm_tb/cmp/apb_uart_scbd.sv"

class apb_uart_env extends uvm_env;

  `uvm_component_utils(apb_uart_env)

  function new (string name = "apb_uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_agent                    apb;
  uart_agent                   tx;
  uart_agent                   rx;
  apb_uart_scbd                scbd;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb  = apb_agent::type_id::create("apb", this);
    tx   = uart_agent::type_id::create("tx", this);
    rx   = uart_agent::type_id::create("rx", this);
    scbd = apb_uart_scbd::type_id::create("scbd", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb.ap.connect(scbd.apb_imp);
    tx.ap.connect(scbd.uart_tx_imp);
    rx.ap.connect(scbd.uart_rx_imp);
  endfunction

endclass

`endif
