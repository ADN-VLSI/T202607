`timescale 1ns / 1ps

module gray2bin #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] gray_i,
    output logic [WIDTH-1:0] bin_o
);

  always_comb begin
    bin_o[WIDTH-1] = gray_i[WIDTH-1];

    for (int i = WIDTH - 2; i >= 0; i--) begin
      bin_o[i] = gray_i[i] ^ bin_o[i+1];
    end
  end

endmodule
