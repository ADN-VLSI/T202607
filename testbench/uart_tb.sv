`timescale 1ns/1ps

module uart_tb;

  // 1. Instantiate both interfaces
  uart_tx_if tx_if(); 
  uart_rx_if rx_if(); 

  // 2. Connect physical serial wire between interfaces
  assign rx_if.line = tx_if.line;

  initial begin
    int tx_data;
    int rx_data;
    bit rx_parity;

    // 3. Setup VCD Dump File for GTKWave
    $dumpfile("uart_sim.vcd"); 
    $dumpvars(0, uart_tb);

    tx_data = 8'b10100101; 

    // 4. Concurrently run transmitter and receiver tasks
    fork
      begin
        tx_if.send(.data(tx_data));
      end
      begin
        rx_if.recv(.data(rx_data), .parity(rx_parity));
      end
    join

    // 5. Check and print test results
    $display("---------------------------------------");
    $display("Transmitted Data (TX) : 0b%08b", tx_data);
    $display("Received Data    (RX) : 0b%08b", rx_data);
    $display("---------------------------------------");

    if (tx_data == rx_data) begin
      $display("STATUS: SUCCESS - Sent and Received data match!");
    end else begin
      $error("STATUS: FAILURE - Data mismatch!");
    end

    #100ns;
    $finish;
  end

endmodule