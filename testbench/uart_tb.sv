module uart_tb;

  uart_if intf();

  int tx_data;
  int rx_data;
  bit rx_parity;

  initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    $display("starting simulation");
    #100ns;

    tx_data = 8'b01001100;
    #10;

    fork
      intf.send(tx_data);
      intf.recv(rx_data, rx_parity);
    join

    $display("Tx Data: %b", tx_data);
    $display("Rx Data: %b", rx_data);

    if (rx_data == tx_data)
      $display("PASS: sent 0x%0h, received 0x%0h", tx_data, rx_data);
    else
      $display("FAIL: sent 0x%0h, received 0x%0h", tx_data, rx_data);

    #100ns;

    $finish;
  end

endmodule