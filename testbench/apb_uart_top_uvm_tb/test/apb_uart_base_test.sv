`ifndef __GUARD_APB_UART_BASE_TEST_SV__
`define __GUARD_APB_UART_BASE_TEST_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/apb_uart_env.sv"

class apb_uart_base_test extends uvm_test;

  `uvm_component_utils(apb_uart_base_test)

  function new (string name = "apb_uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_uart_env                    env;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_uart_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    uvm_top.print_topology();
    phase.raise_objection(this);
    #1us;
    phase.drop_objection(this);
  endtask

endclass

`endif
