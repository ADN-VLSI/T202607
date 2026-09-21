`include "ltb/obj/apb_seq_item.sv"
`include "ltb/obj/apb_rsp_item.sv"
`include "ltb/obj/uart_seq_item.sv"
`include "ltb/obj/uart_rsp_item.sv"

`include "ltb/cmp/generator.sv"
`include "ltb/cmp/apb_driver.sv"
`include "ltb/cmp/apb_monitor.sv"
`include "ltb/cmp/uart_driver.sv"
`include "ltb/cmp/uart_monitor.sv"
`include "ltb/cmp/scoreboard.sv"

module apb_uart_top_layered_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  import uart_regif_pkg::ADDR_CTRL;
  import uart_regif_pkg::ADDR_CFG;
  import uart_regif_pkg::ADDR_STATUS;
  import uart_regif_pkg::ADDR_TXD;
  import uart_regif_pkg::ADDR_RXD;
  import uart_regif_pkg::ADDR_INTR;

  import uart_regif_pkg::uart_ctrl_t;
  import uart_regif_pkg::uart_cfg_t;
  import uart_regif_pkg::uart_status_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PARAMETERS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int ClkFreq = 100_000_000;
  localparam int BaudRate = 115200;

  // Register values built from the package structs : no manual bit packing
  localparam uart_cfg_t CfgReg = '{
      reserved: '0,
      extra_stop: 1'b0,
      parity_type: 1'b0,
      parity_en: 1'b0,
      num_bits: 2'd3,  // 3 = 8 data bits
      baud_div: 16'(ClkFreq / BaudRate)
  };

  localparam uart_ctrl_t CtrlReg = '{
      reserved: '0,
      rx_flush: 1'b0,
      tx_flush: 1'b0,
      rx_en: 1'b1,
      tx_en: 1'b1
  };

  // One UART frame : start + 8 data + stop, plus margin
  localparam realtime FrameTime = (12.0s / BaudRate);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ctrl_if ctrl_intf ();

  apb_if apb_intf (
      .pclk(ctrl_intf.clk),
      .presetn(ctrl_intf.arst_n)
  );

  uart_if tx_intf ();  // DUT -> TB : uart_tx_mon watches this
  uart_if rx_intf ();  // TB -> DUT : uart_dvr drives, uart_rx_mon watches

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  mailbox #(apb_seq_item)  apb_dvr_mbx;
  mailbox #(apb_rsp_item)  apb_mon_mbx;
  mailbox #(uart_seq_item) uart_dvr_mbx;
  mailbox #(uart_rsp_item) uart_tx_mon_mbx;
  mailbox #(uart_rsp_item) uart_rx_mon_mbx;

  generator                gen;
  apb_driver               apb_dvr;
  apb_monitor              apb_mon;
  uart_driver              uart_dvr;
  uart_monitor             uart_tx_mon;
  uart_monitor             uart_rx_mon;
  scoreboard               sb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTL
  //////////////////////////////////////////////////////////////////////////////////////////////////

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

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // BUILD PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    $dumpfile("apb_uart_top_layered_tb.vcd");
    $dumpvars(0, apb_uart_top_layered_tb);
    $timeformat(-9, 0, "ns");

    apb_dvr_mbx     = new(1);
    apb_mon_mbx     = new();
    uart_dvr_mbx    = new(1);
    uart_tx_mon_mbx = new();
    uart_rx_mon_mbx = new();

    gen             = new();
    apb_dvr         = new();
    apb_mon         = new();
    uart_dvr        = new();
    uart_tx_mon     = new();
    uart_rx_mon     = new();
    sb              = new();

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // CONNECT PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    apb_dvr.set_interface(apb_intf);
    apb_mon.set_interface(apb_intf);
    uart_dvr.set_interface(rx_intf);
    uart_tx_mon.set_interface(tx_intf);
    uart_rx_mon.set_interface(rx_intf);

    apb_dvr.set_mailbox(apb_dvr_mbx);
    apb_mon.set_mailbox(apb_mon_mbx);
    uart_dvr.set_mailbox(uart_dvr_mbx);
    uart_tx_mon.set_mailbox(uart_tx_mon_mbx);
    uart_rx_mon.set_mailbox(uart_rx_mon_mbx);

    gen.set_apb_mailbox(apb_dvr_mbx);
    gen.set_uart_mailbox(uart_dvr_mbx);

    sb.set_apb_mailbox(apb_mon_mbx);
    sb.set_uart_tx_mailbox(uart_tx_mon_mbx);
    sb.set_uart_rx_mailbox(uart_rx_mon_mbx);

    // Monitor sampling config : must match what we program into the DUT CFG register
    tx_intf.baud_rate   = BaudRate;
    tx_intf.data_bits   = 8;
    tx_intf.parity_en   = 0;
    tx_intf.parity_type = 0;
    tx_intf.extra_stop  = 0;

    rx_intf.baud_rate   = BaudRate;
    rx_intf.data_bits   = 8;
    rx_intf.parity_en   = 0;
    rx_intf.parity_type = 0;
    rx_intf.extra_stop  = 0;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // RESET PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    ctrl_intf.apply_reset();

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // RUN PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    ctrl_intf.start_clock(ClkFreq);

    apb_dvr.run();
    apb_mon.run();
    uart_dvr.run();
    uart_tx_mon.run();
    uart_rx_mon.run();
    sb.run();

    //---- 1. Configure the DUT
    gen.apb_write(ADDR_CFG, 32'(CfgReg));
    gen.apb_write(ADDR_CTRL, 32'(CtrlReg));
    apb_intf.wait_till_idle();

    //---- 2. TX path : APB write -> DUT -> tx line
    gen.apb_write(ADDR_TXD, 32'hA5);
    #(2 * FrameTime);

    gen.apb_write(ADDR_TXD, 32'h3C);
    #(2 * FrameTime);

    gen.apb_write(ADDR_TXD, 32'h55);
    #(2 * FrameTime);

    //---- 3. RX path : rx line -> DUT -> APB read
    gen.uart_send(8'h5A, BaudRate);
    #(2 * FrameTime);  // let the DUT finish receiving
    gen.apb_read(ADDR_RXD);
    apb_intf.wait_till_idle();

    gen.uart_send(8'h7E, BaudRate);
    #(2 * FrameTime);
    gen.apb_read(ADDR_RXD);
    apb_intf.wait_till_idle();

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // SHUTDOWN PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    apb_intf.wait_till_idle();
    #(2 * FrameTime);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // REPORT PHASE
    ////////////////////////////////////////////////////////////////////////////////////////////////

    sb.report();

    $finish;
  end

endmodule