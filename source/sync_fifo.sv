`timescale 1ns/1ps

module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 4,
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH)
) (
    input  logic                    clk_i,
    input  logic                    arst_ni,

    input  logic [DATA_WIDTH-1:0]   data_in_i,
    input  logic                    data_in_valid_i,
    output logic                    data_in_ready_o,

    output logic [DATA_WIDTH-1:0]   data_out_o,
    output logic                    data_out_valid_o,
    input  logic                    data_out_ready_i,

    output logic [ADDR_WIDTH:0]     count_o
);

    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    logic [ADDR_WIDTH-1:0] WP;
    logic [ADDR_WIDTH-1:0] RP;
    logic [ADDR_WIDTH:0]   count;

    wire write_fire = data_in_valid_i && data_in_ready_o;
    wire read_fire  = data_out_valid_o && data_out_ready_i;

    assign data_in_ready_o  = (count < FIFO_DEPTH);
    assign data_out_valid_o = (count > 0);
    assign count_o          = count;

    assign data_out_o       = mem[RP];

    always_ff @(posedge clk_i or negedge arst_ni) begin
        if (!arst_ni) begin
            WP    <= '0;
            RP    <= '0;
            count <= '0;
        end else begin
            if (write_fire) begin
                mem[WP] <= data_in_i;
                WP      <= (WP == FIFO_DEPTH - 1) ? '0 : WP + 1'b1;
            end

            if (read_fire) begin
                RP      <= (RP == FIFO_DEPTH - 1) ? '0 : RP + 1'b1;
            end

            case ({write_fire, read_fire})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default count <= count;
            endcase
                
        end
    end

endmodule