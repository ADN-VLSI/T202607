`timescale 1ns/1ps

module apb_uart_top
  import uart_regif_pkg::*;
#(
    parameter int ADDR_WIDTH   = 32,
    parameter int DATA_WIDTH   = 32,
    parameter int WSTRB_WIDTH  = DATA_WIDTH / 8,
    parameter int FIFO_DEPTH_W = 9 // 512 entries (count width = 10)
)(
    // ---------------- System Clock & Reset ----------------
    input  logic                      clk_i,      // SYSTEM CLK
    input  logic                      arst_ni,    // SYSTEM RSTn (active low)

    // ---------------- APB3 Interface ----------------
    input  logic                      psel_i,
    input  logic                      penable_i,
    input  logic                      pwrite_i,
    input  logic [ADDR_WIDTH-1:0]     paddr_i,
    input  logic [DATA_WIDTH-1:0]     pwdata_i,
    input  logic [WSTRB_WIDTH-1:0]    pstrb_i,

    output logic                      pready_o,
    output logic [DATA_WIDTH-1:0]     prdata_o,
    output logic                      perror_o,

    // ---------------- External UART Pins ----------------
    output logic                      tx_o,       // UART TX
    input  logic                      rx_i,       // UART RX

    // ---------------- Optional Interrupt ----------------
    output logic                      intr_o
);

    // =========================================================================
    // 1. Internal Memory Bus (Converter <-> Register Interface)
    // =========================================================================
    logic                   mreq;
    logic                   mwe;
    logic [ADDR_WIDTH-1:0]  maddr;
    logic [DATA_WIDTH-1:0]  mwdata;
    logic [WSTRB_WIDTH-1:0] mstrb;

    logic                   mack;
    logic [DATA_WIDTH-1:0]  mrdata;
    logic                   mresp;

    // =========================================================================
    // 2. Register File Outputs & Configurations
    // =========================================================================
    uart_ctrl_t ctrl;
    uart_cfg_t  cfg;
    uart_intr_t intr;

    assign intr_o = |intr;

    // =========================================================================
    // 3. Clock Generation (Baud Clocks)
    // =========================================================================
    logic clk_div_8x; // 8x oversampling clock (orange line)
    logic clk_div_1x; // 1x baud rate clock (green line)

    // CLK DIV: Divides System Clock to produce 8x oversampling clock
    // Since toggle divider period = 2 * div, div = (baud_div / 8) / 2 = baud_div / 16
    logic [15:0] baud_div_by_16;
    assign baud_div_by_16 = (cfg.baud_div >> 4) == 0 ? 16'd1 : (cfg.baud_div >> 4);

    clk_div #(
        .DIV_WIDTH(16)
    ) u_clk_div (
        .clk_i   (clk_i),
        .arst_ni (arst_ni),
        .div_i   (baud_div_by_16),
        .clk_o   (clk_div_8x)
    );

    // CLK DIV 8: Divides 8x Clock by 8 (4 cycles high + 4 cycles low) to generate 1x Baud Clock
    clk_div #(
        .DIV_WIDTH(4)
    ) u_clk_div_8 (
        .clk_i   (clk_div_8x),
        .arst_ni (arst_ni),
        .div_i   (4'd4),
        .clk_o   (clk_div_1x)
    );

    // =========================================================================
    // 4. TX Datapath (Regif -> CDC TX FIFO -> UART TX)
    // =========================================================================
    logic [7:0] tx_reg_data;
    logic       tx_reg_valid;
    logic       tx_reg_ready;

    logic [7:0] tx_fifo_data;
    logic       tx_fifo_valid;
    logic       tx_fifo_ready;

    logic [FIFO_DEPTH_W:0] tx_fifo_wr_count;

    // CDC TX FIFO
    cdc_fifo #(
        .DATA_WIDTH  (8),
        .FIFO_SIZE   (FIFO_DEPTH_W),
        .SYNC_STAGES (2)
    ) u_cdc_tx_fifo (
        // Write Domain (System Clock)
        .data_in_clk_i    (clk_i),
        .data_in_arst_ni  (arst_ni),
        .data_in_i        (tx_reg_data),
        .data_in_valid_i  (tx_reg_valid && ctrl.tx_en),
        .data_in_ready_o  (tx_reg_ready),
        .data_in_count_o  (tx_fifo_wr_count),

        // Read Domain (1x Baud Clock)
        .data_out_clk_i   (clk_div_1x),
        .data_out_arst_ni (arst_ni),
        .data_out_o       (tx_fifo_data),
        .data_out_valid_o (tx_fifo_valid),
        .data_out_ready_i (tx_fifo_ready),
        .data_out_count_o ()
    );

    // UART Transmitter (runs on 1x Baud Clock)
    uart_transmitter u_uart_tx (
        .clk_i         (clk_div_1x),
        .arst_ni       (arst_ni),

        .data_i        (tx_fifo_data),
        .data_valid_i  (tx_fifo_valid && ctrl.tx_en),
        .data_ready_o  (tx_fifo_ready),

        .num_bits_i    (cfg.num_bits),
        .parity_en_i   (cfg.parity_en),
        .parity_type_i (cfg.parity_type),
        .extra_stop_i  (cfg.extra_stop),

        .tx_o          (tx_o)
    );

    // =========================================================================
    // 5. RX Datapath (UART RX -> CDC RX FIFO -> Regif)
    // =========================================================================
    logic [7:0] rx_uart_data;
    logic       rx_uart_valid;

    logic [7:0] rx_reg_data;
    logic       rx_reg_valid;
    logic       rx_reg_ready;

    logic [FIFO_DEPTH_W:0] rx_fifo_rd_count;

    // UART Receiver (runs on 8x Oversampling Clock)
    uart_receiver #(
        .OVERSAMPLE(8)
    ) u_uart_rx (
        .clk_i         (clk_div_8x),
        .arst_ni       (arst_ni),

        .rx_o          (rx_i), // Serial input
        .num_bits_i    (cfg.num_bits),
        .parity_en_i   (cfg.parity_en),
        .parity_type_i (cfg.parity_type),

        .data_o        (rx_uart_data),
        .data_valid_o  (rx_uart_valid)
    );

    // CDC RX FIFO
    cdc_fifo #(
        .DATA_WIDTH  (8),
        .FIFO_SIZE   (FIFO_DEPTH_W),
        .SYNC_STAGES (2)
    ) u_cdc_rx_fifo (
        // Write Domain (8x RX Clock)
        .data_in_clk_i    (clk_div_8x),
        .data_in_arst_ni  (arst_ni),
        .data_in_i        (rx_uart_data),
        .data_in_valid_i  (rx_uart_valid && ctrl.rx_en),
        .data_in_ready_o  (),
        .data_in_count_o  (),

        // Read Domain (System Clock)
        .data_out_clk_i   (clk_i),
        .data_out_arst_ni (arst_ni),
        .data_out_o       (rx_reg_data),
        .data_out_valid_o (rx_reg_valid),
        .data_out_ready_i (rx_reg_ready),
        .data_out_count_o (rx_fifo_rd_count)
    );

    // =========================================================================
    // 6. APB-to-MEM Converter
    // =========================================================================
    apb_to_mem_converter #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_apb_to_mem (
        .clk         (clk_i),
        .arst_n      (arst_ni),

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

    // =========================================================================
    // 7. UART Register Interface
    // =========================================================================
    logic tx_busy;
    logic rx_busy;

    assign tx_busy = (tx_fifo_wr_count != 0);
    assign rx_busy = (rx_fifo_rd_count != 0);

    uart_regif #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_uart_regif (
        .clk             (clk_i),
        .arst_n          (arst_ni),

        .mreq            (mreq),
        .mwe             (mwe),
        .maddr           (maddr),
        .mwdata          (mwdata),
        .mstrb           (mstrb),

        .mack            (mack),
        .mrdata          (mrdata),
        .mresp           (mresp),

        .tx_fifo_count   (tx_fifo_wr_count[9:0]),
        .rx_fifo_count   (rx_fifo_rd_count[9:0]),
        .tx_busy         (tx_busy),
        .rx_busy         (rx_busy),

        .tx_data_o       (tx_reg_data),
        .tx_data_valid_o (tx_reg_valid),
        .tx_data_ready_i (tx_reg_ready),

        .rx_data_i       (rx_reg_data),
        .rx_data_valid_i (rx_reg_valid),
        .rx_data_ready_o (rx_reg_ready),

        .ctrl_o          (ctrl),
        .cfg_o           (cfg),
        .intr_o          (intr)
    );

endmodule : apb_uart_top
