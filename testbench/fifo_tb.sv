`timescale 1ns/1ps
module fifo_tb;

  
  parameter int ADDR_WIDTH = 3;
  parameter int DATA_WIDTH = 8;

  
  logic clk_i;
  logic arst_ni;

 
  logic [DATA_WIDTH-1:0] data_in;
  logic data_in_valid_i;

  
  logic data_in_ready_o;

  logic [DATA_WIDTH-1:0] data_out_o;
  logic data_out_valid_o;

  logic data_out_ready_i;

  logic [ADDR_WIDTH:0] count_o;

 
  fifo #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk_i              (clk_i),
    .arst_ni            (arst_ni),

    .data_in            (data_in),
    .data_in_valid_i    (data_in_valid_i),
    .data_in_ready_o    (data_in_ready_o),

    .data_out_o         (data_out_o),
    .data_out_valid_o   (data_out_valid_o),
    .data_out_ready_i   (data_out_ready_i),

    .count_o            (count_o)
  );

  
  initial begin
    clk_i = 0;

    forever #5 clk_i = ~clk_i;
  end

  
  initial begin
      $dumpfile("fifo.vcd");
      $dumpvars(0, fifo_tb);
    
    arst_ni          = 0;
    data_in          = 0;
    data_in_valid_i  = 0;
    data_out_ready_i = 0;

    
    #12;

    arst_ni = 1;

    $display("====================================");
    $display("RESET RELEASED");
    $display("====================================");

    
    @(posedge clk_i);

    data_in       = 8'd10;
    data_in_valid_i = 1;

    wait (data_in_ready_o);

    @(posedge clk_i);

    data_in_valid_i = 0;

    $display("WRITE: data = %0d, count = %0d",
             data_in, count_o);

    
    @(posedge clk_i);

    data_in = 8'd20;
    data_in_valid_i = 1;

    wait (data_in_ready_o);

    @(posedge clk_i);

    data_in_valid_i = 0;

    $display("WRITE: data = %0d, count = %0d",
             data_in, count_o);

    
    @(posedge clk_i);

    data_in = 8'd30;
    data_in_valid_i = 1;

    wait (data_in_ready_o);

    @(posedge clk_i);

    data_in_valid_i = 0;

    $display("WRITE: data = %0d, count = %0d",
             data_in, count_o);

    
    @(posedge clk_i);

    data_out_ready_i = 1;

    wait (data_out_valid_o);

    @(posedge clk_i);
    #1;

    data_out_ready_i = 0;

    $display("READ: data = %0d, count = %0d",
             data_out_o, count_o);

    
    @(posedge clk_i);

    data_out_ready_i = 1;

    wait (data_out_valid_o);

    @(posedge clk_i);
    #1;

    data_out_ready_i = 0;

    $display("READ: data = %0d, count = %0d",
             data_out_o, count_o);

           

    @(negedge clk_i);


    data_in = 8'd40;
    data_in_valid_i = 1;


    data_out_ready_i = 1;


   $display("----------------------------------");
   $display("BEFORE READ + WRITE");
   $display("WRITE = %0d", data_in);
   $display("count = %0d", count_o);
   $display("----------------------------------");


   @(posedge clk_i);

   #1;


   $display("----------------------------------");
   $display("AFTER READ + WRITE");
   $display("read data = %0d", data_out_o);
   $display("count     = %0d", count_o);
   $display("----------------------------------");
   @(negedge clk_i);

   data_in_valid_i  = 0;
   data_out_ready_i = 0;

   @(negedge clk_i);

   data_out_ready_i = 1;


   @(posedge clk_i);
   #1;

    $display("FINAL READ: data = %0d, count = %0d",
         data_out_o, count_o);


   @(negedge clk_i);

     data_out_ready_i = 0;

    
    #20;

    $display("====================================");
    $display("TEST FINISHED");
    $display("====================================");


   



   #10;
   $finish;

  end

endmodule