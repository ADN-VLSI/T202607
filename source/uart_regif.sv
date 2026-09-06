module uart_regif
  import uart_regif_pkg::*;
#(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int WSTRB_WIDTH = DATA_WIDTH / 8
)(
    // ---------------- Clock & Reset ----------------
    input  logic                      arst_n,
    input  logic                      clk,

    // ---------------- Memory interface (from converter) ----------------
    input  logic                      mreq,
    input  logic                      mwe,
    input  logic [ADDR_WIDTH-1:0]     maddr,
    input  logic [DATA_WIDTH-1:0]     mwdata,
    input  logic [WSTRB_WIDTH-1:0]    mstrb,

    output logic                      mack,
    output logic [DATA_WIDTH-1:0]     mrdata,
    output logic                      mresp,

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

    uart_status_t status;
    logic [DATA_WIDTH-1:0] read_data;
    logic                  addr_invalid;

    // ---------------- Byte-Strobe Mask Helper ----------------
    function automatic logic [DATA_WIDTH-1:0] apply_wstrb(
        input logic [DATA_WIDTH-1:0] orig_val,
        input logic [DATA_WIDTH-1:0] wr_val,
        input logic [WSTRB_WIDTH-1:0] strb
    );
        logic [DATA_WIDTH-1:0] res;
        for (int i = 0; i < WSTRB_WIDTH; i++) begin
            res[i*8 +: 8] = strb[i] ? wr_val[i*8 +: 8] : orig_val[i*8 +: 8];
        end
        return res;
    endfunction

    always_ff @(posedge clk or negedge arst_n)
    begin
        if(!arst_n)
        begin
            ctrl_o <= CTRL_RST;
            cfg_o  <= CFG_RST;
            intr_o <= INTR_RST;
        end
        else
        begin
            // Flush bits in CTRL register are self-clearing single-cycle pulses
            ctrl_o.tx_flush <= 1'b0;
            ctrl_o.rx_flush <= 1'b0;

            if(mreq && mwe)
            begin
                case(maddr)
                    ADDR_CTRL:  ctrl_o <= uart_ctrl_t'(apply_wstrb(32'(ctrl_o), mwdata, mstrb));
                    ADDR_CFG:   cfg_o  <= uart_cfg_t'(apply_wstrb(32'(cfg_o), mwdata, mstrb));
                    ADDR_INTR:  intr_o <= uart_intr_t'(apply_wstrb(32'(intr_o), mwdata, mstrb));
                    default:    ;
                endcase
            end
        end
    end

    always @*
    begin
        tx_data_valid_o = 1'b0;
        tx_data_o       = 8'h00;
        if(mreq &&
           mwe &&
           maddr == ADDR_TXD)
        begin
            tx_data_valid_o = 1'b1;
            tx_data_o       = mwdata[7:0];
        end
    end

    always @*
    begin
        rx_data_ready_o = 1'b0;
        if(mreq &&
           !mwe &&
           maddr == ADDR_RXD)
        begin
            rx_data_ready_o = 1'b1;
        end
    end

    always @*
    begin
        status = '0;
        status.tx_busy       = tx_busy;
        status.rx_busy       = rx_busy;
        status.tx_fifo_count = tx_fifo_count;
        status.rx_fifo_count = rx_fifo_count;
    end

    always @*
    begin
        read_data = '0;
        case(maddr)
            ADDR_CTRL:   read_data = DATA_WIDTH'(ctrl_o);
            ADDR_CFG:    read_data = DATA_WIDTH'(cfg_o);
            ADDR_STATUS: read_data = DATA_WIDTH'(status);
            ADDR_RXD:    read_data[7:0] = rx_data_i;
            ADDR_INTR:   read_data = DATA_WIDTH'(intr_o);
            default:     read_data = '0;
        endcase
    end

    always @*
    begin
        case(maddr)
            ADDR_CTRL,
            ADDR_CFG,
            ADDR_STATUS,
            ADDR_TXD,
            ADDR_RXD,
            ADDR_INTR: addr_invalid = 1'b0;
            default:   addr_invalid = 1'b1;
        endcase
    end

    always @*
    begin
        mack   = mreq;
        mrdata = read_data;
        mresp  = mreq && addr_invalid;
    end

endmodule : uart_regif