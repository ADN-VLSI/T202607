class rand_eg;

     int in_freq = 100;
     rand int ref_div;
     rand int fb_div;
     int ou_freq;

     constraint c_ref_div {
          ref_div inside {[1:15]};
     }

     constraint c_fb_div {
          fb_div inside {[16:511]};
     }

     constraint c_ou_freq {
          (in_freq * fb_div) >= (16 * ref_div);
          (in_freq * fb_div) <= (5000 * ref_div);
     }

     function new();
          this.in_freq = 100;
     endfunction

     virtual function automatic void calculate_ou_freq();
          ou_freq = (in_freq * fb_div) / ref_div;
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
     
     virtual function automatic int get_ou_freq();
          return this.ou_freq;
     endfunction

     /*
     virtual function automatic string to_string();
          return $sformatf("Input frequency: %0d MHz\n
                           Reference divider: %0d\n
                           Feedback divider: %0d\n
                           Output Frequency: %0d MHz", 
                           get_in_freq(), get_ref_div(), get_fb_div(), get_ou_freq());
     endfunction
*/

     virtual function automatic string to_string();
     return $sformatf("Input frequency: %0d MHz\n"   +
                      "Reference divider: %0d\n"   +
                      "Feedback divider: %0d\n"    +
                      "Output Frequency: %0d MHz", 
                      get_in_freq(), get_ref_div(), get_fb_div(), get_ou_freq());
    endfunction

    virtual function automatic void display();
     $display(to_string);
    endfunction

endclass

module test_eg;
     initial begin
          rand_eg example_tb = new();

          repeat(5) begin
               if (example_tb.randomize()) begin
                    example_tb.calculate_out_freq;
                    example_tb.display();
               end
          end
     end
endmodule