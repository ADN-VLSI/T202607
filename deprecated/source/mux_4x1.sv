module mux_4x1 #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] in0_i,
    input  logic [WIDTH-1:0] in1_i,
    input  logic [WIDTH-1:0] in2_i,
    input  logic [WIDTH-1:0] in3_i,
    input  logic [1:0]       sel_i,
    output logic [WIDTH-1:0] out_o
);

  always_comb begin
    case (sel_i)
      2'b00:   out_o = in0_i;
      2'b01:   out_o = in1_i;
      2'b10:   out_o = in2_i;
      2'b11:   out_o = in3_i;
      default: out_o = '0;
    endcase
  end

endmodule
