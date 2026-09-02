`timescale 1ns/1ps

module apb_uart_top
  import uart_regif_pkg::*;
#(
    parameter int ADDR_WIDTH   = 32,
    parameter int DATA_WIDTH   = 32,
    parameter int WSTRB_WIDTH  = DATA_WIDTH / 8,
    parameter int FIFO_DEPTH_W = 9
)(
    // ============================================================
    // System Clock and Reset
    // ============================================================
    input  logic                     clk_i,
    input  logic                     arst_ni,

    // ============================================================
    // APB Interface
    // ============================================================
    input  logic                     psel_i,
    input  logic                     penable_i,
    input  logic                     pwrite_i,
    input  logic [ADDR_WIDTH-1:0]    paddr_i,
    input  logic [DATA_WIDTH-1:0]    pwdata_i,
    input  logic [WSTRB_WIDTH-1:0]   pstrb_i,

    output logic                     pready_o,
    output logic [DATA_WIDTH-1:0]    prdata_o,
    output logic                     perror_o,

    // ============================================================
    // UART Pins
    // ============================================================
    output logic                     tx_o,
    input  logic                     rx_i,

    // ============================================================
    // Interrupt
    // ============================================================
    output logic                     intr_o
);


    // ============================================================
    // 1. APB Converter <-> UART Register Interface
    // ============================================================

    logic                     mreq;
    logic                     mwe;
    logic [ADDR_WIDTH-1:0]    maddr;
    logic [DATA_WIDTH-1:0]    mwdata;
    logic [WSTRB_WIDTH-1:0]   mstrb;

    logic                     mack;
    logic [DATA_WIDTH-1:0]    mrdata;
    logic                     mresp;


    // ============================================================
    // 2. UART Configuration / Control / Interrupt
    // ============================================================

    uart_ctrl_t ctrl;
    uart_cfg_t  cfg;
    uart_intr_t intr;

    assign intr_o = |intr;


    // ============================================================
    // 3. Baud Clocks
    // ============================================================

    logic clk_div_8x;
    logic clk_div_1x;

    logic [15:0] baud_div_8x;

    /*
     * Note on dual_edge_reg clock divider behavior:
     * clk_div uses dual_edge_reg, which updates on BOTH clock edges (0->1 and 1->0).
     *
     * As a result, counting 'div_i' edges takes div_i * (T_in / 2).
     * Toggling every 'div_i' edges gives:
     *   T_out = 2 * (div_i * T_in / 2) = div_i * T_in  ==>  f_out = f_in / div_i.
     *
     * 1. 8x oversampled clock (f_8x = f_sys / (baud_div / 8)):
     *    div_i = baud_div / 8 = cfg.baud_div >> 3
     *
     * 2. 1x baud clock from 8x clock (f_1x = f_8x / 8):
     *    div_i = 8 (4'd8)
     */
    assign baud_div_8x =
        ((cfg.baud_div >> 3) == 0)
        ? 16'd1
        : (cfg.baud_div >> 3);


    // ------------------------------------------------------------
    // System clock -> 8x UART clock
    // ------------------------------------------------------------

    clk_div #(
        .DIV_WIDTH(16)
    ) u_clk_div_8x (
        .arst_ni (arst_ni),
        .clk_i   (clk_i),
        .div_i   (baud_div_8x),
        .clk_o   (clk_div_8x)
    );


    // ------------------------------------------------------------
    // 8x clock -> 1x baud clock
    // ------------------------------------------------------------

    clk_div #(
        .DIV_WIDTH(4)
    ) u_clk_div_1x (
        .arst_ni (arst_ni),
        .clk_i   (clk_div_8x),
        .div_i   (4'd8),
        .clk_o   (clk_div_1x)
    );


    // ============================================================
    // 4. TX SIGNALS
    // ============================================================

    // uart_regif -> TX FIFO
    logic [7:0] tx_reg_data;
    logic       tx_reg_valid;
    logic       tx_reg_ready;

    // TX FIFO -> uart_transmitter
    logic [7:0] tx_fifo_data;
    logic       tx_fifo_valid;
    logic       tx_fifo_ready;

    logic [FIFO_DEPTH_W:0] tx_fifo_count;


    // ============================================================
    // 5. TX CDC FIFO
    //
    // uart_regif
    //   clk_i
    //     |
    //     v
    // TX CDC FIFO
    //     |
    //     v
    // uart_transmitter
    // clk_div_1x
    // ============================================================

    cdc_fifo #(
        .DATA_WIDTH  (8),
        .FIFO_SIZE   (FIFO_DEPTH_W),
        .SYNC_STAGES (2)
    ) u_cdc_tx_fifo (

        // ---------------- WRITE DOMAIN ----------------
        // System clock / uart_regif side

        .data_in_clk_i    (clk_i),
        .data_in_arst_ni  (arst_ni),

        .data_in_i        (tx_reg_data),
        .data_in_valid_i  (tx_reg_valid && ctrl.tx_en),
        .data_in_ready_o  (tx_reg_ready),

        .data_in_count_o  (tx_fifo_count),


        // ---------------- READ DOMAIN -----------------
        // 1x baud clock / transmitter side

        .data_out_clk_i   (clk_div_1x),
        .data_out_arst_ni (arst_ni),

        .data_out_o       (tx_fifo_data),
        .data_out_valid_o (tx_fifo_valid),
        .data_out_ready_i (tx_fifo_ready),

        .data_out_count_o ()
    );


    // ============================================================
    // 6. UART TRANSMITTER
    // ============================================================

    uart_transmitter u_uart_tx (

        .arst_ni       (arst_ni),
        .clk_i         (clk_div_1x),

        .data_i        (tx_fifo_data),

        .num_bits_i    (cfg.num_bits),
        .parity_en_i   (cfg.parity_en),
        .parity_type_i (cfg.parity_type),
        .extra_stop_i  (cfg.extra_stop),

        .data_valid_i  (tx_fifo_valid && ctrl.tx_en),
        .data_ready_o  (tx_fifo_ready),

        .tx_o          (tx_o)
    );


    // ============================================================
    // 7. RX SIGNALS
    // ============================================================

    // uart_receiver -> RX FIFO
    logic [7:0] rx_uart_data;
    logic       rx_uart_valid;

    // RX FIFO -> uart_regif
    logic [7:0] rx_reg_data;
    logic       rx_reg_valid;
    logic       rx_reg_ready;

    logic [FIFO_DEPTH_W:0] rx_fifo_count;


    // ============================================================
    // 8. UART RECEIVER
    //
    // rx_i
    //   |
    //   v
    // uart_receiver
    //   |
    //   v
    // rx_uart_data
    // ============================================================

    uart_receiver #(
        .OVERSAMPLE(8)
    ) u_uart_rx (

        .arst_ni       (arst_ni),
        .clk_i         (clk_div_8x),

        .num_bits_i    (cfg.num_bits),
        .parity_en_i   (cfg.parity_en),
        .parity_type_i (cfg.parity_type),

        // Your receiver module calls this INPUT "rx_o"
        .rx_o          (rx_i),

        .data_o        (rx_uart_data),
        .data_valid_o  (rx_uart_valid)
    );


    // ============================================================
    // 9. RX CDC FIFO
    //
    // uart_receiver
    // clk_div_8x
    //      |
    //      v
    // RX CDC FIFO
    //      |
    //      v
    // uart_regif
    // clk_i
    // ============================================================

    cdc_fifo #(
        .DATA_WIDTH  (8),
        .FIFO_SIZE   (FIFO_DEPTH_W),
        .SYNC_STAGES (2)
    ) u_cdc_rx_fifo (

        // ---------------- WRITE DOMAIN ----------------
        // Receiver / 8x clock side

        .data_in_clk_i    (clk_div_8x),
        .data_in_arst_ni  (arst_ni),

        .data_in_i        (rx_uart_data),
        .data_in_valid_i  (rx_uart_valid && ctrl.rx_en),

        .data_in_ready_o  (),
        .data_in_count_o  (),


        // ---------------- READ DOMAIN -----------------
        // uart_regif / system clock side

        .data_out_clk_i   (clk_i),
        .data_out_arst_ni (arst_ni),

        .data_out_o       (rx_reg_data),
        .data_out_valid_o (rx_reg_valid),
        .data_out_ready_i (rx_reg_ready),

        .data_out_count_o (rx_fifo_count)
    );


    // ============================================================
    // 10. APB -> MEMORY BUS CONVERTER
    // ============================================================

    apb_to_mem_converter #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_apb_to_mem_converter (

        .arst_n  (arst_ni),
        .clk     (clk_i),

        // ---------------- APB SIDE ----------------

        .psel    (psel_i),
        .penable (penable_i),
        .paddr   (paddr_i),
        .pwrite  (pwrite_i),
        .pwdata  (pwdata_i),
        .pstrb   (pstrb_i),

        .pready  (pready_o),
        .prdata  (prdata_o),
        .pslverr (perror_o),


        // ------------- INTERNAL MEMORY BUS -----------

        .mreq    (mreq),
        .maddr   (maddr),
        .mwe     (mwe),
        .mwdata  (mwdata),
        .mstrb   (mstrb),

        .mack    (mack),
        .mrdata  (mrdata),
        .mresp   (mresp)
    );


    // ============================================================
    // 11. UART STATUS
    // ============================================================

    logic tx_busy;
    logic rx_busy;

    assign tx_busy = (tx_fifo_count != 0);
    assign rx_busy = (rx_fifo_count != 0);


    // ============================================================
    // 12. UART REGISTER INTERFACE
    // ============================================================

    uart_regif #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WSTRB_WIDTH (WSTRB_WIDTH)
    ) u_uart_regif (

        .arst_n          (arst_ni),
        .clk             (clk_i),


        // ---------------- MEMORY BUS ----------------

        .mreq            (mreq),
        .mwe             (mwe),
        .maddr           (maddr),
        .mwdata          (mwdata),
        .mstrb           (mstrb),

        .mack            (mack),
        .mrdata          (mrdata),
        .mresp           (mresp),


        // ---------------- FIFO STATUS ---------------

        .tx_fifo_count   (tx_fifo_count[9:0]),
        .rx_fifo_count   (rx_fifo_count[9:0]),

        .tx_busy         (tx_busy),
        .rx_busy         (rx_busy),


        // ---------------- TX ------------------------

        .tx_data_o       (tx_reg_data),
        .tx_data_valid_o (tx_reg_valid),
        .tx_data_ready_i (tx_reg_ready),


        // ---------------- RX ------------------------

        .rx_data_i       (rx_reg_data),
        .rx_data_valid_i (rx_reg_valid),
        .rx_data_ready_o (rx_reg_ready),


        // -------- CONTROL / CONFIG / INTERRUPT ------

        .ctrl_o          (ctrl),
        .cfg_o           (cfg),
        .intr_o          (intr)
    );


endmodule : apb_uart_top