module fun_task_test_myself;
     mailbox #(int) mbx = new(20);
ami modify korlam
     //send task
     task automatic send(int cnt = 5);
        repeat (cnt) begin
            int data;
            data = $urandom;
            mbx.put(data);
            $display("%0t\t SENT:: 0x%0h", $realtime, data);
        end

     endtask


     //recieve task
     task automatic recv();
        forever begin
            int wait_time, data;
            wait_time = $urandom_range(1, 5);
            $display("%0t\t WAIT:: %0dns", $realtime, wait_time);
            #(wait_time);
            mbx.get(data);
            $display("%0t\t RECV:: 0x%0h", $realtime, data);
        end
     endtask


     //simulation
     inital begin
        $timeformat(-9, 0, "ns");
        fork 
            send(21);
            recv();
        join_any
    

        while(mbx.num()) begin
            #1ns;
        end
        $finish
    end
endmodule