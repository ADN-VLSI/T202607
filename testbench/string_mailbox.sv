module string_mailbox;

  mailbox #(string) mbx = new();

    initial begin
        automatic string msg[$] ='{"Hello", "World", "SystemVerilog"};

        foreach (msg[i]) begin
          mbx.put(msg[i]);
          $display("[%0t] Sent: %s", $time, msg[i]);
        end
    end

    initial begin
        string msg;

        repeat (3) begin
          mbx.get(msg);
          $display("[%0t] Received: %s", $time, msg);
        end
    end


endmodule
