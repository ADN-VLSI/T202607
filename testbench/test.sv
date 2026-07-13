module test;

  level_1 l1 ();

  logic [3:0] x = 0;


  initial begin
    forever begin
      #5ns x++;
    end
  end

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);
    $display("Hello, World!");

    #100ns $finish;
  end

endmodule


/*

test |
     level_1 |
             level_2 |
                     level_3

*/
