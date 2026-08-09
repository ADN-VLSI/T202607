module intf_test;

  logic GLOBAL_RST_N;
  logic GLOBAL_CLK;

  val_rdy_if #(
      .DATA_WIDTH(16)
  ) intf1 (
      .rst_n(GLOBAL_RST_N),
      .clk  (GLOBAL_CLK)
  );

  initial begin
    forever begin
      GLOBAL_CLK = 1'b0;
      #5ns;
      GLOBAL_CLK = 1'b1;
      #5ns;
    end
  end

  initial begin

    $dumpfile("intf_test.vcd");
    $dumpvars(0, intf_test);

    $display("starting simulation");
    #100ns;

    intf1.valid = 1'b1;
    intf1.data  = 8'hAA;

    #100ns;

    $finish;

  end

endmodule
