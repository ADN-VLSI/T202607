`ifndef __GUARD_SCOREBOARD_SV__
`define __GUARD_SCOREBOARD_SV__ 0

`include "ltb/obj/apb_rsp_item.sv"
`include "ltb/obj/uart_rsp_item.sv"

`include "uart_regif_pkg.sv"

import uart_regif_pkg::ADDR_CFG;
import uart_regif_pkg::ADDR_TXD;


class scoreboard;

  mailbox #(apb_rsp_item)  apb_mbx;
  mailbox #(uart_rsp_item) uart_mbx;

  bit [7:0] tx_data[$];

  int current_baud_rate   = 9600;
  int current_data_bits   = 8;
  bit current_parity_en   = 0;
  bit current_parity_type = 0;
  bit current_extra_stop  = 0;

  virtual uart_if tx_intf;

  int pass = 0;
  int fail = 0;


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual function automatic void set_apb_mailbox(
      mailbox #(apb_rsp_item) mbx
  );
    this.apb_mbx = mbx;
  endfunction


  virtual function automatic void set_uart_mailbox(
      mailbox #(uart_rsp_item) mbx
  );
    this.uart_mbx = mbx;
  endfunction


  virtual function automatic void set_interface(
      virtual uart_if intf
  );
    this.tx_intf = intf;
  endfunction


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual task run();

    fork


      //////////////////////////////////////////////////////////////////////////////////////////////
      // APB RESPONSE PROCESSING
      //////////////////////////////////////////////////////////////////////////////////////////////

      forever begin

        apb_rsp_item item;

        apb_mbx.get(item);


        // Update UART configuration
        if ((item.slverr == 0) &&
            (item.we == 1) &&
            (item.addr == ADDR_CFG)) begin

          int baud_div;

          baud_div = item.data[15:0];

          if (baud_div != 0)
            current_baud_rate = 100_000_000 / baud_div;

          case (item.data[17:16])
            2'b00: current_data_bits = 5;
            2'b01: current_data_bits = 6;
            2'b10: current_data_bits = 7;
            2'b11: current_data_bits = 8;
          endcase

          current_parity_en   = item.data[18];
          current_parity_type = item.data[19];
          current_extra_stop  = item.data[20];


          // Synchronize UART monitor with DUT configuration
          if (tx_intf != null) begin

            tx_intf.baud_rate   = current_baud_rate;
            tx_intf.data_bits   = current_data_bits;
            tx_intf.parity_en   = current_parity_en;
            tx_intf.parity_type = current_parity_type;
            tx_intf.extra_stop  = current_extra_stop;

          end

        end


        // Store expected UART TX data
        else if ((item.slverr == 0) &&
                 (item.we == 1) &&
                 (item.addr == ADDR_TXD)) begin

          tx_data.push_back(item.data[7:0]);

        end

      end


      //////////////////////////////////////////////////////////////////////////////////////////////
      // UART RESPONSE PROCESSING
      //////////////////////////////////////////////////////////////////////////////////////////////

      begin

        int byte_idx = 0;

        forever begin

          uart_rsp_item item;
          bit [7:0] expected_data;
          bit byte_ok;

          uart_mbx.get(item);

          byte_idx++;
          byte_ok = 1;


          // Check that expected data exists
          if (tx_data.size() == 0) begin

            fail++;

            $display(
              "FAIL : Byte %0d unexpected, got %02h",
              byte_idx,
              item.data
            );

          end

          else begin

            expected_data = tx_data.pop_front();


            // Check UART configuration
            if (item.data_bits !== current_data_bits) begin

              $display(
                "FAIL : Byte %0d data bits mismatch, expected %0d, got %0d",
                byte_idx,
                current_data_bits,
                item.data_bits
              );

              byte_ok = 0;

            end


            if (item.parity_en !== current_parity_en) begin

              $display(
                "FAIL : Byte %0d parity enable mismatch, expected %0b, got %0b",
                byte_idx,
                current_parity_en,
                item.parity_en
              );

              byte_ok = 0;

            end


            // Compare expected data with actual UART data
            if (item.data !== expected_data) begin

              $display(
                "FAIL : Byte %0d expected %02h, got %02h",
                byte_idx,
                expected_data,
                item.data
              );

              byte_ok = 0;

            end


            // Check parity
            if (current_parity_en) begin

              if (item.parity !==
                  (current_parity_type ? ~(^item.data) : (^item.data))) begin

                $display(
                  "FAIL : Byte %0d parity mismatch",
                  byte_idx
                );

                byte_ok = 0;

              end

            end


            if (byte_ok) begin

              pass++;

              $display(
                "PASS : Byte %0d received = %02h",
                byte_idx,
                item.data
              );

            end

            else begin

              fail++;

            end

          end

        end
      end


    join_none

  endtask


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT
  //////////////////////////////////////////////////////////////////////////////////////////////////

  virtual function automatic void report();

    $display("");
    $display("========================================");
    $display("FINAL TEST SUMMARY");
    $display("========================================");
    $display("TOTAL PASS = %0d", pass);
    $display("TOTAL FAIL = %0d", fail);
    $display("========================================");

    if ((fail == 0) &&
        (pass > 0) &&
        (tx_data.size() == 0))
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");

    $display("========================================");

  endfunction


endclass

`endif