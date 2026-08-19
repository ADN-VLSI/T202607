`timescale 1ns/1ps

module fifo_tb;

  localparam int ADDR_WIDTH = 3;
  localparam int DATA_WIDTH = 8;
  localparam int DEPTH      = (2 ** ADDR_WIDTH); // DEPTH = 8

  
  logic                  clk_i;
  logic                  arst_ni;
  logic [DATA_WIDTH-1:0] data_in;
  logic                  data_in_valid_i;
  logic                  data_in_ready_o;
  logic [DATA_WIDTH-1:0] data_out_o;
  logic                  data_out_valid_o;
  logic                  data_out_ready_i;
  logic [ADDR_WIDTH:0]   count_o;

  
  fifo #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk_i            (clk_i),
    .arst_ni          (arst_ni),
    .data_in          (data_in),
    .data_in_valid_i  (data_in_valid_i),
    .data_in_ready_o  (data_in_ready_o),
    .data_out_o       (data_out_o),
    .data_out_valid_o (data_out_valid_o),
    .data_out_ready_i (data_out_ready_i),
    .count_o          (count_o)
  );

  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  

  task automatic write_data(input logic [DATA_WIDTH-1:0] wdata);
    @(posedge clk_i);
    data_in = wdata;
    data_in_valid_i = 1;
    
    
    do begin
      @(posedge clk_i);
    end while (!data_in_ready_o);
    
    data_in_valid_i = 0; 
    
    #1; 
    $display("[WRITE] Wrote Data = %3d | Current Count = %0d", wdata, count_o);
  endtask

  task automatic read_data();
    @(posedge clk_i);
    data_out_ready_i = 1;
    
   
    do begin
      @(posedge clk_i);
    end while (!data_out_valid_o);
    
    data_out_ready_i = 0;
    
    #1;
    $display("[READ]  Read Data  = %3d | Current Count = %0d", data_out_o, count_o);
  endtask

  task automatic read_write(input logic [DATA_WIDTH-1:0] wdata);
    @(posedge clk_i);
    data_in = wdata;
    data_in_valid_i = 1;
    data_out_ready_i = 1;
    
    @(posedge clk_i);
    data_in_valid_i = 0;
    data_out_ready_i = 0;
    
    #1; 
    $display("[R/W]   Simultaneous -> Wrote: %3d, Read: %3d | Current Count = %0d", wdata, data_out_o, count_o);
  endtask

  // ==========================================
  // MAIN TEST SEQUENCE
  // ==========================================

  initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, fifo_tb);

  
    arst_ni          = 0;
    data_in          = 0;
    data_in_valid_i  = 0;
    data_out_ready_i = 0;

    
    #15;
    arst_ni = 1;
    #1;
    $display("--- RESET RELEASED. Initial Count = %0d ---", count_o);
    $display("--------------------------------------------------");

    
    write_data(10);
    write_data(20);
    read_data();
    read_data();
    $display("--------------------------------------------------");

    
    write_data(30);  
    read_write(40);  
    read_data();     
    $display("--------------------------------------------------");

  
    $display("--- FILLING FIFO TO MAX DEPTH (8) ---");
    for (int i = 0; i < DEPTH; i++) begin
      write_data(100 + i);
    end
    $display("--------------------------------------------------");

    
    $display("--- TRYING TO WRITE WHEN FULL ---");
    @(posedge clk_i);
    data_in         = 99;
    data_in_valid_i = 1;
    
    #1; 
    if (data_in_ready_o == 0) begin
      $display("[OVERFLOW PASS] FIFO is full! data_in_ready_o = 0, Count remains = %0d", count_o);
    end else begin
      $display("[OVERFLOW FAIL] FIFO accepted data while full!");
    end

    @(posedge clk_i);
    data_in_valid_i = 0; // Turn off write attempt
    $display("--------------------------------------------------");

    $display("--- EMPTYING FIFO ---");
    for (int i = 0; i < DEPTH; i++) begin
      read_data();
    end
    $display("--------------------------------------------------");
    
    $display("\n--- TEST: READ WHEN FIFO IS EMPTY ---");
    $display("Before Read: Count = %0d | data_out_valid_o = %b", count_o, data_out_valid_o);

   @(posedge clk_i);
   data_out_ready_i = 1; 

   #1;
   $display("During Read: data_out_valid_o = %b (Should be 0, so no read occurs)", data_out_valid_o);
   @(posedge clk_i);
   data_out_ready_i = 0; 

   #1;
   $display("After Read : Count = %0d (Should remain 0)", count_o);
   
   $display("\n--- TEST: WRITE DURING RESET ---");
   arst_ni = 0; // Assert reset active (0)

   @(posedge clk_i);
   data_in         = 8'hAA;
   data_in_valid_i = 1; // Attempt write while reset is active

   #1;
   $display("During Reset Write: Count = %0d | data_in_ready_o = %b", count_o, data_in_ready_o);

  @(posedge clk_i);
 data_in_valid_i = 0; // Turn off write attempt
  arst_ni          = 1; // Release reset back to active high

  #1;
 $display("After Reset Released: Count = %0d (Should still be 0)", count_o);
    #20;
    $display("--- TEST FINISHED ---");
    $finish;
  end

endmodule