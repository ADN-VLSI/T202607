class clock_generator;

  protected int unsigned      in_freq;
  rand protected int unsigned out_freq;

  constraint c_out_freq {
    out_freq >= 16;
    out_freq <= 5000;
  }

  function new(input int unsigned in_freq = 100, input int unsigned out_freq = 100);
    this.in_freq  = in_freq;
    this.out_freq = out_freq;
  endfunction

  virtual function automatic void set_in_freq(input int unsigned in_freq);
    this.in_freq = in_freq;
  endfunction

  virtual function automatic int unsigned get_in_freq();
    return this.in_freq;
  endfunction
  
  virtual function automatic void set_out_freq(input int unsigned out_freq);
    if (out_freq >= 16 && out_freq <= 5000) begin
      this.out_freq = out_freq;
    end else begin
      $display("Out of range frequency: %0d MHz", out_freq);
    end
  endfunction

  virtual function automatic int unsigned get_out_freq();
    return this.out_freq;
  endfunction

  virtual function automatic string to_string();
    return $sformatf("In Freq: %0d MHz\033[24GOut Freq: %0d MHz", get_in_freq(), get_out_freq());
  endfunction

  virtual function automatic void display();
    $display(to_string());
  endfunction

endclass


// Derived Class: PLL Generator (Inherits from clock_generator)

class pll_generator extends clock_generator;

  rand protected int unsigned ref_div;
  rand protected int unsigned fb_div;

  // Constraint: ref_div range [1 : 15]
  constraint c_ref_div {
    ref_div >= 1;
    ref_div <= 15;
  }

  // Constraint: fb_div range [16 : 511]
  constraint c_fb_div {
    fb_div >= 16;
    fb_div <= 511;
  }

  // Working equation constraint: ref_div * out_freq = in_freq * fb_div
  constraint c_pll_relation {
    ref_div * out_freq == in_freq * fb_div;
  }

  function new(input int unsigned in_freq  = 100,
               input int unsigned out_freq = 100,
               input int unsigned ref_div  = 1,
               input int unsigned fb_div   = 16);
    super.new(in_freq, out_freq);
    this.ref_div = ref_div;
    this.fb_div  = fb_div;
  endfunction

  virtual function automatic void set_ref_div(input int unsigned ref_div);
    this.ref_div = ref_div;
  endfunction

  virtual function automatic int unsigned get_ref_div();
    return this.ref_div;
  endfunction

  virtual function automatic void set_fb_div(input int unsigned fb_div);
    this.fb_div = fb_div;
  endfunction

  virtual function automatic int unsigned get_fb_div();
    return this.fb_div;
  endfunction

  virtual function automatic string to_string();
    string txt;
    $sformat(txt, "%s\033[48GRef Div: %0d\033[66GFB Div: %0d",
             super.to_string(), this.ref_div, this.fb_div);
    return txt;
  endfunction

endclass


module pll_test;

  initial begin
    pll_generator   pll;
    clock_generator clk_gen;

    pll = new(100, 100, 1, 16);

    // Polymorphism: Assigning derived object to base handle
    clk_gen = pll;

    $display("================ Initial Configuration ================");
    clk_gen.display();

    $display("\n================ 10 Random Configurations ================");
    repeat (10) begin
      if (clk_gen.randomize()) begin
        clk_gen.display();
      end else begin
        $display("Randomization Failed!");
      end
    end

    $display("==========================================================");
    $finish();
  end

endmodule