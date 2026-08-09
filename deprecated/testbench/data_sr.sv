module data_sr;

  logic GLOBAL_RST_N;
  logic GLOBAL_CLK;

  val_rdy_if #(
      .DATA_WIDTH(16)
  ) intf1 (
      .rst_n(GLOBAL_RST_N),
      .clk  (GLOBAL_CLK)
  );

  initial begin

    #50ns;
    GLOBAL_RST_N <= 1'b0;
    #50ns;
    GLOBAL_RST_N <= 1'b1;
    #50ns;

    forever begin
      GLOBAL_CLK <= 1'b0;
      #5ns;
      GLOBAL_CLK <= 1'b1;
      #5ns;
    end
  end


  data_sender sndr (.intf(intf1));
  data_receiver scvr (.intf(intf1));


  initial begin

    $dumpfile("data_sr.vcd");
    $dumpvars(0, data_sr);

    $display("starting simulation");
    #1us;

    $finish;

  end

endmodule
