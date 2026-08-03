`timescale 1ns/1ps

module gray2bin_tb;

  parameter int WIDTH = 4;

  gray2bin_if #(.WIDTH(WIDTH)) intf();

  gray2bin dut (
    .vif(intf)
  );

  function automatic logic [WIDTH-1:0] tb_gray2bin(input logic [WIDTH-1:0] g);
    logic [WIDTH-1:0] b;
    b[WIDTH-1] = g[WIDTH-1];
    for (int i = WIDTH-2; i >= 0; i--) begin
      b[i] = g[i] ^ b[i+1];
    end
    return b;
  endfunction

  initial begin
    $dumpfile("gray2bin_sim.vcd");
    $dumpvars(0, gray2bin_tb);

    apply_and_compare(4'b0000);
    apply_and_compare(4'b0011);
    apply_and_compare(4'b0110);
    apply_and_compare(4'b1101);
    apply_and_compare(4'b1111);
    apply_and_compare(4'b1000);

    $display(" ok! ");


    #10;
    $finish;
  end

  task automatic apply_and_compare(input logic [WIDTH-1:0] test_gray);
    logic [WIDTH-1:0] expected_bin;

    intf.gray = test_gray;
    #10;

    expected_bin = tb_gray2bin(intf.gray);

    if (intf.bin === expected_bin) begin
      $display("[MATCH] Input Gray: %b | RTL Bin: %b | TB Expected: %b",
               intf.gray, intf.bin, expected_bin);
    end
    else begin
      $error("[MISMATCH] Input Gray: %b | RTL Bin: %b | TB Expected: %b",
             intf.gray, intf.bin, expected_bin);
    end
  endtask

endmodule