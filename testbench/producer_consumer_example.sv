module producer_consumer_example;
  typedef struct packed {  // Define a packet structure
    int data_id;
    logic [31:0] payload;
  } packet_type;

  mailbox #(packet_type) packet_mailbox = new(2);  // Bounded mailbox, capacity 2

  // Producer Process
  initial begin : producer_process
    packet_type pkt;
    for (int i = 0; i < 5; i++) begin
      pkt.data_id = i;
      pkt.payload = $random();
      if (packet_mailbox.try_put(pkt)) begin  // Non-blocking put attempt
        $display("[%0t] Producer: Sent packet ID %0d, Payload 0x%h", $time, pkt.data_id,
                 pkt.payload);
      end else begin
        $display("[%0t] Producer: Mailbox FULL! Failed to send packet ID %0d", $time, pkt.data_id);
      end
      #($urandom_range(5, 15));  // Random delay before next send
    end
    $display("[%0t] Producer: Finished sending packets.", $time);

    while (packet_mailbox.num() > 0) begin
      #1;  // Wait for mailbox to be emptied by consumer
    end

    $finish;  // End simulation after sending all packets
  end

  // Consumer Process
  initial begin : consumer_process
    packet_type received_packet;
    #10;  // Start consumer slightly later
    while (1) begin
      if (packet_mailbox.try_get(received_packet)) begin  // Non-blocking get attempt
        $display("[%0t] Consumer: Received packet ID %0d, Payload 0x%h", $time,
                 received_packet.data_id, received_packet.payload);
      end else begin
        $display("[%0t] Consumer: Mailbox EMPTY! Waiting for packets...", $time);
      end
      #($urandom_range(12, 20));  // Random delay before next receive attempt
      if (received_packet.data_id == 4) break;  // Simple exit condition after receiving packet ID 4
    end
    $display("[%0t] Consumer: Finished receiving packets.", $time);
  end
endmodule
