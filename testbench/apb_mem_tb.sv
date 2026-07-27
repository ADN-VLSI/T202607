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

  task automatic apply_reset();
    #100ns;
    pclk    <= 1'b0;
    presetn <= 1'b0;
    intf.apply_reset(1);
    #100ns;
    presetn <= 1'b1;
    #100ns;
  endtask

  task automatic start_clock();
    fork
      forever begin
        #5ns pclk <= 1'b0;
        #5ns pclk <= 1'b1;
      end
    join_none
    repeat (5) @(posedge pclk);
  endtask

  initial begin
    int rdata;

    $timeformat(-9, 0, "ns");
    $dumpfile("apb_mem_tb.vcd");
    $dumpvars(0, apb_mem_tb);

    apply_reset();
    start_clock();

    intf.write(0, 'h12345678);
    intf.write(4, 'h90ABCDEF);

    intf.read(0, rdata);
    $display("Read from address 0: %h", rdata);
    intf.read(4, rdata);
    $display("Read from address 4: %h", rdata);

    #100ns;
    $finish;
  end

endmodule
