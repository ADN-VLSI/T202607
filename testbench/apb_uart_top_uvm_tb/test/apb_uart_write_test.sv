`ifndef __GUARD_APB_UART_WRITE_TEST_SV__
`define __GUARD_APB_UART_WRITE_TEST_SV__ 0

`include "uart_regif_pkg.sv"
import uart_regif_pkg::*;

`include "apb_uart_top_uvm_tb/obj/apb_seq_item.sv"
`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"

// -----------------------------------------------------------------------------
// Sequence: Random APB Write Data
// -----------------------------------------------------------------------------
class random_apb_wdata_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(random_apb_wdata_seq)

  int seq_length = 4;

  function new(string name = "random_apb_wdata_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_seq_item req;
    void'(uvm_config_db#(int)::get(null, "parameter", "RANDOM_APB_WDATA_SEQ_LENGTH", seq_length));

    // 1. Configure 115200 baud (8N1): baud_div = 100MHz / 115200 = 868 (0x364), num_bits = 3 (8 bits)
    `uvm_do_with(req, { we == 1; addr == ADDR_CFG; data == 32'h0003_0364; })

    // 2. Enable UART TX & RX in CTRL register (tx_en=1, rx_en=1)
    `uvm_do_with(req, { we == 1; addr == ADDR_CTRL; data == 32'h0000_0003; })

    // 3. Send randomized data bytes to TXD
    repeat (seq_length) begin
      `uvm_do_with(req, { we == 1; addr == ADDR_TXD; })
    end
  endtask
endclass

// -----------------------------------------------------------------------------
// Test: APB UART Write Test
// -----------------------------------------------------------------------------
class apb_uart_write_test extends apb_uart_base_test;
  `uvm_component_utils(apb_uart_write_test)

  function new(string name = "apb_uart_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (env.tx.mon.intf != null) env.tx.mon.intf.baud_rate = 115200;
  endfunction

  virtual task run_phase(uvm_phase phase);
    random_apb_wdata_seq my_seq;
    phase.raise_objection(this);

    // Wait for reset to complete
    #1us;

    uvm_config_db#(int)::set(uvm_root::get(), "parameter", "RANDOM_APB_WDATA_SEQ_LENGTH", 4);
    my_seq = random_apb_wdata_seq::type_id::create("my_seq");
    my_seq.start(env.apb.sqr);

    // Wait for scoreboard to verify all 4 bytes
    wait (env.scbd.pass + env.scbd.fail >= 4);
    #100us;

    phase.drop_objection(this);
  endtask
endclass

`endif