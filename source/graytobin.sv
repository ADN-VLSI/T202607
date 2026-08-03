`timescale 1ns/1ps

module gray2bin (
  gray2bin_if vif
);

  always_comb begin
    vif.bin[vif.WIDTH-1] = vif.gray[vif.WIDTH-1];

    for (int i = vif.WIDTH-2; i >= 0; i--) begin
      vif.bin[i] = vif.gray[i] ^ vif.bin[i+1];
    end
  end

endmodule