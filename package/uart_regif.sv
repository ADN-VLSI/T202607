package uart_regif_pkg;

    // ---------------- Register byte-address offsets ----------------
    localparam logic [7:0] ADDR_CTRL   = 8'h00;
    localparam logic [7:0] ADDR_CFG    = 8'h04;
    localparam logic [7:0] ADDR_STATUS = 8'h08;
    localparam logic [7:0] ADDR_TXD    = 8'h0C;
    localparam logic [7:0] ADDR_RXD    = 8'h10;
    localparam logic [7:0] ADDR_INTR   = 8'h14;

    // ---------------- UART_CTRL (0x00) : RW ----------------
    typedef struct packed {
        logic [27:0] reserved;   // [31:4]
        logic        rx_flush;   // [3]  (pulse: write 1 to flush)
        logic        tx_flush;   // [2]  (pulse: write 1 to flush)
        logic        rx_en;      // [1]
        logic        tx_en;      // [0]
    } uart_ctrl_t;

    // ---------------- UART_CFG (0x04) : RW ----------------
    typedef struct packed {
        logic [10:0] reserved;      // [31:21]
        logic        extra_stop;    // [20]
        logic        parity_type;   // [19]
        logic        parity_en;     // [18]
        logic [1:0]  num_bits;      // [17:16]
        logic [15:0] baud_div;      // [15:0]
    } uart_cfg_t;

    // ---------------- UART_STATUS (0x08) : RO ----------------
    typedef struct packed {
        logic [9:0] reserved;        // [31:22]
        logic       rx_busy;         // [21]
        logic       tx_busy;         // [20]
        logic [9:0] rx_fifo_count;   // [19:10]
        logic [9:0] tx_fifo_count;   // [9:0]
    } uart_status_t;

    // ---------------- UART_INTR (0x14) : RW ----------------
    typedef struct packed {
        logic [27:0] reserved;   // [31:4]
        logic        rx_empty;   // [3]
        logic        tx_empty;   // [2]
        logic        rx_full;    // [1]
        logic        tx_full;    // [0]
    } uart_intr_t;

    // ---------------- Reset values ----------------
    localparam uart_ctrl_t CTRL_RST = '{
        reserved : '0,
        rx_flush : 1'b0,
        tx_flush : 1'b0,
        rx_en    : 1'b0,
        tx_en    : 1'b0
    };

    localparam uart_cfg_t CFG_RST = '{
        reserved    : '0,
        extra_stop  : 1'b0,
        parity_type : 1'b0,
        parity_en   : 1'b0,
        num_bits    : 2'd3,
        baud_div    : 16'h28B0
    };

    localparam uart_intr_t INTR_RST = '{
        reserved  : '0,
        rx_empty  : 1'b0,
        tx_empty  : 1'b0,
        rx_full   : 1'b0,
        tx_full   : 1'b0
    };

endpackage : uart_regif_pkg
