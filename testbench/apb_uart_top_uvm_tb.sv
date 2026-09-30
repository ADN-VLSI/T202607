`include "uvm_macros.svh"

import uvm_pkg::*;

`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"
`include "apb_uart_top_uvm_tb/test/apb_uart_write_test.sv"

module apb_uart_top_uvm_tb;

  ctrl_if ctrl_intf ();

  apb_if apb_intf (
      .pclk(ctrl_intf.clk),
      .presetn(ctrl_intf.arst_n)
  );

  uart_if tx_intf ();  // DUT -> TB : uart_tx_mon watches this
  uart_if rx_intf ();  // TB -> DUT : uart_dvr drives, uart_rx_mon watches

  apb_uart_top #(
      .ADDR_WIDTH  (32),
      .DATA_WIDTH  (32),
      .WSTRB_WIDTH (4),
      .FIFO_DEPTH_W(9)
  ) DUT (
      .clk_i    (ctrl_intf.clk),
      .arst_ni  (ctrl_intf.arst_n),
      .psel_i   (apb_intf.psel),
      .penable_i(apb_intf.penable),
      .paddr_i  (apb_intf.paddr),
      .pwrite_i (apb_intf.pwrite),
      .pwdata_i (apb_intf.pwdata),
      .pstrb_i  (apb_intf.pstrb),
      .pready_o (apb_intf.pready),
      .prdata_o (apb_intf.prdata),
      .pslverr_o(apb_intf.pslverr),
      .tx_o     (tx_intf.line),
      .rx_i     (rx_intf.line),
      .intr_o   (  /*LEFT BLANK*/)
  );

  initial begin
    ctrl_intf.start_clock(100_000_000);
  end

  initial begin
    ctrl_intf.apply_reset();
  end

  initial begin
    string test_name;
    $timeformat(-9, 0, "ns");
    $dumpfile("apb_uart_top_uvm_tb.vcd");
    $dumpvars(0, apb_uart_top_uvm_tb);

    uvm_config_db#(virtual ctrl_if)::set(uvm_root::get(), "*.env.ctrl.*", "ctrl_intf", ctrl_intf);
    uvm_config_db#(virtual apb_if)::set(uvm_root::get(),  "*.env.apb.*", "apb_intf", apb_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.tx.*", "tx_intf", tx_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.rx.*", "rx_intf", rx_intf);

    if ($value$plusargs("UVM_TESTNAME=%s", test_name)) begin
      run_test(test_name);
    end else if ($value$plusargs("CLI_TEST_NAME=%s", test_name) && test_name != "default") begin
      run_test(test_name);
    end else begin
      run_test("apb_uart_base_test");
    end
  end

endmodule
