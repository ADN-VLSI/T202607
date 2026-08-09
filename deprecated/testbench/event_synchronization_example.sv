module event_synchronization_example;
  event config_ready_event; // Declare an event
  event data_processed_event;

  // Configuration Process
  initial begin : config_process
    $display("[%0t] Configuration Process: Starting...", $time);
    #25; // Simulate configuration time
    $display("[%0t] Configuration Process: Configuration complete. Triggering event...", $time);
    -> config_ready_event; // Trigger the event to signal configuration completion
    wait(data_processed_event.triggered); // Wait for data processing to complete
    $display("[%0t] Configuration Process: Data processing acknowledged. Exiting.", $time);
  end

  // Data Processing Process
  initial begin : data_process
    $display("[%0t] Data Process: Waiting for configuration...", $time);
    @(config_ready_event); // Wait for the configuration_ready_event to be triggered
    $display("[%0t] Data Process: Configuration ready. Starting data processing...", $time);
    #30; // Simulate data processing time
    $display("[%0t] Data Process: Data processing complete.", $time);
    -> data_processed_event; // Signal data processing completion
  end

  initial begin
    #100 $finish; // Simulation timeout
  end
endmodule
