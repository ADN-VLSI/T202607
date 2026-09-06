module apb_mem_tb;

  localparam int CHOSEN_ADDR_WIDTH = 16;
  localparam int CHOSEN_DATA_WIDTH = 32;
  localparam int DROP_ADDRESS_BITS = $clog2(CHOSEN_DATA_WIDTH / 8);

  logic presetn;
  logic pclk;

  int   pass_count;
  int   fail_count;

  apb_if #(
      .ADDR_WIDTH(CHOSEN_ADDR_WIDTH),
      .DATA_WIDTH(CHOSEN_DATA_WIDTH)
  ) intf (
      .pclk(pclk),
      .presetn(presetn)
  );

  apb_mem #(
      .ADDR_WIDTH(CHOSEN_ADDR_WIDTH),
      .DATA_WIDTH(CHOSEN_DATA_WIDTH)
  ) u_dut (
      .preset_ni(presetn),
      .pclk_i   (pclk),
      .psel_i   (intf.psel),
      .penable_i(intf.penable),
      .paddr_i  (intf.paddr),
      .pwrite_i (intf.pwrite),
      .pwdata_i (intf.pwdata),
      .pready_o (intf.pready),
      .prdata_o (intf.prdata)
  );

  task automatic apply_reset();
    #100ns;
    pclk    <= 1'b0;
    presetn <= 1'b0;
    intf.apply_reset(1);
    #100ns;
    presetn <= 1'b1;
    #100ns;
  endtask

  task automatic start_clock();
    fork
      forever begin
        #5ns pclk <= 1'b0;
        #5ns pclk <= 1'b1;
      end
    join_none
    repeat (5) @(posedge pclk);
  endtask

  task automatic start_scoreboard();
    logic [CHOSEN_DATA_WIDTH-1:0] ref_mem[longint];
    fork
      forever begin
        logic [CHOSEN_ADDR_WIDTH-1:0] addr;
        logic                         write;
        logic [CHOSEN_DATA_WIDTH-1:0] data;
        intf.get_transaction(addr, write, data);
        addr = addr >> DROP_ADDRESS_BITS;
        if (write) begin
          $display("\033[0;33m mem[0x%08h] << 0x%08h [%0t]\033[0m", addr, data, $realtime);
          ref_mem[addr] = data;
        end else begin
          if (ref_mem[addr] !== data) begin
            $display("\033[0;31m mem[0x%08h] >> 0x%08h  Exp:0x%0h [%0t]\033[0m", addr, data,
                     ref_mem[addr], $realtime);
            fail_count++;
          end else begin
            $display("\033[0;32m mem[0x%08h] >> 0x%08h [%0t]\033[0m", addr, data, $realtime);
            pass_count++;
          end
        end
      end
    join_none
  endtask

  task automatic run_directed_sequence(int len = 100);
    int data;
    intf.write('h0, 'hDEADBEEF);
    intf.write('h4, 'hF00DCAFE);
    intf.write('h8, 'hBADCAB1E);
    intf.write('hC, 'hF0E2F0E2);
    intf.read('h0, data);
    intf.read('h4, data);
    intf.read('h8, data);
    intf.read('hC, data);
  endtask

  task automatic run_random_sequence(int len = 100);
    int addr_pool[$];
    int addr;
    int data;
    repeat (len) begin
      randcase

        3: begin
          addr = $urandom;
          data = $urandom;
          intf.write(addr, data);
          addr_pool.push_back(addr);
        end

        2: begin
          addr = addr_pool[$urandom_range(0, addr_pool.size()-1)];
          intf.read(addr, data);
        end

        1: begin
          addr = addr_pool[$urandom_range(0, addr_pool.size()-1)];
          intf.read($urandom, data);
        end

      endcase
    end
  endtask

  initial begin

    $timeformat(-9, 0, "ns");
    $dumpfile("apb_mem_tb.vcd");
    $dumpvars(0, apb_mem_tb);

    apply_reset();
    start_clock();

    start_scoreboard();

    // run_directed_sequence();
    run_random_sequence(1000);

    #100ns;
    $finish;
  end

  final begin
    $write("%0d/%0d ", pass_count, pass_count + fail_count);
    if (fail_count > 0) begin
      $display("\033[7;31m..TEST FAILED..\033[0m");
    end else begin
      $display("\033[7;32m..TEST PASSED..\033[0m");
    end
  end

endmodule