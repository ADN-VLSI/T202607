interface gray2bin_if #(
  parameter int WIDTH = 64
);

  logic [WIDTH-1:0] gray;
  logic [WIDTH-1:0] bin;

endinterface