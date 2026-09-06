////////////////////////////////////////////////////////////////////////////////////////////////////
//
//    Module      : Clock Divider
//
//    Description : This module divides the input clock frequency by a configurable factor.
//                  The division factor is set by the div_i input. The module supports
//                  asynchronous active-low reset and generates a divided clock output.
//                  See details at document/clk_div.md
//
//    Author      : Motasim Faiyaz
//
//    Date        : February 19, 2026
//
////////////////////////////////////////////////////////////////////////////////////////////////////

module clk_div #(
    parameter int DIV_WIDTH = 16
) (
    input  logic                 arst_ni,
    input  logic                 clk_i,
    input  logic [DIV_WIDTH-1:0] div_i,
    output logic                 clk_o
);
    logic [DIV_WIDTH-1:0] cnt;
    logic [DIV_WIDTH-1:0] div;
    
    // Original code counted half-cycles. We divide by 2 to count full-cycles 
    // while keeping the exact same baud rate calculation from the Top module.
    assign div = (div_i <= 1) ? 1 : (div_i >> 1);

    always_ff @(posedge clk_i or negedge arst_ni) begin
        if (!arst_ni) begin
            cnt   <= 0;
            clk_o <= 0;
        end else begin
            if (cnt >= div - 1) begin
                cnt   <= 0;
                clk_o <= ~clk_o;
            end else begin
                cnt   <= cnt + 1;
            end
        end
    end
endmodule
