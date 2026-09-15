class ClockConfig;
  // Express frequencies as integers to satisfy the compiler
  // 100 MHz = 100_000 kHz
  int in_freq_khz = 100000; 

  // Configurable variables (Integers - perfectly valid)
  rand int ref_div;
  rand int fb_div;

  // Output frequency limits as integers (in kHz)
  // 16 MHz to 5000 MHz becomes 16_000 kHz to 5_000_000 kHz
  rand int ou_freq_khz;

  // Constraint rules using pure integer types
  constraint clk_constraints {
    ref_div inside {[1 : 15]};
    fb_div  inside {[16 : 511]};
    
    // Bounds in kHz
    ou_freq_khz >= 16000;
    ou_freq_khz <= 5000000;
    
    // Rearranged math formula to avoid division drops/fractions:
    // ref_div * ou_freq = in_freq * fb_div
    (ref_div * ou_freq_khz) == (in_freq_khz * fb_div);
  }

  function void display();
    // Convert back to real only for display purposes
    real in_freq_mhz = in_freq_khz / 1000.0;
    real ou_freq_mhz = ou_freq_khz / 1000.0;

    $display("====== PLL Randomization Result ======");
    $display(" Input Freq  : %0.1f MHz", in_freq_mhz);
    $display(" REF Divider : %0d", ref_div);
    $display(" FB Divider  : %0d", fb_div);
    $display(" Output Freq : %0.3f MHz", ou_freq_mhz);
    $display("======================================");
  endfunction
endclass

module pll_random_test;
  initial begin
    // Added 'automatic' keyword to fix the warning 
    automatic ClockConfig cfg = new();
    
    $display("Starting PLL Simulation... Generating 5 random configurations:");
    
    repeat(5) begin
      if (cfg.randomize()) begin
        cfg.display();
      end else begin
        $error("Solver Error: Constraints conflict!");
      end
    end
    
    $finish;
  end
endmodule