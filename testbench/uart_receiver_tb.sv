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

  task automatic drive_bit(input logic val);
    rx_o = val;
    #80;                 
  endtask

  task automatic send(input logic [7:0] data);
    int i;
    drive_bit(0);                    
    for (i = 0; i < 8; i++)
      drive_bit(data[i]);           
    drive_bit(1);                    
    #80;
  endtask


  initial begin

    $dumpfile("uart_receiver_tb.vcd");
    $dumpvars(0, uart_receiver_tb);

    arst_ni = 0;
    clk_i   = 0;
    rx_o    = 1;
    num_bits_i = 2'b11;             
    parity_en_i = 0;
    parity_type_i = 0;

    #100;
    arst_ni = 1;
    #100;

    // clock
    fork
      forever #5 clk_i = ~clk_i;
    join_none

    @(posedge clk_i);

    send(8'hA5);
    send(8'hFF);
    send(8'h00);

    $finish;

  end



always @(posedge clk_i)
    if (data_valid_o)
      $display("[%0t] got 0x%02h", $time, data_o);

endmodule
