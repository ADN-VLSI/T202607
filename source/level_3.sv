module level_3;

  int x = 2100;

  initial begin
    forever begin
      #5ns x++;
    end
  end

endmodule