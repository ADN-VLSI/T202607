`ifndef __GUARD_ALL_REG_ACCESS_TEST_SV__
`define __GUARD_ALL_REG_ACCESS_TEST_SV__ 0

`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"
`include "apb_uart_top_uvm_tb/sequence/all_reg_access_seq.sv"

class all_reg_access_test extends apb_uart_base_test;

  `uvm_component_utils(all_reg_access_test)

  function new(string name = "all_reg_access_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    all_reg_access_seq reg_seq;

    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Register access test started", UVM_LOW)

    reg_seq = all_reg_access_seq::type_id::create("reg_seq");
    reg_seq.start(env.apb.sqr);
    apb_intf.wait_till_idle();

    `uvm_info(get_type_name(), "Register access test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : all_reg_access_test

`endif
