`ifndef __GUARD_APB_SEQ_ITEM_SV__
`define __GUARD_APB_SEQ_ITEM_SV__ 0

`include "uart_regif_pkg.sv"

class apb_seq_item;

  import uart_regif_pkg::ADDR_CTRL;
  import uart_regif_pkg::ADDR_CFG;
  import uart_regif_pkg::ADDR_STATUS;
  import uart_regif_pkg::ADDR_TXD;
  import uart_regif_pkg::ADDR_RXD;
  import uart_regif_pkg::ADDR_INTR;

  rand logic        we;
  rand logic [ 4:0] addr;
  rand logic [31:0] data;

  bit               allow_random_addr = 0;
  bit               allow_random_data = 0;

  constraint addr_c {
    if (!allow_random_addr) {

      // Write transaction
      if (we) {
        addr inside {ADDR_CTRL, ADDR_CFG, ADDR_TXD, ADDR_INTR};
      }

      // Read transaction
      else {
        addr inside {ADDR_CTRL, ADDR_CFG, ADDR_STATUS, ADDR_RXD, ADDR_INTR};
      }
    }
  }

  constraint data_c {
    if (!allow_random_data) {
      /* verilog_format: off */
      if (addr == ADDR_CTRL)  data [31: 4] == '0;
      if (addr == ADDR_CFG)   data [31:21] == '0;
      if (addr == ADDR_TXD)   data [31: 8] == '0;
      if (addr == ADDR_INTR)  data [31: 4] == '0;
    /* verilog_format: on */
    }
  }

  virtual function automatic string to_string();
    return $sformatf("we=%0b addr=0x%02h data=0x%08h", we, addr, data);
  endfunction

  virtual function automatic void display();
    $display("%s", to_string());
  endfunction

endclass

`endif
