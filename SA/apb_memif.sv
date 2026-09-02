module apb_memif (

    input  wire        arst_n,
    input  wire        clk,
    input  wire        psel,
    input  wire        penable,
    input  wire [31:0] paddr,    
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    input  wire [3:0]  pstrb,

    output wire        pready,
    output wire [31:0] prdata,
    output wire        pslverr,

    output wire        mreq,
    output wire [31:0] maddr,
    output wire        mwe,
    output wire [31:0] mwdata,
    output wire [3:0]  mstrb,

    input  wire        mack,
    input  wire [31:0] mrdata,
    input  wire        mresp
);

    reg penable_reg;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            penable_reg <= 1'b0;
        end else begin
            penable_reg <= penable;
        end
    end

    assign mreq = psel && (~penable_reg);

    assign maddr  = paddr;
    assign mwe    = pwrite;
    assign mwdata = pwdata;
    assign mstrb  = pstrb;
   
    reg        pready_reg;
    reg [31:0] prdata_reg;
    reg        pslverr_reg;

    wire mux_sel;
    assign mux_sel = penable || mreq;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            pready_reg <= 1'b0;
        end else begin
            pready_reg <= mux_sel ? mack : pready_reg;
        end
    end
    assign pready = pready_reg;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            prdata_reg <= 32'b0;
        end else begin
            prdata_reg <= mux_sel ? mrdata : prdata_reg;
        end
    end
    assign prdata = prdata_reg;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            pslverr_reg <= 1'b0;
        end else begin
            pslverr_reg <= mux_sel ? mresp : pslverr_reg;
        end
    end
    assign pslverr = pslverr_reg;

endmodule