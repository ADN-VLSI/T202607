`timescale 1ns / 1ps

module gray_to_bin_tb;

  parameter int WIDTH = 4;

  // Global pass/fail flag
  bit test_failed = 0;

  gray2bin_if #(.WIDTH(WIDTH)) intf ();

  gray2bin dut (.vif(intf));

  function automatic logic [WIDTH-1:0] tb_gray2bin(input logic [WIDTH-1:0] g);
    logic [WIDTH-1:0] b;
    b[WIDTH-1] = g[WIDTH-1];
    for (int i = WIDTH - 2; i >= 0; i--) begin
      b[i] = g[i] ^ b[i+1];
    end
    return b;
  endfunction

  initial begin
    $dumpfile("gray2bin_sim.vcd");
    $dumpvars(0, gray2bin_tb);

    // Run test cases
    apply_and_compare(4'b0000);
    apply_and_compare(4'b0011);
    apply_and_compare(4'b0110);
    apply_and_compare(4'b1101);
    apply_and_compare(4'b1111);
    apply_and_compare(4'b1000);

    if (test_failed == 0) begin
      $display("           TEST SUCCESSFUL! All matched.          ");
    end else begin
      $display("           TEST UNSUCCESSFUL! Mismatch found.     ");
    end

    #10;
    $finish;
  end

  task automatic apply_and_compare(input logic [WIDTH-1:0] test_gray);
    logic [WIDTH-1:0] expected_bin;

    intf.gray = test_gray;
    #10;

    expected_bin = tb_gray2bin(intf.gray);

    if (intf.bin !== expected_bin) begin
      test_failed = 1;
    end
  endtask

endmodule
