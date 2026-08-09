module test;

  level_1 l1 ();

  logic [3:0] x = 0;


  initial begin
    forever begin
      #5ns x++;
    end
  end

  initial begin
    $timeformat(-7, 3, "USA", 15);
    $dumpfile("test.vcd");
    $dumpvars(1, test.l1.l2);
    #100ns;
    $error("Hello, World! [%0t]", $realtime);
    $display("WE SURSIVED");
    #100ns $finish;
  end

endmodule


/*

test |
     level_1 |
             level_2 |
                     level_3

*/
