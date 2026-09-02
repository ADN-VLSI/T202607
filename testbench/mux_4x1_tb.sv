`timescale 1ns/1ps

module mux_4x1_tb;

  localparam int WIDTH = 4;

  logic [WIDTH-1:0] in0;
  logic [WIDTH-1:0] in1;
  logic [WIDTH-1:0] in2;
  logic [WIDTH-1:0] in3;
  logic [1:0]       sel;
  logic [WIDTH-1:0] out;

  int pass_count = 0;
  int fail_count = 0;

  // DUT instantiation
  mux_4x1 #(
      .WIDTH(WIDTH)
  ) dut (
      .in0_i(in0),
      .in1_i(in1),
      .in2_i(in2),
      .in3_i(in3),
      .sel_i(sel),
      .out_o(out)
  );

  task automatic check(
      input [1:0]       s,
      input [WIDTH-1:0] expected
  );
    #5;
    if (out === expected) begin
      $display("[PASS] time=%0t ns | sel=%b => out=0x%0h (Expected: 0x%0h)", $time, s, out, expected);
      pass_count++;
    end else begin
      $display("[FAIL] time=%0t ns | sel=%b => out=0x%0h (Expected: 0x%0h)", $time, s, out, expected);
      fail_count++;
    end
  endtask

  initial begin
    // Waveform dump for GTKWave / VS Code WaveTrace
    $dumpfile("mux_4x1.vcd");
    $dumpvars(0, mux_4x1_tb);

    $display("========================================");
    $display("     4x1 MULTIPLEXER TESTBENCH");
    $display("========================================");

    in0 = 4'hA;
    in1 = 4'hB;
    in2 = 4'hC;
    in3 = 4'hD;

    // Test each select line
    sel = 2'b00; check(sel, in0);
    sel = 2'b01; check(sel, in1);
    sel = 2'b10; check(sel, in2);
    sel = 2'b11; check(sel, in3);

    // Dynamic inputs test
    #10;
    in0 = 4'h1; in1 = 4'h2; in2 = 4'h3; in3 = 4'h4;
    sel = 2'b00; check(sel, in0);
    sel = 2'b01; check(sel, in1);
    sel = 2'b10; check(sel, in2);
    sel = 2'b11; check(sel, in3);

    #10;
    $display("========================================");
    $display(" Tests Passed: %0d | Tests Failed: %0d", pass_count, fail_count);
    $display("========================================");
    $finish;
  end

endmodule
