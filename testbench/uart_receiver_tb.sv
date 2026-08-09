module uart_receiver_tb;

  logic       arst_ni;
  logic       clk_i;
  logic [1:0] num_bits_i;
  logic       parity_en_i;
  logic       parity_type_i;
  logic       rx_o;

  logic [7:0] data_o;
  logic       data_valid_o;

  uart_receiver #(.OVERSAMPLE(8)) dut (.*);


  initial begin

    // YOUR CODE HERE

  end

endmodule
