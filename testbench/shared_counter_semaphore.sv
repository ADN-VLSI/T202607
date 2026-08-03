module shared_counter_semaphore;

  int counter = 0;
  semaphore count_mutex = new(1);

  initial begin : process_A
    for (int i = 0; i < 5; i++) begin
      count_mutex.get(1);
      counter++;
      $display("[%0t] Process A: Incrementing counter to %0d", $time, counter);
      #5;
      count_mutex.put(1);
      #2;
    end
  end

  initial begin : process_B
    for (int i = 0; i < 5; i++) begin
      count_mutex.get(1);
      counter++;
      $display("[%0t] Process B: Incrementing counter to %0d", $time, counter);
      #5;
      count_mutex.put(1);
      #2;
    end
  end

  initial begin : monitor_process
    #100;
    $display("----------------------------------------");
    $display("[%0t] Final Counter Value: %0d", $time, counter);
    $display("----------------------------------------");
    $finish;
  end

endmodule