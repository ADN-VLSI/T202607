module uart_transmitter_tb;

  logic       arst_ni;
  logic       clk_i;

  logic [7:0] data_i;
  logic [1:0] num_bits_i;
  logic       parity_en_i;
  logic       parity_type_i;
  logic       extra_stop_i;
  logic       data_valid_i;

  logic       data_ready_o;
  logic       tx_o;

  uart_transmitter u_dut (.*);

  task automatic send (input int data, input int num_bits = 3, input bit parity_en = 0, input bit parity_type = 0, input bit extra_stop = 0);
    data_i        <= data;
    num_bits_i    <= num_bits;
    parity_en_i   <= parity_en;
    parity_type_i <= parity_type;
    extra_stop_i  <= extra_stop;
    data_valid_i  <= 1'b1;
    do @(posedge clk_i); while (!data_ready_o);
    data_valid_i <= 1'b0;
  endtask

  initial begin

    $dumpfile("uart_transmitter_tb.vcd");
    $dumpvars(0, uart_transmitter_tb);

    #100ns;

    arst_ni       <= '0;
    clk_i         <= '0;
    data_i        <= '0;
    num_bits_i    <= '0;
    parity_en_i   <= '0;
    parity_type_i <= '0;
    extra_stop_i  <= '0;
    data_valid_i  <= '0;

    #100ns;

    arst_ni <= '1;

    #100ns;

    fork
      forever begin
        #5ns clk_i <= ~clk_i;
      end
    join_none
    @(posedge clk_i);

    send(8'hA5, 3, 1, 0, 0);
    send(8'hFF, 3, 1, 0, 0);
    send(8'h00, 3, 1, 0, 0);

    #500ns;
    $finish;

  end

endmodule
