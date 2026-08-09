module string_mailbox_example;

  mailbox #(string) string_mb = new();

  initial begin
    fork
      
      begin : producer_process
        automatic string messages[] = '{"Hello", "World", "SystemVerilog", "Mailbox Test"};

        foreach (messages[i]) begin
          automatic string msg = messages[i];
          $display("[%0t] Producer: Sending \"%s\"", $time, msg);
          string_mb.put(msg);
          #10;               
        end
      end

      
      begin : consumer_process
        automatic string received_msg;

        #5; 
        forever begin
          string_mb.get(received_msg);
          $display("[%0t] Consumer: Received \"%s\"", $time, received_msg);
          #5;
        end
      end
    join_any

    
    wait (string_mb.num() == 0);
  
    $finish;
  end

endmodule