`timescale 1ns/1ps

module apb_uart_register_interface
  import uart_regif_pkg::*;
#(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int WSTRB_WIDTH = DATA_WIDTH / 8
)(
    input  logic clk_i,
    input  logic rst_ni,

    // ---------------- APB3/APB4 slave port ----------------
    input  logic                    psel_i,
    input  logic                    penable_i,
    input  logic                    pwrite_i,
    input  logic [ADDR_WIDTH-1:0]   paddr_i,
    input  logic [DATA_WIDTH-1:0]   pwdata_i,
    input  logic [WSTRB_WIDTH-1:0]  pstrb_i,

    output logic                    pready_o,
    output logic [DATA_WIDTH-1:0]   prdata_o,
    output logic                    perror_o,

    // ---------------- UART datapath / status ----------------
    input  logic [9:0] tx_fifo_count,
    input  logic [9:0] rx_fifo_count,

    input  logic tx_busy,
    input  logic rx_busy,

    output logic [7:0] tx_data_o,
    output logic       tx_data_valid_o,
    input  logic       tx_data_ready_i,

    input  logic [7:0] rx_data_i,
    input  logic       rx_data_valid_i,
    output logic       rx_data_ready_o,

    output uart_ctrl_t ctrl_o,
    output uart_cfg_t  cfg_o,
    output uart_intr_t intr_o
);

    // ---------------- Internal memory interface signals (between converter & regif) ----------------
    logic                   mreq;
    logic                   mwe;
    logic [ADDR_WIDTH-1:0]  maddr;
    logic [DATA_WIDTH-1:0]  mwdata;
    logic [WSTRB_WIDTH-1:0] mstrb;

    logic                   mack;
    logic [DATA_WIDTH-1:0]  mrdata;
    logic                   mresp;

    // ---------------- APB -> flat memory interface bridge ----------------
    apb_to_mem_converter #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_apb_to_mem (
        .clk         (clk_i),
        .arst_n      (rst_ni),

        .psel        (psel_i),
        .penable     (penable_i),
        .pwrite      (pwrite_i),
        .paddr       (paddr_i),
        .pwdata      (pwdata_i),
        .pstrb       (pstrb_i),

        .pready      (pready_o),
        .prdata      (prdata_o),
        .pslverr     (perror_o),

        .mreq        (mreq),
        .mwe         (mwe),
        .maddr       (maddr),
        .mwdata      (mwdata),
        .mstrb       (mstrb),

        .mack        (mack),
        .mrdata      (mrdata),
        .mresp       (mresp)
    );

    // ---------------- UART register file ----------------
    uart_regif #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_uart_regif (
        .clk             (clk_i),
        .arst_n          (rst_ni),

        .mreq            (mreq),
        .mwe             (mwe),
        .maddr           (maddr),
        .mwdata          (mwdata),
        .mstrb           (mstrb),

        .mack            (mack),
        .mrdata          (mrdata),
        .mresp           (mresp),

        .tx_fifo_count   (tx_fifo_count),
        .rx_fifo_count   (rx_fifo_count),
        .tx_busy         (tx_busy),
        .rx_busy         (rx_busy),

        .tx_data_o       (tx_data_o),
        .tx_data_valid_o (tx_data_valid_o),
        .tx_data_ready_i (tx_data_ready_i),

        .rx_data_i       (rx_data_i),
        .rx_data_valid_i (rx_data_valid_i),
        .rx_data_ready_o (rx_data_ready_o),

        .ctrl_o          (ctrl_o),
        .cfg_o           (cfg_o),
        .intr_o          (intr_o)
    );

endmodule : apb_uart_register_interface
