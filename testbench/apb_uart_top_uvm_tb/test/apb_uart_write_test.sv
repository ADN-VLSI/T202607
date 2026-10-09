`ifndef __GUARD_APB_UART_WRITE_TEST_SV__
`define __GUARD_APB_UART_WRITE_TEST_SV__ 0

`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"
`include "apb_uart_top_uvm_tb/sequence/apb_uart_init_seq.sv"
`include "apb_uart_top_uvm_tb/sequence/random_apb_wdata_seq.sv"

// -----------------------------------------------------------------------------
// Test: APB UART Write Test
// -----------------------------------------------------------------------------
class apb_uart_write_test extends apb_uart_base_test;

  `uvm_component_utils(apb_uart_write_test)

  function new(string name = "apb_uart_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (tx_intf != null) tx_intf.baud_rate = 115200;
  endfunction : connect_phase

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Basic write test started", UVM_LOW)

    begin  // SEND APB
      apb_uart_init_seq    init_seq;
      random_apb_wdata_seq my_seq;

      // Initialize UART
      init_seq = apb_uart_init_seq::type_id::create("init_seq");
      init_seq.start(env.apb.sqr);

      // Perform randomized APB writes to UART TX
      uvm_config_db#(int)::set(uvm_root::get(), "parameter", "RANDOM_APB_WDATA_SEQ_LENGTH", 4);
      my_seq = random_apb_wdata_seq::type_id::create("my_seq");
      my_seq.start(env.apb.sqr);
    end

    // Wait for scoreboard to check all transactions
    wait (env.scbd.pass + env.scbd.fail >= 4);

    fork
      // Wait for interfaces to be idle
      apb_intf.wait_till_idle();
      tx_intf.wait_till_idle();
    join

    `uvm_info(get_type_name(), "Basic write test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask : main_phase

endclass : apb_uart_write_test

`endif