interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic pclk,
    input logic presetn
);

  logic                  psel;
  logic                  penable;
  logic [ADDR_WIDTH-1:0] paddr;
  logic                  pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH-1:0] prdata;
  logic                  pready;

  modport master(
      input pclk,
      input presetn,
      output psel,
      output penable,
      output paddr,
      output pwrite,
      output pwdata,
      input prdata,
      input pready
  );

  modport slave(
      input pclk,
      input presetn,
      input psel,
      input penable,
      input paddr,
      input pwrite,
      input pwdata,
      output prdata,
      output pready
  );

  bit is_clock_edge_aligned;

  always @(posedge pclk) begin
    is_clock_edge_aligned <= 1'b1;
    #1;
    is_clock_edge_aligned <= 1'b0;
  end

  task automatic apply_reset(bit mode = 1);  // mode 0 = slave
    if (mode) begin
      psel    <= '0;
      penable <= '0;
      paddr   <= '0;
      pwrite  <= '0;
      pwdata  <= '0;
    end else begin
      prdata <= '0;
      pready <= '0;
    end
  endtask

  task automatic do_transaction(input logic [ADDR_WIDTH-1:0] addr, input logic write,
                                input logic [DATA_WIDTH-1:0] wdata,
                                output logic [DATA_WIDTH-1:0] rdata);
    wait (is_clock_edge_aligned);
    psel    <= 1'b1;
    penable <= 1'b0;
    paddr   <= addr;
    pwrite  <= write;
    pwdata  <= wdata;
    @(posedge pclk);
    penable <= 1'b1;
    do @(posedge pclk); while (~pready);
    rdata = prdata;
    psel <= 1'b0;
  endtask

  task automatic write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] wdata);
    bit dummy_1;
    do_transaction(addr, '1, wdata, dummy_1);
  endtask

  task automatic read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] rdata);
    do_transaction(addr, '0, '0, rdata);
  endtask

endinterface

