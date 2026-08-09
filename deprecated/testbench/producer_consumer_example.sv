module semaphore;

  int counter = 0;
  semaphore count_mutex = new(1);

  initial begin : process_A
    for (int i = 0; i < 10; i++) begin
      count_mutex.get(1);
      counter++;
      $display("[%0t] Process A: Incrementing counter 1 to %0d", $time, counter);
      #5;
      count_mutex.put(1);
      #2;
    end
  end

  initial begin : process_B
    for (int i = 0; i < 5; i++) begin
      count_mutex.get(1);
      counter++;
      $display("[%0t] Process B: Incrementing counter 2 to %0d", $time, counter);
      #5;
      count_mutex.put(1);
      #2;
    end
  end

  initial begin : monitor_process
    #100;
        $display("[%0t] Final Counter Value: %0d", $time, counter);
    $finish;
  end

endmodule