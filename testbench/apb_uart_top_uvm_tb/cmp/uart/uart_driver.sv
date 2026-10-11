`ifndef __GUARD_UART_DRIVER_SV__
`define __GUARD_UART_DRIVER_SV__ 0

`include "apb_uart_top_uvm_tb/obj/uart/uart_seq_item.sv"

class uart_driver extends uvm_driver #(uart_seq_item);

  `uvm_component_utils(uart_driver)

  function new (string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual uart_if intf;

  virtual function void connect_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual uart_if)::get(this, "", "intf", intf)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      forever begin
        seq_item_port.get_next_item(req);
        phase.raise_objection(this);
        intf.send(
          req.data,
          req.baud_rate,
          req.parity_en,
          req.parity_type,
          req.extra_stop,
          req.data_bits
        );
        phase.drop_objection(this);
        seq_item_port.item_done();
      end
    join_none
  endtask

endclass

`endif
