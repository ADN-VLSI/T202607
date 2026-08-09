module data_sender (
    val_rdy_if.sender intf
);

  initial begin

    forever begin

      @(posedge intf.clk);

      intf.valid <= intf.rst_n ?  $urandom : '0;
      intf.data  <= $urandom;

    end

  end

endmodule
