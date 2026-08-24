module bin_to_gray #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] bin_i,
    output logic [WIDTH-1:0] gray_o
);

  always_comb begin
    gray_o = bin_i ^ (bin_i >> 1);
  end

endmodule
