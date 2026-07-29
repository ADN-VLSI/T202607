`timescale 1ns/1ps

module uart_tb;

  // 1. Instantiate the TWO separate interfaces
  uart_tx_if tx_if(); // Interface 1: Transmitter
  uart_rx_if rx_if(); // Interface 2: Receiver

  // 2. Physical wire connecting TX line to RX line
  assign rx_if.line = tx_if.line;

  initial begin
    int tx_data;
    int rx_data;
    bit rx_parity;

    // Set up VCD waveform dumping for GTKWave
    $dumpfile("uart_sim.vcd"); 
    $dumpvars(0, uart_tb);

    tx_data = 8'b10100101; 

    // 3. Call send on tx_if and recv on rx_if in parallel
    fork
      begin
        tx_if.send(.data(tx_data));
      end
      begin
        rx_if.recv(.data(rx_data), .parity(rx_parity));
      end
    join

    // 4. Print and Verify Results
    $display("Transmitted Data (tx_if) : 0b%08b", tx_data);
    $display("Received Data    (rx_if) : 0b%08b", rx_data);

    if (tx_data == rx_data) begin
      $display("SUCCESS: Sent from tx_if and received on rx_if successfully match!");
    end else begin
      $error("FAILURE: Data mismatch! Expected 0x%0h, got 0x%0h", tx_data, rx_data);
    end

    #100ns;
    $finish;
  end

endmodule