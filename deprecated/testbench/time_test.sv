module time_test;

  initial begin
    time t;
    t = 'x;
    $display("Time printed as t: %0t", t);
    $display("Time printed as h: %0h", t);
    $finish;
  end

endmodule
