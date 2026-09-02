module apb_to_memif#(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    // ----------------------------------------------------
    // APB Interface (Input from APB Master)
    // ----------------------------------------------------
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic                      PWRITE,
    input  logic [ADDR_WIDTH-1:0]     PADDR,
    input  logic [DATA_WIDTH-1:0]     PWDATA,
    input  logic [(DATA_WIDTH/8)-1:0] PSTRB,
    
    output logic                      PREADY,
    output logic [DATA_WIDTH-1:0]     PRDATA,
    output logic                      PERROR,

    // ----------------------------------------------------
    // Memory Interface (Output to Memory/Slave)
    // ----------------------------------------------------
    output logic                      mvalid,
    output logic                      mwrite,
    output logic [ADDR_WIDTH-1:0]     maddr,
    output logic [DATA_WIDTH-1:0]     mwdata,
    output logic [(DATA_WIDTH/8)-1:0] mstrb,

    // ----------------------------------------------------
    // Memory Interface (Input from Memory/Slave)
    // ----------------------------------------------------
    input  logic                      mready,
    input  logic [DATA_WIDTH-1:0]     mrdata,
    input  logic                      merror
);

    // ====================================================
    // 1. Valid Signal Generation (AND Gate Logic)
    // ====================================================
    assign mvalid = PSEL & PENABLE;

    // ====================================================
    // 2. APB to Memory Mapping (Direct Connections)
    // ====================================================
    assign mwrite = PWRITE;
    assign maddr  = PADDR;
    assign mwdata = PWDATA;
    assign mstrb  = PSTRB;

    // ====================================================
    // 3. Memory to APB Mapping (Return Signals)
    // ====================================================
    assign PREADY = mready;
    assign PRDATA = mrdata;
    assign PERROR = merror;

endmodule