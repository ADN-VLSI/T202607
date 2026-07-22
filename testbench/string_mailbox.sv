module string_mailbox;

  mailbox #(string) mbx = new(20);

  initial
  begin
    string messages = '{"Hello", "World", "SystemVerilog"};

  end


  task automatic send();
    repeat (cnt)
    begin
      int data;
      data = $urandom;
      mbx.put(data);
      $display("%0t\t SENT: 0x%0h", $realtime, data);
    end
  endtask

  task automatic recv();
    forever
    begin
      int wait_time;
      int data;
      wait_time = $urandom_range(1, 5);
      $display("%0t\t WAIT: %0dns", $realtime, wait_time);
      #(1ns * wait_time);
      mbx.get(data);
      $display("%0t\t RECV: 0x%0h", $realtime, data);
    end
  endtask

  initial
  begin
    #100;
    $finish;
  end
  
endmodule
