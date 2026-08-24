interface rv_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic clk_i,
    input logic arst_ni
);
    logic [DATA_WIDTH-1:0] data;
    logic                  valid;
    logic                  ready;

    // Modport for Producer (Master)
    modport master (
        input  clk_i, arst_ni, ready,
        output data, valid
    );

    // Modport for Consumer (Slave)
    modport slave (
        input  clk_i, arst_ni, data, valid,
        output ready
    );

    // Clocking block for testbench synchronization
    clocking cb @(posedge clk_i);
        default input #1ns output #1ns;
        inout data, valid, ready;
    endclocking

endinterface