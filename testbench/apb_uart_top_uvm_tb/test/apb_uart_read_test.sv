`ifndef __GUARD_APB_UART_READ_TEST_SV__
`define __GUARD_APB_UART_READ_TEST_SV__ 0

`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"
`include "apb_uart_top_uvm_tb/sequence/random_uart_rx_seq.sv"
`include "apb_uart_top_uvm_tb/sequence/apb_uart_init_seq.sv"
`include "apb_uart_top_uvm_tb/sequence/random_apb_rdata_seq.sv"


class apb_uart_read_test extends apb_uart_base_test;

  `uvm_component_utils(apb_uart_read_test)

  function new(string name = "apb_uart_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Basic read test started", UVM_LOW)
    begin
        apb_uart_init_seq init_seq;
        init_seq = apb_uart_init_seq::type_id::create("init_seq");
        init_seq.start(env.apb.sqr);
    end

    begin  // SEND APB
      // Perform randomized APB reads from UART RX
      random_uart_rx_seq uart_rx_seq;
      uvm_config_db#(int)::set(uvm_root::get(), "parameter", "RANDOM_UART_RX_SEQ_LENGTH", 10);
      uart_rx_seq = random_uart_rx_seq::type_id::create("uart_rx_seq");
      uart_rx_seq.start(env.rx.sqr);
    end

    fork
      // Wait for interfaces to be idle
      apb_intf.wait_till_idle();
      rx_intf.wait_till_idle();
    join

    begin 
        random_apb_rdata_seq apb_rdata_seq;
        uvm_config_db#(int)::set(uvm_root::get(), "parameter", "RANDOM_APB_RDATA_SEQ_LENGTH", 10);
        apb_rdata_seq = random_apb_rdata_seq::type_id::create("apb_rdata_seq");
        apb_rdata_seq.start(env.apb.sqr);
    end
    fork
      // Wait for interfaces to be idle
      apb_intf.wait_till_idle();
      rx_intf.wait_till_idle();
    join

    `uvm_info(get_type_name(), "Basic read test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask : run_phase
endclass : apb_uart_read_test

`endif
