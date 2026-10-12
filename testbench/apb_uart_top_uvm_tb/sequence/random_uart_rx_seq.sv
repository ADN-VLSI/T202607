`ifndef __GUARD_RANDOM_UART_RX_SEQ_SV__
`define __GUARD_RANDOM_UART_RX_SEQ_SV__ 0

`include "apb_uart_top_uvm_tb/obj/uart/uart_seq_item.sv"


class random_uart_rx_seq extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(random_uart_rx_seq)

  function new(string name = "random_uart_rx_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    int seq_length;

    if (!uvm_config_db#(int)::get(uvm_root::get(), "parameter", "RANDOM_UART_RX_SEQ_LENGTH", seq_length)) begin
        seq_length = 1;
    end

    repeat (seq_length) begin 
        `uvm_do_with(req, {
        data inside {[8'h00:8'hFF]};
        baud_rate == 115200;
        parity_en == 0;
        parity_type == 0;
        extra_stop == 0;
        data_bits == 8;
    })
    end

  endtask : body

endclass
`endif