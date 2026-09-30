`ifndef __GUARD_APB_UART_SCBD_SV__
`define __GUARD_APB_UART_SCBD_SV__ 0

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "uart_regif_pkg.sv"
import uart_regif_pkg::ADDR_CTRL;
import uart_regif_pkg::ADDR_CFG;
import uart_regif_pkg::ADDR_STATUS;
import uart_regif_pkg::ADDR_TXD;
import uart_regif_pkg::ADDR_RXD;
import uart_regif_pkg::ADDR_INTR;

`include "apb_uart_top_uvm_tb/obj/apb_rsp_item.sv"
`include "apb_uart_top_uvm_tb/obj/uart_rsp_item.sv"

// Declare analysis implementation suffixes for APB, UART TX, and UART RX
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)

// ==============================================================================================
// SCOREBOARD
// ==============================================================================================

// APB UART Scoreboard
// This UVM scoreboard compares APB transactions with UART transactions
// to verify data integrity between the APB interface and serial UART lines.
class apb_uart_scbd extends uvm_scoreboard;

  `uvm_component_utils(apb_uart_scbd)

  // Analysis implementation ports for receiving items from monitors
  uvm_analysis_imp_apb     #(apb_rsp_item,  apb_uart_scbd) apb_imp;
  uvm_analysis_imp_uart_tx #(uart_rsp_item, apb_uart_scbd) uart_tx_imp;
  uvm_analysis_imp_uart_rx #(uart_rsp_item, apb_uart_scbd) uart_rx_imp;

  // Shadow queues for data verification
  bit [7:0] tx_expected_q[$];
  bit [7:0] rx_expected_q[$];

  // Verification pass/fail counters
  int pass = 0;
  int fail = 0;

  // Constructor
  function new(string name = "apb_uart_scbd", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  // Build phase: instantiate analysis implementation ports
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_imp     = new("apb_imp", this);
    uart_tx_imp = new("uart_tx_imp", this);
    uart_rx_imp = new("uart_rx_imp", this);
  endfunction : build_phase

  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  // --------------------------------------------------------------------------------------------
  // APB Transaction Handler
  // --------------------------------------------------------------------------------------------
  virtual function void write_apb(apb_rsp_item item);
    `uvm_info(get_type_name(), $sformatf("Received APB item: %s", item.to_string()), UVM_HIGH)

    // Ignore transactions with slave error
    if (item.slverr === 1'b1) begin
      `uvm_warning(get_type_name(), $sformatf("APB access returned SLVERR at addr 0x%02h", item.addr))
      return;
    end

    // ---- TX PATH: CPU wrote data byte to ADDR_TXD -> DUT must transmit it on UART TX line
    if ((item.we === 1'b1) && (item.addr == ADDR_TXD)) begin
      tx_expected_q.push_back(item.data[7:0]);
      `uvm_info(get_type_name(), $sformatf("SCB: expecting 0x%02h on UART TX line (depth=%0d)",
                item.data[7:0], tx_expected_q.size()), UVM_MEDIUM)
    end

    // ---- RX PATH: CPU read data byte from ADDR_RXD -> must match byte driven into UART RX line
    else if ((item.we === 1'b0) && (item.addr == ADDR_RXD)) begin
      if (rx_expected_q.size() == 0) begin
        fail++;
        `uvm_error(get_type_name(), $sformatf("FAIL: RXD read 0x%02h but rx_expected_q is empty (nothing driven on RX line)", item.data[7:0]))
      end else begin
        bit [7:0] expected;
        expected = rx_expected_q.pop_front();
        if (item.data[7:0] === expected) begin
          pass++;
          `uvm_info(get_type_name(), $sformatf("PASS: RXD Match = 0x%02h", item.data[7:0]), UVM_LOW)
        end else begin
          fail++;
          `uvm_error(get_type_name(), $sformatf("FAIL: RXD Mismatch! Expected 0x%02h, got 0x%02h", expected, item.data[7:0]))
        end
      end
    end

    // Informational logging for configuration register writes
    else if (item.we === 1'b1 && item.addr == ADDR_CFG) begin
      `uvm_info(get_type_name(), $sformatf("APB CFG write: 0x%08h", item.data), UVM_HIGH)
    end
    else if (item.we === 1'b1 && item.addr == ADDR_CTRL) begin
      `uvm_info(get_type_name(), $sformatf("APB CTRL write: 0x%08h", item.data), UVM_HIGH)
    end
  endfunction : write_apb

  // --------------------------------------------------------------------------------------------
  // UART TX Transaction Handler (DUT -> TB on TX line)
  // --------------------------------------------------------------------------------------------
  virtual function void write_uart_tx(uart_rsp_item item);
    `uvm_info(get_type_name(), $sformatf("Received UART TX item: %s", item.to_string()), UVM_HIGH)

    // Compare with expected TX byte from APB write
    if (tx_expected_q.size() == 0) begin
      fail++;
      `uvm_error(get_type_name(), $sformatf("FAIL: Unexpected byte 0x%02h on UART TX line (tx_expected_q empty)", item.data))
    end else begin
      bit [7:0] expected;
      expected = tx_expected_q.pop_front();
      if (item.data === expected) begin
        pass++;
        `uvm_info(get_type_name(), $sformatf("PASS: UART TX Match = 0x%02h", item.data), UVM_LOW)
      end else begin
        fail++;
        `uvm_error(get_type_name(), $sformatf("FAIL: UART TX Mismatch! Expected 0x%02h, got 0x%02h", expected, item.data))
      end
    end
  endfunction : write_uart_tx

  // --------------------------------------------------------------------------------------------
  // UART RX Transaction Handler (TB -> DUT on RX line)
  // --------------------------------------------------------------------------------------------
  virtual function void write_uart_rx(uart_rsp_item item);
    `uvm_info(get_type_name(), $sformatf("Received UART RX item: %s", item.to_string()), UVM_HIGH)

    // Queue expected data waiting for APB read from ADDR_RXD
    rx_expected_q.push_back(item.data);
    `uvm_info(get_type_name(), $sformatf("SCB: expecting 0x%02h from APB RXD read (depth=%0d)",
              item.data, rx_expected_q.size()), UVM_MEDIUM)
  endfunction : write_uart_rx

  // --------------------------------------------------------------------------------------------
  // Check Phase: Verify no pending unverified bytes remain in queues
  // --------------------------------------------------------------------------------------------
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (tx_expected_q.size() != 0) begin
      `uvm_error(get_type_name(), $sformatf("Check Phase FAIL: %0d unverified byte(s) remaining in tx_expected_q", tx_expected_q.size()))
      fail += tx_expected_q.size();
    end
    if (rx_expected_q.size() != 0) begin
      `uvm_error(get_type_name(), $sformatf("Check Phase FAIL: %0d unverified byte(s) remaining in rx_expected_q", rx_expected_q.size()))
      fail += rx_expected_q.size();
    end
  endfunction : check_phase

  // --------------------------------------------------------------------------------------------
  // Report Phase: Display verification results
  // --------------------------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    $display("");
    $display("========================================");
    $display("       FINAL TEST SUMMARY               ");
    $display("========================================");
    $display(" PASS            = %0d", pass);
    $display(" FAIL            = %0d", fail);
    $display("========================================");
    if (fail == 0 && pass > 0 && tx_expected_q.size() == 0 && rx_expected_q.size() == 0) begin
      $display(" ALL TESTS PASSED");
    end else if (pass == 0 && fail == 0) begin
      $display(" NO TRANSACTIONS CHECKED");
    end else begin
      $display(" SOME TESTS FAILED");
    end
    $display("========================================");

    `uvm_info(get_type_name(), "", UVM_NONE)
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
    `uvm_info(get_type_name(), "       FINAL TEST SUMMARY               ", UVM_NONE)
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf(" PASS            = %0d", pass), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf(" FAIL            = %0d", fail), UVM_NONE)
    `uvm_info(get_type_name(), "========================================", UVM_NONE)

    if (fail == 0 && pass > 0 && tx_expected_q.size() == 0 && rx_expected_q.size() == 0) begin
      `uvm_info(get_type_name(), " ALL TESTS PASSED", UVM_NONE)
    end else if (pass == 0 && fail == 0) begin
      `uvm_info(get_type_name(), " NO TRANSACTIONS CHECKED", UVM_NONE)
    end else begin
      `uvm_error(get_type_name(), " SOME TESTS FAILED")
    end
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
  endfunction : report_phase

endclass

`endif