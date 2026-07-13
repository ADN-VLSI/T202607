module level_2;

  level_3 l3();

  int x = 1100;

  initial begin
    forever begin
      #5ns x++;
    end
  end

endmodule