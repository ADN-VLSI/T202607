`ifndef __GUARD_APB_RSP_ITEM_SV__
`define __GUARD_APB_RSP_ITEM_SV__ 0


`include "uart_regif_pkg.sv"

`include "ltb/obj/apb_seq_item.sv"

class apb_rsp_item extends apb_seq_item;

  // rand logic        we;
  // rand logic [ 4:0] addr;
  // rand logic [31:0] data;
  logic slverr;

  virtual function automatic string to_string();
    // return $sformatf("we=%0b addr=0x%02h data=0x%08h", we, addr, data);
    return $sformatf("%s slverr=%0b", super.to_string(), slverr);
  endfunction

endclass

`endif
