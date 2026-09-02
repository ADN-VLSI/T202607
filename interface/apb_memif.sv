module apb_memif #(
    parameter int ADDR_WIDTH = 2,
    parameter int DATA_WIDTH = 1
) (   
        // --- APB slave port: inputs (from APB master) ---
    input  logic                    arst_n, clk,
    input  logic                    psel, penable, pwrite,
    input  logic [ADDR_WIDTH-1:0]   paddr,
    input  logic [DATA_WIDTH-1:0]   pwdata,
    input  logic [DATA_WIDTH/8-1:0] pstrb,

    // --- APB slave port: outputs (back to APB master) ---
    output logic                    pready, pslverr,
    output logic [DATA_WIDTH-1:0]   prdata,

    // --- Memory-side port: outputs (to memory/peripheral) ---
    output logic                    mreq, mwe,
    output logic [ADDR_WIDTH-1:0]   maddr,
    output logic [DATA_WIDTH-1:0]   mwdata,
    output logic [DATA_WIDTH/8-1:0] mstrb,

    // --- Memory-side port: inputs (from memory/peripheral) ---
    input  logic                    mack, mresp,
    input  logic [DATA_WIDTH-1:0]   mrdata
);

    

endmodule