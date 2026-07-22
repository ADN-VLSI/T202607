module shared_counter_semaphore;
    semaphore counter_semaphore = new(1);
    int counter = 0;

    initial begin : process_1
        repeat (10) begin
            $display("[%0t] Process 1: "Attempting to acquire semaphore...", $time");
            counter_semaphore.get(1);

            $display([%0t] Process 1: Acquired semaphore, counter = %0d", $time, counter);
            counter++;
            $display("[%0t] Process 1: Incremented counter to %0d", $time, counter);
            #5ns;

            counter_semaphore.put(1);
            $display("[%0t] Process 1: Semaphore released.", $time);
            #5ns;
        end
    end

    initial begin : process_2
            repeat (10) begin
                $display("[%0t] Process 2: Attempting to acquire semaphore...", $time);
                counter_semaphore.get(1);

                $display("[%0t] Process 2: Semaphore Acquired, counter = %0d", $time, counter);
                counter++;

                $display("[%0t] Process 1: Incremented counter to %0d", $time, counter);
                #5ns;

                counter_semaphore.put(1);
                $display("[%0t] Process 2: Semaphore released.", $time);

                #5ns;   
            end 
    end

endmodule