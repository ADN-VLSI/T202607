`ifndef __GUARD_SCOREBOARD_SV__
`define __GUARD_SCOREBOARD_SV__ 0

`include "ltb/obj/apb_rsp_item.sv"
`include "ltb/obj/uart_rsp_item.sv"

import uart_regif_pkg::ADDR_TXD;
import uart_regif_pkg::ADDR_RXD;

//--------------------------------------------------------------------------------------------------
// TX PATH : CPU writes TXD        => expected
//           byte appears on tx_o  => actual
//
// RX PATH : byte driven on rx_i   => expected
//           CPU reads RXD         => actual
//--------------------------------------------------------------------------------------------------

class scoreboard;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // FIELDS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  mailbox #(apb_rsp_item)  apb_mbx;      // apb_monitor        -> scoreboard
  mailbox #(uart_rsp_item) uart_tx_mbx;  // monitor on tx line -> scoreboard
  mailbox #(uart_rsp_item) uart_rx_mbx;  // monitor on rx line -> scoreboard

  bit [7:0] tx_expected_q[$];
  bit [7:0] rx_expected_q[$];

  int pass = 0;
  int fail = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual function automatic void set_apb_mailbox(mailbox #(apb_rsp_item) mbx);
    this.apb_mbx = mbx;
  endfunction

  virtual function automatic void set_uart_tx_mailbox(mailbox #(uart_rsp_item) mbx);
    this.uart_tx_mbx = mbx;
  endfunction

  virtual function automatic void set_uart_rx_mailbox(mailbox #(uart_rsp_item) mbx);
    this.uart_rx_mbx = mbx;
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // APB SIDE : TXD write creates an expectation, RXD read is checked
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic apb_process();
    forever begin

      apb_rsp_item item;
      bit [7:0] expected;

      apb_mbx.get(item);

      // Errored access : ignore
      if (item.slverr === 1'b1) continue;

      // ---- TX path : CPU wrote a byte, the DUT must transmit it
      if ((item.we === 1'b1) && (item.addr == ADDR_TXD)) begin

        tx_expected_q.push_back(item.data[7:0]);
        $display("[%0t] SCB  : expecting 0x%02h on tx line", $time, item.data[7:0]);

      end

      // ---- RX path : CPU read a byte, it must be what we drove on rx line
      else if ((item.we === 1'b0) && (item.addr == ADDR_RXD)) begin

        if (rx_expected_q.size() == 0) begin
          fail++;
          $display("[%0t] FAIL : RXD read 0x%02h but nothing was driven on rx line", $time,
                   item.data[7:0]);
          continue;
        end

        expected = rx_expected_q.pop_front();

        if (item.data[7:0] === expected) begin
          pass++;
          $display("[%0t] PASS : RXD = 0x%02h", $time, item.data[7:0]);
        end else begin
          fail++;
          $display("[%0t] FAIL : RXD expected 0x%02h, got 0x%02h", $time, expected, item.data[7:0]);
        end

      end

    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TX LINE : compare what the DUT actually transmitted
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic uart_tx_process();
    forever begin

      uart_rsp_item item;
      bit [7:0] expected;

      uart_tx_mbx.get(item);

      if (tx_expected_q.size() == 0) begin
        fail++;
        $display("[%0t] FAIL : unexpected byte 0x%02h on tx line", $time, item.data);
        continue;
      end

      expected = tx_expected_q.pop_front();

      if (item.data === expected) begin
        pass++;
        $display("[%0t] PASS : tx line = 0x%02h", $time, item.data);
      end else begin
        fail++;
        $display("[%0t] FAIL : tx line expected 0x%02h, got 0x%02h", $time, expected, item.data);
      end

    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RX LINE : whatever we drove into the DUT becomes an expectation
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task automatic uart_rx_process();
    forever begin

      uart_rsp_item item;

      uart_rx_mbx.get(item);

      rx_expected_q.push_back(item.data);
      $display("[%0t] SCB  : expecting 0x%02h from RXD read", $time, item.data);

    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task run();
    fork
      apb_process();
      uart_tx_process();
      uart_rx_process();
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual function automatic void report();

    $display("");
    $display("========================================");
    $display(" FINAL TEST SUMMARY");
    $display("========================================");
    $display(" PASS            = %0d", pass);
    $display(" FAIL            = %0d", fail);
    $display("========================================");

    if ((fail == 0) && (pass > 0) && (tx_expected_q.size() == 0) && (rx_expected_q.size() == 0))
      $display(" ALL TESTS PASSED");
    else $display(" SOME TESTS FAILED");

    $display("========================================");

  endfunction

endclass

`endif