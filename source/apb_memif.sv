module apb_memif (
    input  logic        clk,
    input  logic        arst_n,

    // APB Slave Interface
    input  logic        psel,
    input  logic        penable,
    input  logic [31:0] paddr,
    input  logic        pwrite,
    input  logic [31:0] pwdata,
    input  logic [3:0]  pstrb,
    output logic        pready,
    output logic [31:0] prdata,
    output logic        pslverr,

    // Memory Interface
    output logic        mreq,
    output logic [31:0] maddr,
    output logic        mwe,
    output logic [31:0] mwdata,
    output logic [3:0]  mstrb,
    input  logic        mack,
    input  logic [31:0] mrdata,
    input  logic        mresp
);

    // Direct passthrough assignments
    assign maddr  = paddr;
    assign mwe    = pwrite;
    assign mwdata = pwdata;
    assign mstrb  = pstrb;

    // Request Pulse Logic
    logic req_reg;
    assign mreq = psel && (req_reg) && (!req_reg);

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) req_reg <= 1'b0;
        else         req_reg <= penable;
    end

    // Output Registers and Multiplexers
    logic ready_reg, err_reg;
    logic [31:0] rdata_reg;
    
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