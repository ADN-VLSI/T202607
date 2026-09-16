interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic pclk,
    input logic presetn
);

  logic                    psel;
  logic                    penable;
  logic [  ADDR_WIDTH-1:0] paddr;
  logic                    pwrite;
  logic [  DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH/8-1:0] pstrb;
  logic                    pready;
  logic [  DATA_WIDTH-1:0] prdata;
  logic                    pslverr;

  modport master(
      output psel,
      output penable,
      output paddr,
      output pwrite,
      output pwdata,
      output pstrb,
      input pready,
      input prdata,
      input pslverr
  );

  modport slave(
      input psel,
      input penable,
      input paddr,
      input pwrite,
      input pwdata,
      input pstrb,
      output pready,
      output prdata,
      output pslverr
  );

  modport monitor(
      input psel,
      input penable,
      input paddr,
      input pwrite,
      input pwdata,
      input pstrb,
      input pready,
      input prdata,
      input pslverr
  );

  bit is_clock_edge_aligned;

  always @(posedge pclk) begin
    is_clock_edge_aligned <= 1'b1;
    #1step;
    is_clock_edge_aligned <= 1'b0;
  end

  task automatic apply_reset(bit mode = 1);  // mode 0 = slave
    if (mode) begin
      psel    <= '0;
      penable <= '0;
      paddr   <= '0;
      pwrite  <= '0;
      pwdata  <= '0;
      pstrb   <= '0;
    end else begin
      pready  <= '0;
      prdata  <= '0;
      pslverr <= '0;
    end
  endtask

  task automatic do_transaction(input logic [ADDR_WIDTH-1:0] addr, input logic write,
                                input logic [DATA_WIDTH-1:0] wdata,
                                output logic [DATA_WIDTH-1:0] rdata, output logic slverr);
    wait (is_clock_edge_aligned);
    psel    <= 1'b1;
    penable <= 1'b0;
    paddr   <= addr;
    pwrite  <= write;
    pwdata  <= wdata;
    pstrb   <= '1;
    @(posedge pclk);
    penable <= 1'b1;
    do @(posedge pclk); while (~pready);
    rdata  = prdata;
    slverr = pslverr;
    psel <= 1'b0;
  endtask

  task automatic get_transaction(output logic [ADDR_WIDTH-1:0] addr, output logic write,
                                 output logic [DATA_WIDTH-1:0] data, output logic slverr);
    do @(posedge pclk); while (!(presetn === '1 && psel === '1 && penable === '0));
    do @(posedge pclk); while (!(presetn === '1 && psel === '1 && penable === '1 && pready === '1));
    addr  = paddr;
    write = pwrite;
    data  = (write) ? pwdata : prdata;
    slverr = pslverr;
  endtask

  task automatic write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] wdata);
    bit dummy_1;
    bit dummy_2;
    do_transaction(addr, '1, wdata, dummy_1, dummy_2);
  endtask

  task automatic read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] rdata);
    bit dummy_2;
    do_transaction(addr, '0, '0, rdata, dummy_2);
  endtask

  task automatic wait_till_idle(int x = 10);
    int i;
    while (i < x) begin
      @(posedge pclk);
      i++;
      if (psel == 1) i = 0;
    end
  endtask

endinterface

