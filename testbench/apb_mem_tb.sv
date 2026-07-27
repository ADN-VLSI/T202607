module apb_mem_tb;

  localparam int CHOSEN_ADDR_WIDTH = 5;
  localparam int CHOSEN_DATA_WIDTH = 32;

  logic presetn;
  logic pclk;

  apb_if #(
      .ADDR_WIDTH(CHOSEN_ADDR_WIDTH),
      .DATA_WIDTH(CHOSEN_DATA_WIDTH)
  ) intf (
      .pclk(pclk),
      .presetn(presetn)
  );

  apb_mem #(
      .ADDR_WIDTH(CHOSEN_ADDR_WIDTH),
      .DATA_WIDTH(CHOSEN_DATA_WIDTH)
  ) u_dut (
      .preset_ni(presetn),
      .pclk_i   (pclk),
      .psel_i   (intf.psel),
      .penable_i(intf.penable),
      .paddr_i  (intf.paddr),
      .pwrite_i (intf.pwrite),
      .pwdata_i (intf.pwdata),
      .pready_o (intf.pready),
      .prdata_o (intf.prdata)
  );

  initial begin
    $timeformat(-9, 0, "ns");
    $dumpfile("apb_mem_tb.vcd");
    $dumpvars(0, apb_mem_tb);

    // ADD WRITE AND READ TESTS
    // YOUR CODE HERE

    #100ns;
    $finish;
  end

endmodule
