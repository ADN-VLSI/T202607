module shared_resource_protection;
  semaphore resource_semaphore = new(1); // Binary semaphore (mutex) - 1 key available
  integer shared_data = 0;

  // Process 1: Access and modify shared data
  initial begin : process_one
    $display("[%0t] Process 1: Attempting to acquire semaphore...", $time);
    resource_semaphore.get(1); // Acquire the semaphore (blocking) - exclusive access granted
    $display("[%0t] Process 1: Semaphore acquired. Accessing shared resource...", $time);
    shared_data++; // Access and modify shared_data - critical section
    $display("[%0t] Process 1: Shared data incremented to %0d", $time, shared_data);
    #20; // Simulate resource usage time
    resource_semaphore.put(1); // Release the semaphore - allows other processes to access
    $display("[%0t] Process 1: Semaphore released.", $time);
  end

  // Process 2: Access and modify shared data concurrently
  initial begin : process_two
    #10; // Start process 2 slightly later
    $display("[%0t] Process 2: Attempting to acquire semaphore...", $time);
    resource_semaphore.get(1); // Process 2 will block here until Process 1 releases semaphore
    $display("[%0t] Process 2: Semaphore acquired. Accessing shared resource...", $time);
    shared_data += 5; // Access and modify shared_data - critical section
    $display("[%0t] Process 2: Shared data incremented to %0d", $time, shared_data);
    #15; // Simulate resource usage time
    resource_semaphore.put(1); // Release the semaphore
    $display("[%0t] Process 2: Semaphore released.", $time);
  end

  initial begin
    #50 $finish; // Simulation timeout
  end
endmodule
