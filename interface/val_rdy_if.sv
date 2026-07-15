interface val_rdy_if #(
    parameter int DATA_WIDTH = 8
) (
    input logic rst_n,
    input logic clk
);

  logic [DATA_WIDTH-1:0] data;
  logic                  valid;
  logic                  ready;

  modport sender(input rst_n, input clk, output data, output valid, input ready);

  modport receiver(input rst_n, input clk, input data, input valid, output ready);

endinterface
