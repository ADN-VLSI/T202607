//=========================================================
//mailbox example
//=========================================================
module producer_consumer;
    typedef struct {
        int data_id;
        logic [31:0] payload;
    } packet_type;

    mailbox #(packet_type) packet_mailbox = new(2);

    // Producer process
    initial begin : producer_process
        packet_type pkt;
        for (int i = 0; i < 5; i++) begin
            pkt.data_id = i;
            pkt.payload = $random();
            if (packet_mailbox.try_put(pkt)) begin
                $display("[%0t] Producer: Sent Packet ID %0d, Payload %0h", $time, pkt.data_id, pkt.payload);
            end else begin
                $display("[%0t] Producer: Mailbox full, could not send Packet ID %0d", $time, pkt.data_id);
            end
            #($urandom_range(5, 15)); // Random delay between 5 and 15 time units
        end
        $display("[%0t] Producer: Finished sending packets", $time);

        while (packet_mailbox.num() > 0) begin
            #1; // Wait for the consumer to process remaining packets
        end

        $finish;
    end

    // Consumer process
    initial begin : consumer_process
        packet_type rcv_pkt;
        #10;
        while (1) begin
            if (packet_mailbox.try_get(rcv_pkt)) begin
                $display("[%0t] Consumer: Received Packet ID %0d, Payload %0h", $time, rcv_pkt.data_id, rcv_pkt.payload);
            end else begin
                $display("[%0t] Consumer: Mailbox empty, waiting for packets", $time);
            end
            #($urandom_range(2, 20)); // Random delay between 5 and
            if (rcv_pkt.data_id == 4) break;
        end
        $display("[%0t] Consumer: Finished receiving packets", $time);
    end
endmodule
