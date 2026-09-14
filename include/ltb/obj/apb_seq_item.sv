
`include "uart_regif_pkg.sv"

class apb_seq_item;

  rand logic        we;
  rand logic [ 4:0] addr;
  rand logic [31:0] data;

  bit               allow_random_addr = 0;

  constraint addr_c {
    if (!allow_random_addr) {
      addr inside {uart_regif_pkg::ADDR_CTRL, uart_regif_pkg::ADDR_CFG, uart_regif_pkg::ADDR_STATUS,
                   uart_regif_pkg::ADDR_TXD, uart_regif_pkg::ADDR_RXD, uart_regif_pkg::ADDR_INTR};
    }
  }

endclass
