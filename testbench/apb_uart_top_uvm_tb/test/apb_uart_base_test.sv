`ifndef __GUARD_APB_UART_BASE_TEST_SV__
`define __GUARD_APB_UART_BASE_TEST_SV__ 0

`include "apb_uart_top_uvm_tb/cmp/apb_uart_env.sv"

class apb_uart_base_test extends uvm_test;

  `uvm_component_utils(apb_uart_base_test)

  function new (string name = "apb_uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_uart_env                    env;

  virtual ctrl_if ctrl_intf;
  virtual apb_if  apb_intf;
  virtual uart_if tx_intf;
  virtual uart_if rx_intf;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_uart_env::type_id::create("env", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual ctrl_if)::get(uvm_root::get(), "*.env.ctrl.*", "intf", ctrl_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
    if (!uvm_config_db#(virtual  apb_if)::get(uvm_root::get(), "*.env.apb.*", "intf", apb_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
    if (!uvm_config_db#(virtual uart_if)::get(uvm_root::get(), "*.env.tx.*", "intf", tx_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
    if (!uvm_config_db#(virtual uart_if)::get(uvm_root::get(), "*.env.rx.*", "intf", rx_intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    apb_intf.apply_reset();
    tx_intf.apply_reset();
    rx_intf.apply_reset();
    ctrl_intf.apply_reset();
    phase.drop_objection(this);
  endtask

  virtual task configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    phase.raise_objection(this);
    ctrl_intf.start_clock();
    phase.drop_objection(this);
  endtask

  virtual task shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    phase.raise_objection(this);
    fork
      apb_intf.wait_till_idle();
      tx_intf.wait_till_idle();
      rx_intf.wait_till_idle();
    join
    phase.drop_objection(this);
  endtask

endclass

`endif
