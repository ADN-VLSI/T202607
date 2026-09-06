module apb2mem_conv #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH/8
)(
    input  logic        clk,
    input  logic        arst_n,

    // APB Slave 
    input  logic                  psel,
    input  logic                  penable,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic                  pwrite,
    input  logic [DATA_WIDTH-1:0] pwdata,
    input  logic [STRB_WIDTH-1:0] pstrb,
    output logic                  pready,
    output logic [DATA_WDITH-1:0] prdata,
    output logic                  pslverr,

    // Memory 
    output logic                  mreq,
    output logic [ADDR_WIDTH-1:0] maddr,
    output logic                  mwe,
    output logic [DATA_WIDTH-1:0] mwdata,
    output logic [STRB_WIDTH-1:0] mstrb,
    input  logic                  mack,
    input  logic [DATA_WIDTH-1:0] mrdata,
    input  logic                  mresp
);

    // Direct passthrough assignments
    assign maddr  = paddr;
    assign mwe    = pwrite;
    assign mwdata = pwdata;
    assign mstrb  = pstrb;

    // Request Pulse Logic
    logic req_reg;
    assign mreq = psel && penable && (!req_reg);

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) req_reg <= 1'b0;
        else         req_reg <= penable;
    end

    // Output Registers and Multiplexers
    logic ready_reg, err_reg;
    logic [DATA_WIDTH-1:0] rdata_reg;
    
    logic hold_en;
    assign hold_en = mreq | mack;

    // Multiplexer outputs
    assign pready  = hold_en ? mack   : ready_reg;
    assign prdata  = hold_en ? mrdata : rdata_reg;
    assign pslverr = hold_en ? mresp  : err_reg;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            ready_reg <= 1'b0;
            rdata_reg <= '0;
            err_reg   <= 1'b0;
        end else begin
            ready_reg <= mack;
            rdata_reg <= mrdata;
            err_reg   <= mresp;
        end
    end

endmodule