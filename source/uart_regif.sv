module uart_regif
  import uart_regif_pkg::*;
#(
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int WSTRB_WIDTH = DATA_WIDTH / 8
)(
    input  logic clk_i,
    input  logic rst_ni,

    // ---------------- Flat memory request (from bridge/converter) ----------
    input  logic                    mem_valid_i,
    input  logic                    mem_write_i,
    input  logic [ADDR_WIDTH-1:0]   mem_addr_i,
    input  logic [DATA_WIDTH-1:0]   mem_wdata_i,
    input  logic [WSTRB_WIDTH-1:0]  mem_wstrb_i,

    output logic                    mem_ready_o,
    output logic [DATA_WIDTH-1:0]   mem_rdata_o,
    output logic                    mem_error_o,

    input logic [9:0] tx_fifo_count,
    input logic [9:0] rx_fifo_count,

    input logic tx_busy,
    input logic rx_busy,

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
    logic [31:0]  read_data;
    logic         addr_invalid;

    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(!rst_ni)
        begin
            ctrl_o <= CTRL_RST;
            cfg_o  <= CFG_RST;
            intr_o <= INTR_RST;
        end
        else
        begin
            if(mem_valid_i && mem_write_i)
            begin
                case(mem_addr_i)
                    ADDR_CTRL:  ctrl_o <= uart_ctrl_t'(mem_wdata_i);
                    ADDR_CFG:   cfg_o  <= uart_cfg_t'(mem_wdata_i);
                    ADDR_INTR:  intr_o <= uart_intr_t'(mem_wdata_i);
                    default:    ;
                endcase
            end
        end
    end

    always @*
    begin
        tx_data_valid_o = 1'b0;
        tx_data_o       = 8'h00;
        if(mem_valid_i &&
           mem_write_i &&
           mem_addr_i == ADDR_TXD)
        begin
            tx_data_valid_o = 1'b1;
            tx_data_o       = mem_wdata_i[7:0];
        end
    end

    always @*
    begin
        rx_data_ready_o = 1'b0;
        if(mem_valid_i &&
           !mem_write_i &&
           mem_addr_i == ADDR_RXD)
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
        read_data = 32'h0;
        case(mem_addr_i)
            ADDR_CTRL:   read_data = ctrl_o;
            ADDR_CFG:    read_data = cfg_o;
            ADDR_STATUS: read_data = status;
            ADDR_RXD:    read_data[7:0] = rx_data_i;
            ADDR_INTR:   read_data = intr_o;
            default:     read_data = 32'h0;
        endcase
    end

    always @*
    begin
        case(mem_addr_i)
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
        mem_ready_o = mem_valid_i;
        mem_rdata_o = read_data;
        mem_error_o = mem_valid_i && addr_invalid;
    end

endmodule : uart_regif
