`timescale 1ns/1ps

module gray2bin_tb;

  parameter int WIDTH = 4;

  gray2bin_if #(.WIDTH(WIDTH)) intf();

  gray2bin dut (
    .vif(intf)
  );

  initial begin
    $dumpfile("gray2bin_sim.vcd");
    $dumpvars(0, gray2bin_tb);

    intf.gray = 4'b0000;
    #10;
    check_result(4'b0000);

    intf.gray = 4'b0001;
    #10;
    check_result(4'b0001);

    intf.gray = 4'b0011;
    #10;
    check_result(4'b0010);


    $display("ALL TESTS COMPLETED");
 
    #10;
    $finish;
  end

  task automatic check_result(input logic [WIDTH-1:0] expected_bin);
    if (intf.bin === expected_bin) begin
      $display("[PASS] Input Gray: %b | Output Bin: %b | Match!", intf.gray, intf.bin);
    end else begin
      $error("[FAIL] Input Gray: %b | Output Bin: %b (Expected: %b)", intf.gray, intf.bin, expected_bin);
    end
  endtask

endmodule