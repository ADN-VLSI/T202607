module data_receiver (
    val_rdy_if.receiver intf
);

  initial begin

    forever begin

      @(posedge intf.clk);

      intf.ready <= intf.rst_n ?  $urandom : '0;

    end

  end

endmodule
