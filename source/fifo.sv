`timescale 1ns/1ps
module fifo #(
  parameter int ADDR_WIDTH = 3,
  parameter int DATA_WIDTH = 8
)(
  input  logic clk_i,
  input  logic arst_ni, 

  input  logic [DATA_WIDTH-1:0] data_in,
  input  logic data_in_valid_i,
  output logic data_in_ready_o,

  output logic [DATA_WIDTH-1:0] data_out_o,
  output logic data_out_valid_o,
  input logic data_out_ready_i,

  output logic [ADDR_WIDTH:0] count_o 
);

  
  localparam int DEPTH = (2 ** ADDR_WIDTH);

  
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  logic [ADDR_WIDTH:0] wr_ptr;
  logic [ADDR_WIDTH:0] rd_ptr;

  
  logic full;
  logic empty;

  
  logic write_en;
  logic read_en;

  
  assign empty = (wr_ptr == rd_ptr);

 
  assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

  
  
  assign data_in_ready_o = !full;

  
  assign data_out_valid_o = !empty;

  

  
  assign write_en = data_in_valid_i && data_in_ready_o;


  assign read_en = data_out_valid_o && data_out_ready_i;

  
  always_ff @(posedge clk_i or negedge arst_ni) begin

    if (!arst_ni) begin

      
      wr_ptr <= '0;
      rd_ptr <= '0;

      
      count_o <= '0;

      
      data_out_o <= '0;

    end

    else begin

      
      if (write_en) begin

        
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;

        
        wr_ptr <= wr_ptr + 1'b1;

      end

      
      if (read_en) begin

       
        data_out_o <= mem[rd_ptr[ADDR_WIDTH-1:0]];

       
        rd_ptr <= rd_ptr + 1'b1;

      end

      

      if (write_en && !read_en) begin

        count_o <= count_o + 1'b1;

      end

      else if (!write_en && read_en) begin

        count_o <= count_o - 1'b1;

      end

    end

  end

endmodule