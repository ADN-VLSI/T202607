module counter;
  semaphore resource_semaphore = new(1); // Binary semaphore (mutex) - 2 keys available
  integer count= 0;

  // Process 1: Access and modify shared data
  initial begin : process_one
    for (int i = 0; i < 5; i++) begin
        resource_semaphore.get(1); // Acquire the semaphore
        count += 1; // Access and modify shared_data - critical section

      $display("[%0t] Process 1: Attempting to acquire semaphore...", $time);
      #5ns;
      resource_semaphore.put(1);
      #2ns; // Release the semaphore
      
  end
end

  // Process 2: Access and modify shared data concurrently
  initial begin : process_two
    for (int i = 0; i < 5; i++) begin
        resource_semaphore.get(1); // Acquire the semaphore
        count += 1; // Access and modify shared_data - critical section

      $display("[%0t] Process 1: Attempting to acquire semaphore...[%0t]", $time,$time);
      #5ns;
      resource_semaphore.put(1);
      #2ns; // Release the semaphore
    
  end
end

  initial begin
    #100ns;
    $display("[%0t] Final count value: %0d", $time, count);
  end
endmodule