module struct_tb;

  import pkg_101::my_struct_t;

  initial begin
    my_struct_t my_struct;
    my_struct = 'h123;
    $display("Struct Testbench\n%p", my_struct);
    $finish;
  end

endmodule
