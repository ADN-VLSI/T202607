module condition_test;

  initial begin
    bit [4:0] a[$];

    repeat (4) begin
      randcase
        1: begin
          a.push_back($urandom());
          $display("pushed back in a : 0x%0x", a[$]);
        end
        1: begin
          a.push_front($urandom());
          $display("pushed front in a : 0x%0x", a[0]);
        end
      endcase
    end

    foreach (a[potato]) begin
      $display("The number a[%0d] is 0x%0x", potato, a[potato]);
    end

    foreach (a[sata]) begin
      casez (a[sata])
        'b????1: $display("The number a[%0d] is odd", sata);
        'b????0: $display("The number a[%0d] is even", sata);
      endcase
    end
    $finish;
  end

endmodule
