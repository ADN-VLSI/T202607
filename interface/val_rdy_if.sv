interface val_rdy_if (
    input logic rst_n,
    input logic clk
);

  logic [7:0] data;
  logic       valid;
  logic       ready;

endinterface
