module level_1;

  level_2 l2();

  int x = 100;

  initial begin
    forever begin
      #5ns x++;
    end
  end

endmodule