// 1. Define the Configuration Class
// ==========================================
class ClockConfig;
  // Fixed parameters
  real in_freq = 100.0; // Input frequency in MHz

  // Configurable variables
  rand int ref_div;
  rand int fb_div;

  // Limits
  rand real ou_freq;

  // Constraint rules
  constraint clk_constraints {
    ref_div inside {[1 : 15]};
    fb_div  inside {[16 : 511]};

    ou_freq >= 16.0;
    ou_freq <= 5000.0;

    // Mathematical Equation
    ou_freq == (in_freq * fb_div) / ref_div;
  }

  function void display();
    $display("====== Clock Generation Summary ======");
    $display(" Fixed Input Freq : %0.1f MHz", in_freq);
    $display(" Config Ref Div   : %0d", ref_div);
    $display(" Config FB Div    : %0d", fb_div);
    $display(" Solved Out Freq  : %0.4f MHz", ou_freq);
    $display("======================================");
  endfunction
endclass


// ==========================================
// 2. Define the Testbench Module
// ==========================================
module tb_top;
  initial begin
    ClockConfig cfg = new();
    
    $display("Starting Randomization Tests...");
    
    repeat(5) begin // Try generating 5 different combinations
      if (cfg.randomize()) begin
        cfg.display();
      end else begin
        $error("Solver Error: The math equation conflicts with the bounds.");
      end
    end
    
    $finish;
  end
endmodule