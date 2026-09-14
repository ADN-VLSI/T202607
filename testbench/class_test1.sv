class class_test1;

  localparam int INPUT_FREQ_MHZ = 100;

  rand protected int unsigned divider_ref;
  rand protected int unsigned divider_fb;
  protected int unsigned frequency_out;

  constraint c_divider_ref_range {
    divider_ref inside {[1 : 15]};
  }

  
  constraint c_divider_fb_range {
    divider_fb inside {[16 : 511]};
  }

  
  constraint c_output_freq_bounds {
    (INPUT_FREQ_MHZ * divider_fb) >= (16   * divider_ref);
    (INPUT_FREQ_MHZ * divider_fb) <= (5000 * divider_ref);
  }

  function new();
  this.in_freq = 100;
  endfunction


  virtual function automatic void compute_freq();
    this.frequency_out = (INPUT_FREQ_MHZ * this.divider_fb) / this.divider_ref;
  endfunction

  
  virtual function automatic bit is_freq_valid();
    return (this.frequency_out >= 16) && (this.frequency_out <= 5000);
  endfunction


  virtual function automatic int get_in_freq();  return INPUT_FREQ_MHZ;     endfunction
  virtual function automatic int get_ref_div();  return this.divider_ref;   endfunction
  virtual function automatic int get_fb_div();   return this.divider_fb;    endfunction
  virtual function automatic int get_out_freq();  return this.frequency_out; endfunction

  // String formatting
  virtual function automatic string convert2string();
    return $sformatf(
      "IN_FREQ: %0d MHz   REF_DIV: %0d   FB_DIV: %0d   OUT_FREQ: %0d MHz",
      get_in_freq(),
      get_ref_div(),
      get_fb_div(),
      get_out_freq()
    );
  endfunction

  virtual function automatic void print();
    $display("%s", convert2string());
  endfunction

endclass


module pll_test;

  initial begin
    pll_config pll_inst = new();

    repeat (10) begin
      if (!pll_inst.randomize()) begin
        $display("Randomization Failed");
        continue;
      end

      pll_inst.compute_freq();

      if (pll_inst.is_freq_valid()) begin
        pll_inst.print();
      end else begin
        $display(
          "INVALID CONFIG -> REF_DIV=%0d FB_DIV=%0d OUT_FREQ=%0d MHz",
          pll_inst.get_ref_div(),
          pll_inst.get_fb_div(),
          pll_inst.get_out_freq()
        );
      end
    end

    $finish();
  end

endmodule