`include "uvm_macros.svh"

import uvm_pkg::*;

`include "apb_uart_top_uvm_tb/test/apb_uart_base_test.sv"

module apb_uart_top_uvm_tb;

  ctrl_if ctrl_intf ();
  // logic arst_n;
  // logic clk;

  apb_if apb_intf (
      .pclk(ctrl_intf.clk),
      .presetn(ctrl_intf.arst_n)
  );
  // logic                    psel;
  // logic                    penable;
  // logic [  ADDR_WIDTH-1:0] paddr;
  // logic                    pwrite;
  // logic [  DATA_WIDTH-1:0] pwdata;
  // logic [DATA_WIDTH/8-1:0] pstrb;
  // logic                    pready;
  // logic [  DATA_WIDTH-1:0] prdata;
  // logic                    pslverr;

  uart_if tx_intf ();  // DUT -> TB : uart_tx_mon watches this
  // tri1 line;
  uart_if rx_intf ();  // TB -> DUT : uart_dvr drives, uart_rx_mon watches
  // tri1 line;

  initial begin
    $timeformat(-9, 0, "ns");
    $dumpfile("apb_uart_top_uvm_tb.vcd");
    $dumpvars(0, apb_uart_top_uvm_tb);

    uvm_config_db#(virtual ctrl_if)::set(uvm_root::get(), "*.env.ctrl.*", "ctrl_intf", ctrl_intf);
    uvm_config_db#(virtual apb_if)::set(uvm_root::get(),  "*.env.apb.*", "apb_intf", apb_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.tx.*", "tx_intf", tx_intf);
    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.rx.*", "rx_intf", rx_intf);

    run_test("apb_uart_base_test");

  end

endmodule
