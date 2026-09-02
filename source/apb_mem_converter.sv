`timescale 1ns/1ps

module apb_to_mem_converter #(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int WSTRB_WIDTH = DATA_WIDTH / 8
)(
    // ---------------- APB3/APB4 slave port ----------------
    input  logic                      psel_i,
    input  logic                      penable_i,
    input  logic                      pwrite_i,
    input  logic [ADDR_WIDTH-1:0]     paddr_i,
    input  logic [DATA_WIDTH-1:0]     pwdata_i,
    input  logic [WSTRB_WIDTH-1:0]    pstrb_i,

    output logic                      pready_o,
    output logic [DATA_WIDTH-1:0]     prdata_o,
    output logic                      perror_o,

    // ---------------- Flat memory request/response (toward regif) -----------
    output logic                      mem_valid_o,
    output logic                      mem_write_o,
    output logic [ADDR_WIDTH-1:0]     mem_addr_o,
    output logic [DATA_WIDTH-1:0]     mem_wdata_o,
    output logic [WSTRB_WIDTH-1:0]    mem_wstrb_o,

    input  logic                      mem_ready_i,
    input  logic [DATA_WIDTH-1:0]     mem_rdata_i,
    input  logic                      mem_error_i
);

    initial begin
        assert (DATA_WIDTH % 8 == 0)
        else $error("DATA_WIDTH must be a multiple of 8");
    end

    always_comb begin
        mem_addr_o  = paddr_i;
        mem_wdata_o = pwdata_i;
        mem_wstrb_o = pstrb_i;
        mem_write_o = pwrite_i;
        mem_valid_o = psel_i & penable_i;

        pready_o = mem_ready_i;
        prdata_o = mem_rdata_i;
        perror_o = mem_error_i;
    end

endmodule : apb_to_mem_converter