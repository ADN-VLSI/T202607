`timescale 1ns/1ps

module fifocondition_tb;

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

  // Instantiate the updated DUT
  fifocondition #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (.*);

  // Clock Generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // =========================================================================
  // TASK DEFINITIONS (Conditions)
  // =========================================================================

  // 1. Case 00: No Push and No Pop
  task automatic dataNoPushandPop();
    $display("\n[CONDITION 00] Executing dataNoPushandPop...");
    if (!arst_ni) begin
      $display("  -> STATUS: arst_ni is 0. Operation Blocked.");
      return;
    end
    
    @(posedge clk_i);
    data_in_valid_i  = 0;
    data_out_ready_i = 0;
    @(posedge clk_i);
    
    $display("  -> DONE: No Write, No Read. Count remains %0d", count_o);
  endtask

  // 2. Case 01: Pop Only
  task automatic dataOUT();
    $display("\n[CONDITION 01] Executing dataOUT...");
    if (!arst_ni) begin
      $display("  -> STATUS: arst_ni is 0. Operation Blocked.");
      return;
    end
    
    @(posedge clk_i);
    data_in_valid_i  = 0;
    data_out_ready_i = 1;
    
    wait (data_out_valid_o); // Wait until data is valid
    @(posedge clk_i);
    
    data_out_ready_i = 0;
    #1; // Delay to catch updated data_out_o
    $display("  -> SUCCESS: Popped Data = 0x%h, Current Count = %0d", data_out_o, count_o);
  endtask

  // 3. Case 10: Push Only
  task automatic dataIN(input logic [DATA_WIDTH-1:0] d_in);
    $display("\n[CONDITION 10] Executing dataIN with Data = 0x%h...", d_in);
    if (!arst_ni) begin
      $display("  -> STATUS: arst_ni is 0. Operation Blocked.");
      return;
    end
    
    @(posedge clk_i);
    data_in = d_in;
    data_in_valid_i  = 1;
    data_out_ready_i = 0;
    
    wait (data_in_ready_o); // Wait until FIFO is ready
    @(posedge clk_i);
    
    data_in_valid_i = 0;
    #1

    $display("  -> SUCCESS: Pushed Data = 0x%h, Current Count = %0d", d_in, count_o);
  endtask

  // 4. Case 11: Simultaneous Push and Pop
  task automatic dataPushandPop(input logic [DATA_WIDTH-1:0] d_in);
    $display("\n[CONDITION 11] Executing dataPushandPop with Write Data = 0x%h...", d_in);
    if (!arst_ni) begin
      $display("  -> STATUS: arst_ni is 0. Operation Blocked.");
      return;
    end
    
    @(posedge clk_i);
    data_in = d_in;
    data_in_valid_i  = 1;
    data_out_ready_i = 1;
    
    // Wait until BOTH valid and ready handshake can happen
    wait (data_in_ready_o && data_out_valid_o); 
    @(posedge clk_i);
    
    data_in_valid_i  = 0;
    data_out_ready_i = 0;
    #1;
    $display("  -> SUCCESS: Pushed 0x%h and Popped 0x%h in same cycle. Count = %0d", d_in, data_out_o, count_o);
  endtask

  // 5. Depth Fault Condition
  task automatic datadepthfault();
    $display("\n[FAULT TEST] Executing datadepthfault...");
    if (!arst_ni) return;
    
    $display("  -> FILLING FIFO to maximum depth (8)...");
    while (data_in_ready_o == 1) begin
      dataIN($urandom_range(0, 255));
    end
    
    $display("  -> FIFO FULL. Attempting to write one more data (0xFF)...");
    @(posedge clk_i);
    data_in = 8'hFF;
    data_in_valid_i = 1;
    
    @(posedge clk_i);
    if (!data_in_ready_o) begin
      $display("  -> FAULT HANDLED: data_in_ready_o is 0. Data rejected. Count remains %0d", count_o);
    end else begin
      $display("  -> ERROR: FIFO accepted data when full!");
    end
    data_in_valid_i = 0;
  endtask

  // 6. Reset Task
  task automatic dataErase();
    $display("\n[SYSTEM] Executing dataErase...");
    arst_ni = 0;
    data_in_valid_i  = 0;
    data_out_ready_i = 0;
    @(posedge clk_i);
    @(posedge clk_i);
    arst_ni = 1; // Release reset
    @(posedge clk_i);
    $display("  -> SUCCESS: System Reset Complete. FIFO is erased. Count = %0d", count_o);
  endtask

  // 7. Bonus: Empty Fault Condition
  task automatic dataEmptyFault();
    $display("\n[FAULT TEST] Executing dataEmptyFault...");
    if (!arst_ni) return;
    
    $display("  -> EMPTYING FIFO to zero...");
    while (data_out_valid_o == 1) begin
      dataOUT();
    end
    
    $display("  -> FIFO EMPTY. Attempting to read data...");
    @(posedge clk_i);
    data_out_ready_i = 1;
    
    @(posedge clk_i);
    if (!data_out_valid_o) begin
      $display("  -> FAULT HANDLED: data_out_valid_o is 0. Read ignored. Count remains %0d", count_o);
    end else begin
      $display("  -> ERROR: FIFO gave valid data when empty!");
    end
    data_out_ready_i = 0;
  endtask


  // =========================================================================
  // MAIN TEST SEQUENCE
  // =========================================================================
  initial begin
    $dumpfile("fifocondition.vcd");
    $dumpvars(0, fifocondition_tb);

    // Initial default values
    arst_ni = 1; 
    data_in = 0;
    data_in_valid_i  = 0;
    data_out_ready_i = 0;
    #10;

    $display("========================================");
    $display(" STARTING FIFO CONDITIONS TEST SEQUENCE ");
    $display("========================================");

    // 1. Initial Reset
    dataErase();

    // 2. Test Reset condition blocks operations
    $display("\n--- Testing arst_ni = 0 Condition ---");
    arst_ni = 0;
    dataIN(8'hAA); // Should get blocked
    dataOUT();     // Should get blocked
    
    // Release reset to continue normal testing
    dataErase();

    // 3. Test Normal Operations
    $display("\n--- Testing Normal Operations ---");
    
    dataNoPushandPop();        // Case 00
    
    dataIN(8'h11);             // Case 10
    dataIN(8'h22);             // Case 10
    
    dataOUT();                 // Case 01
    
    dataPushandPop(8'h33);     // Case 11
    
    // 4. Test Faults
    datadepthfault();          // Overflow test
    
    dataEmptyFault();          // Underflow test

    $display("\n========================================");
    $display(" ALL TESTS COMPLETED SUCCESSFULLY ");
    $display("========================================");
    
    #10;
    $finish;
  end

endmodule