`timescale 1ns/1ps

import mem_if_pkg::*;
import uart_regif_pkg::*;

module apb_uart_top #(
    parameter int ADDR_WIDTH   = 32,
    parameter int DATA_WIDTH   = 32,
    parameter int WSTRB_WIDTH  = DATA_WIDTH / 8,
    parameter int FIFO_DEPTH_W = 9
)(
    input  logic                      clk_i,      
    input  logic                      arst_ni,    
    input  logic                      psel_i,
    input  logic                      penable_i,
    input  logic                      pwrite_i,
    input  logic [ADDR_WIDTH-1:0]     paddr_i,
    input  logic [DATA_WIDTH-1:0]     pwdata_i,
    input  logic [WSTRB_WIDTH-1:0]    pstrb_i,
    output logic                      pready_o,
    output logic [DATA_WIDTH-1:0]     prdata_o,
    output logic                      perror_o,
    output logic                      tx_o,       
    input  logic                      rx_i,       
    output logic                      intr_o
);

    logic                   mreq, mwe, mack, mresp;
    logic [ADDR_WIDTH-1:0]  maddr;
    logic [DATA_WIDTH-1:0]  mwdata, mrdata;
    logic [WSTRB_WIDTH-1:0] mstrb;

    mem_req_t     reg_req;
    mem_resp_t    reg_resp;
    uart_ctrl_t   ctrl;
    uart_cfg_t    cfg;
    uart_intr_t   intr;
    uart_status_t status;

    assign intr_o = |intr; 
    assign reg_req.valid = mreq;
    assign reg_req.write = mwe;
    assign reg_req.addr  = maddr[7:0]; 
    assign reg_req.wdata = mwdata;
    assign reg_req.strb  = mstrb[0];
    assign mack   = reg_resp.ready;
    assign mrdata = reg_resp.rdata;
    assign mresp  = reg_resp.error;

    apb_to_mem_converter #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .WSTRB_WIDTH(WSTRB_WIDTH)
    ) u_apb_to_mem (
        .clk(clk_i), .arst_n(arst_ni),
        .psel(psel_i), .penable(penable_i), .pwrite(pwrite_i),
        .paddr(paddr_i), .pwdata(pwdata_i), .pstrb(pstrb_i),
        .pready(pready_o), .prdata(prdata_o), .pslverr(perror_o),
        .mreq(mreq), .mwe(mwe), .maddr(maddr), .mwdata(mwdata), .mstrb(mstrb),
        .mack(mack), .mrdata(mrdata), .mresp(mresp)
    );

    logic [7:0] tx_reg_data, rx_reg_data;
    logic       tx_push, rx_pop;
    
    apb_uart_reg_interface u_uart_regif (
        .clk_i(clk_i), .rst_ni(arst_ni),
        .req_i(reg_req),   .resp_o(reg_resp),
        .ctrl_o(ctrl),     .cfg_o(cfg),       
        .intr_o(intr),     .status_i(status),
        .tx_data_o(tx_reg_data), .tx_push_o(tx_push),
        .rx_data_i(rx_reg_data), .rx_pop_o(rx_pop)
    );

    // =========================================================
    // BUG FIX: Corrected Clock Divider Math for dual_edge_reg
    // =========================================================
    logic clk_div_8x; 
    logic clk_div_1x; 
    logic [15:0] baud_div_8x;
    
    assign baud_div_8x = (cfg.baud_div >> 3) == 0 ? 16'd1 : (cfg.baud_div >> 3); // Divided by 8 instead of 16

    clk_div #(.DIV_WIDTH(16)) u_clk_div (
        .clk_i(clk_i), .arst_ni(arst_ni), .div_i(baud_div_8x), .clk_o(clk_div_8x)
    );

    clk_div #(.DIV_WIDTH(4)) u_clk_div_8 (
        .clk_i(clk_div_8x), .arst_ni(arst_ni), .div_i(4'd8), .clk_o(clk_div_1x) // div_i set to 8 instead of 4
    );

    logic [7:0] tx_fifo_data;
    logic       tx_valid_to_uart, uart_tx_ready;
    logic [FIFO_DEPTH_W:0] tx_wr_ptr;

    assign status.tx_busy = (tx_wr_ptr != 0);
    assign status.tx_fifo_count = tx_wr_ptr[9:0];

    cdc_fifo #(.DATA_WIDTH(8), .FIFO_SIZE(FIFO_DEPTH_W), .SYNC_STAGES(2)) u_cdc_tx_fifo (
        .data_in_clk_i(clk_i),             .data_in_arst_ni(arst_ni),
        .data_in_i(tx_reg_data),           .data_in_valid_i(tx_push && ctrl.tx_en),
        .data_in_ready_o(),                .data_in_count_o(tx_wr_ptr),
        .data_out_clk_i(clk_div_1x),       .data_out_arst_ni(arst_ni),
        .data_out_o(tx_fifo_data),         .data_out_valid_o(tx_valid_to_uart),
        .data_out_ready_i(uart_tx_ready),  .data_out_count_o()
    );

    uart_transmitter u_uart_tx (
        .clk_i(clk_div_1x),               .arst_ni(arst_ni),
        .data_i(tx_fifo_data),            .data_valid_i(tx_valid_to_uart && ctrl.tx_en),
        .data_ready_o(uart_tx_ready),
        .num_bits_i(cfg.num_bits),        .parity_en_i(cfg.parity_en),
        .parity_type_i(cfg.parity_type),  .extra_stop_i(cfg.extra_stop),
        .tx_o(tx_o)
    );

    logic [7:0] rx_uart_data;
    logic       rx_valid_to_fifo;
    logic [FIFO_DEPTH_W:0] rx_rd_ptr;

    assign status.rx_busy = (rx_rd_ptr != 0);
    assign status.rx_fifo_count = rx_rd_ptr[9:0];
    assign status.reserved = '0;

    uart_receiver #(.OVERSAMPLE(8)) u_uart_rx (
        .clk_i(clk_div_8x),               .arst_ni(arst_ni),
        .rx_o(rx_i), 
        .num_bits_i(cfg.num_bits),        .parity_en_i(cfg.parity_en),
        .parity_type_i(cfg.parity_type),
        .data_o(rx_uart_data),            .data_valid_o(rx_valid_to_fifo)
    );

    cdc_fifo #(.DATA_WIDTH(8), .FIFO_SIZE(FIFO_DEPTH_W), .SYNC_STAGES(2)) u_cdc_rx_fifo (
        .data_in_clk_i(clk_div_8x),        .data_in_arst_ni(arst_ni),
        .data_in_i(rx_uart_data),          .data_in_valid_i(rx_valid_to_fifo && ctrl.rx_en),
        .data_in_ready_o(),                .data_in_count_o(),
        .data_out_clk_i(clk_i),            .data_out_arst_ni(arst_ni),
        .data_out_o(rx_reg_data),          .data_out_valid_o(),
        .data_out_ready_i(rx_pop),         .data_out_count_o(rx_rd_ptr)
    );

endmodule