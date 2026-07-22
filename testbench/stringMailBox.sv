module string_mailbox_example;

  
  mailbox #(string) str_mbox = new(3);

  
  initial begin : sender
    str_mbox.put("Hello");
    $display("[%0t] Sender: Sent Hello", $time);

    str_mbox.put("World");
    $display("[%0t] Sender: Sent World", $time);

    str_mbox.put("SystemVerilog");
    $display("[%0t] Sender: Sent SystemVerilog", $time);
  end

  
  initial begin : receiver
    string msg;

    str_mbox.get(msg);
    $display("[%0t] Receiver: Received\t%s", $time, msg);

    str_mbox.get(msg);
    $display("[%0t] Receiver: Received\t%s", $time, msg);

    str_mbox.get(msg);
    $display("[%0t] Receiver: Received\t %s", $time, msg);

    $finish;
  end

  


endmodule
