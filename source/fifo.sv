/*
    arst_ni
    clk_i

    data_in_i
    data_in_valid_i
    data_in_ready_o

    data_out_o
    data_out_valid_o
    data_out_ready_i

    count_o
*/

module fifo #(
    parameter int ADDR_WIDTH = 2,
    parameter int DATA_WIDTH = 1
) (
    input  logic                  arst_ni, clk_i, data_in_valid_i, data_out_ready_i, 
    input  logic [DATA_WIDTH-1:0] data_in_i,
    output logic                  data_in_ready_o, data_out_valid_o,
    output logic [DATA_WIDTH-1:0] data_out_o,
    output logic [ADDR_WIDTH:0]   count_o
);

    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];
    logic [ADDR_WIDTH:0] wp, rp, count;

    always_ff @(posedge clk_i or negedge arst_ni) begin
        if (!arst_ni) begin
            wp <= 0;
            rp <= 0;
        end else if (data_in_valid_i && data_in_ready_o) begin 
            mem[wp[ADDR_WIDTH-1:0]] <= data_in_i;
            wp <= wp + 1;
        end else if (data_out_valid_o && data_out_ready_i) begin
            data_out_o <= mem[rp[ADDR_WIDTH-1:0]];
            rp <= rp + 1;
        end
    end

    always_ff @(posedge clk_i or negedge arst_ni) begin
        if (!arst_ni) begin
            count <= 0;
        end else if (data_in_valid_i && data_in_ready_o) begin
            count <= count + 1;
        end else if (data_out_valid_o && data_out_ready_i) begin
            count <= count + 1;        
        end
    end

endmodule