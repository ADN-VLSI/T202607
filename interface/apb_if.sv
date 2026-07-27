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

  // WRITE
  task automatic write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
    // ADD YOU CODE HERE
  endtask

endinterface

