/*
    create mailbox parameterised to carry string
    implement 2 processes: one to sent string messages into 
    mailbox, the other to receive and display string messages
*/

module practice1;

    mailbox #(string) string_mbox = new();

    //sender process
    initial begin : sender_process
        automatic string sen_msg = "SystemVerilog";
        string_mbox.put(sen_msg); // sends `sen_msg` to mailbox `string_mbox`
        $display("[Sender] Sent '%s' to mailbox", sen_msg);
    end

    //receiver process
    initial begin: receiver_process
        string rec_msg;
        string_mbox.get(rec_msg); // receives message from mailbox `string_mbox` and stores it in `rec_msg`
        $display("[Receiver] Received message: %s", rec_msg);
    end

endmodule 