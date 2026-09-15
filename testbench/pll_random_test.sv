class ClockConfig;
  // Express frequencies as integers to satisfy the compiler
  // 100 MHz = 100_000 kHz
  int in_freq_khz = 100000; 

  // Configurable variables 
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

  // 1. Added 'virtual' keyword here to enable polymorphism
    virtual function void display();
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

// 2. Child Class 
class ClockDisplay extends ClockConfig;
  
  virtual function void display();
    real ou_freq_mhz = ou_freq_khz / 1000.0;
    $display("[POLYMORPHIC CUSTOM VIEW] Out Freq: %0.2f MHz (Ref: %0d, FB: %0d)", 
             ou_freq_mhz, ref_div, fb_div);
  endfunction
endclass



// 3. Testbench Module

module pll_random_test;
  initial begin
    // Create the array of 2 base class handles
    automatic ClockConfig cfg_handles[2];
    
    // Allocate the objects directly into the array slots
    cfg_handles[0] = new();              
    cfg_handles[1] = ClockDisplay::new(); 
    
    $display("Starting PLL Simulation... Demonstrating Direct Array Polymorphism:\n");
    
    foreach (cfg_handles[i]) begin
      if (cfg_handles[i].randomize()) begin
        
        cfg_handles[i].display(); 
        $display(""); 
      end else begin
        $error("Solver Error: Constraints conflict!");
      end
    end
    
    $finish;
  end
endmodule
    
