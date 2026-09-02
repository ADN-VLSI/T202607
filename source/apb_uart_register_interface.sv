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

    // ---------------- Internal flat mem_if signals ----------------
    logic                   mem_valid;
    logic                   mem_write;
    logic [ADDR_WIDTH-1:0]  mem_addr;
    logic [DATA_WIDTH-1:0]  mem_wdata;
    logic [WSTRB_WIDTH-1:0] mem_wstrb;

    logic                   mem_ready;
    logic [DATA_WIDTH-1:0]  mem_rdata;
    logic                   mem_error;

    // ---------------- APB -> flat mem_if bridge ----------------
    apb_to_mem_converter #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_apb_to_mem (
        .psel_i      (psel_i),
        .penable_i   (penable_i),
        .pwrite_i    (pwrite_i),
        .paddr_i     (paddr_i),
        .pwdata_i    (pwdata_i),
        .pstrb_i     (pstrb_i),

        .pready_o    (pready_o),
        .prdata_o    (prdata_o),
        .perror_o    (perror_o),

        .mem_valid_o (mem_valid),
        .mem_write_o (mem_write),
        .mem_addr_o  (mem_addr),
        .mem_wdata_o (mem_wdata),
        .mem_wstrb_o (mem_wstrb),

        .mem_ready_i (mem_ready),
        .mem_rdata_i (mem_rdata),
        .mem_error_i (mem_error)
    );

    // ---------------- UART register file ----------------
    uart_regif #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_uart_regif (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),

        .mem_valid_i     (mem_valid),
        .mem_write_i     (mem_write),
        .mem_addr_i      (mem_addr),
        .mem_wdata_i     (mem_wdata),
        .mem_wstrb_i     (mem_wstrb),

        .mem_ready_o     (mem_ready),
        .mem_rdata_o     (mem_rdata),
        .mem_error_o     (mem_error),

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
