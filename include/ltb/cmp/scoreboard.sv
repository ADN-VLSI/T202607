`ifndef __GUARD_SCOREBOARD_SV__
`define __GUARD_SCOREBOARD_SV__

`include "ltb/obj/apb_rsp_item.sv"
`include "ltb/obj/uart_rsp_item.sv"

import uart_regif_pkg::ADDR_TXD;
import uart_regif_pkg::ADDR_RXD;

class scoreboard;

    //////////////////////////////////////////////////////////////////////

    mailbox #(apb_rsp_item) apb_mbx; //apb_monitor to scoreboard
    mailbox #(uart_rsp_item) uart_tx_mbx; //uart_tx monitor to scoreboard
    mailbox #(uart_rsp_item) uart_rx_mbx; // uart_rx monitor to scoreboard

    bit [7:0] tx_expected_q[$];
    bit [7:0] rx_expected_q[$];

    int pass = 0;
    int fail = 0;

    ///////////////////////////////////////////////////////////////////////////////////

    virtual function automatic void set_apb_mailbox(mailbox #(apb_rsp_item) mbx);
        this.apb_mbx = mbx;
    endfunction

    virtual function automatic void set_uart_tx_mailbox(mailbox #(uart_rsp_item) mbx);
        this.uart_tx_mbx = mbx;
    endfunction

    virtual function automatic void set_uart_rx_mailbox(mailbox #(uart_rsp_item) mbx);
        this.uart_rx_mbx = mbx;
    endfunction

    ////////////////////////////////////////////////////////////////////////////
    //APB Process
    ////////////////////////////////////////////////////////////////////////////

    virtual task automatic apb_process();
        forever begin
            apb_rsp_item item;
            bit [7:0] expected;

            apb_mbx.get(item);

            if (item.slverr == 1`b1) continue;
            
            //---TX PATH---
            if ((item.we == 1`b1) && (item.addr == ADDR_TXD)) begin
                t_expected_q.push_back(item.data[7:0]);
                $display("[%0t] SCB: Expecting 0x%02h on tx line", $time, item.data[7:0]);
            end

            //---RX PATH---

        end
    endtask

    ///////////////////////////////////////////////////////////////////////////////
    //UART PROCESS
    ///////////////////////////////////////////////////////////////////////////////

    //---TX LINE---
    virtual task automatic uart_tx_process();
        forever begin
           
            uart_rsp_item item;
            bit [7:0] expected;

            uart_tx_mbs.get(item);

            if (tx_expected_q.size() == 0) begin
                fail++;
                $display("[%0t] FAIL: Unexpected byte 0x%02h on tx line", $time, item.data);
                continue;
            end

            expected = tx_expected_q.pop_front();

            if (item.data === expected) begin
                pass++;
                $display("[%0t] PASS: tx line: 0x%02h", $time, item.data);
            end else begin
                fail++;
                $display("[%0t] FAIL: tx line expected 0x%02h but got 0x%02h", $time, expected, item.data);
            end
        end
    endtask

    //---RX LINE---
    virtual task automatic uart_rx_process();

        forever begin

            uart_rsp_item item;

            uart_rx_mbx.get(item);

            rx_expected_q.push_back(item.data);
            $display("[%0t] SCB: Expecting 0x%02h on tx line", $time, item.data[7:0]);
        end
    endtask

    






endclass

`endif