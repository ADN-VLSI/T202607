module func_task;

  mailbox #(int) mbx = new(20);

  task automatic send(int cnt = 5);
    repeat (cnt) begin
      int data;
      data = $urandom;
      mbx.put(data);
      $display("%0t\t SENT: 0x%0h", $realtime, data);
    end
  endtask

  task automatic recv();
    forever begin
      int wait_time;
      int data;
      wait_time = $urandom_range(1, 5);
      $display("%0t\t WAIT: %0dns", $realtime, wait_time);
      #(1ns * wait_time);
      mbx.get(data);
      $display("%0t\t RECV: 0x%0h", $realtime, data);
    end
  endtask

  initial begin
    $timeformat(-9, 0, "ns");
    fork
      send(21);
      recv();
    join_any

    while (mbx.num()) begin
      #1ns;
    end

    $finish;
  end

endmodule
