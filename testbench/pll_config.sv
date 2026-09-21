class pll_config;

  // Fixed value
  protected int in_freq = 100;

  // Configurable values
  rand protected int ref_div;
  rand protected int fb_div;

  // Calculated output
  protected int out_freq;


  // ref_div = 1 to 15
  constraint c_ref_div {
    ref_div >= 1;
    ref_div <= 15;
  }


  // fb_div = 16 to 511
  constraint c_fb_div {
    fb_div >= 16;
    fb_div <= 511;
  }


  // Output frequency constraint: 16 MHz <= out_freq <= 5000 MHz
  constraint c_out_freq {
    (100 * fb_div) >= (16   * ref_div);
    (100 * fb_div) <= (5000 * ref_div);
  }


  // Constructor
  function new();
    this.in_freq = 100;
  endfunction


  // Calculate output frequency
  virtual function automatic void calculate_out_freq();

    out_freq = (in_freq * fb_div) / ref_div;

  endfunction


  // Check output frequency limit
  virtual function automatic bit valid_out_freq();

    if ((out_freq >= 16) && (out_freq <= 5000))
      return 1;
    else
      return 0;

  endfunction


  virtual function automatic int get_in_freq();
    return this.in_freq;
  endfunction


  virtual function automatic int get_ref_div();
    return this.ref_div;
  endfunction


  virtual function automatic int get_fb_div();
    return this.fb_div;
  endfunction


  virtual function automatic int get_out_freq();
    return this.out_freq;
  endfunction


  virtual function automatic string to_string();

    return $sformatf(
      "IN_FREQ: %0d MHz   REF_DIV: %0d   FB_DIV: %0d   OUT_FREQ: %0d MHz",
      get_in_freq(),
      get_ref_div(),
      get_fb_div(),
      get_out_freq()
    );

  endfunction


  virtual function automatic void display();
    $display(to_string());
  endfunction

endclass



module pll_test;

  initial begin

    pll_config pll;

    pll = new();

    repeat (10) begin

      if (pll.randomize()) begin

        pll.calculate_out_freq();

        if (pll.valid_out_freq()) begin
          pll.display();
        end
        else begin
          $display(
            "INVALID CONFIG -> REF_DIV=%0d FB_DIV=%0d OUT_FREQ=%0d MHz",
            pll.get_ref_div(),
            pll.get_fb_div(),
            pll.get_out_freq()
          );
        end

      end
      else begin
        $display("Randomization Failed");
      end

    end

    $finish();

  end

endmodule