`timescale 1ns/1ps

module apb_to_mem_converter #(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int WSTRB_WIDTH = DATA_WIDTH / 8
)(
    // ---------------- Clock & Reset ----------------
    input  logic                      arst_n,
    input  logic                      clk,

    // ---------------- APB slave port ----------------
    input  logic                      psel,
    input  logic                      penable,
    input  logic [ADDR_WIDTH-1:0]     paddr,
    input  logic                      pwrite,
    input  logic [DATA_WIDTH-1:0]     pwdata,
    input  logic [WSTRB_WIDTH-1:0]    pstrb,

    output logic                      pready,
    output logic [DATA_WIDTH-1:0]     prdata,
    output logic                      pslverr,

    // ---------------- Memory interface ----------------
    output logic                      mreq,
    output logic [ADDR_WIDTH-1:0]     maddr,
    output logic                      mwe,
    output logic [DATA_WIDTH-1:0]     mwdata,
    output logic [WSTRB_WIDTH-1:0]    mstrb,

    input  logic                      mack,
    input  logic [DATA_WIDTH-1:0]     mrdata,
    input  logic                      mresp
);

    initial begin
        assert (DATA_WIDTH % 8 == 0)
        else $error("DATA_WIDTH must be a multiple of 8");
    end

    // -------------------------------------------------------------
    // 1. Direct pass-through wires
    // -------------------------------------------------------------
    assign maddr  = paddr;
    assign mwe    = pwrite;
    assign mwdata = pwdata;
    assign mstrb  = pstrb;

    // -------------------------------------------------------------
    // 2. Top Register (penable delay register)
    // -------------------------------------------------------------
    logic penable_q;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            penable_q <= 1'b0;
        end else begin
            penable_q <= penable;
        end
    end

    // -------------------------------------------------------------
    // 3. Top AND gate: mreq = psel & penable & ~penable_q
    // -------------------------------------------------------------
    assign mreq = psel & penable & (~penable_q);

    // -------------------------------------------------------------
    // 4. OR gate: mux_sel = mreq | mack
    // -------------------------------------------------------------
    logic mux_sel;
    assign mux_sel = mreq | mack;

    // -------------------------------------------------------------
    // 5. Bottom 3 Registers (mack, mrdata, mresp registers)
    // -------------------------------------------------------------
    logic                  mack_q;
    logic [DATA_WIDTH-1:0] mrdata_q;
    logic                  mresp_q;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            mack_q   <= 1'b0;
            mrdata_q <= '0;
            mresp_q  <= 1'b0;
        end else begin
            mack_q   <= mack;
            mrdata_q <= mrdata;
            mresp_q  <= mresp;
        end
    end

    // -------------------------------------------------------------
    // 6. 3 Multiplexers for response signals (pready, prdata, pslverr)
    //    sel = 1 -> direct memory inputs (bypass)
    //    sel = 0 -> registered values
    // -------------------------------------------------------------
    assign pready  = mux_sel ? mack   : mack_q;
    assign prdata  = mux_sel ? mrdata : mrdata_q;
    assign pslverr = mux_sel ? mresp  : mresp_q;

endmodule : apb_to_mem_converter