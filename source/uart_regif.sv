`include "uart_regif_pkg.sv"
`include "mem_if_pkg.sv"

// ---------------------------------------------------------
// Packages must be imported before the module declaration
// ---------------------------------------------------------
import mem_if_pkg::*;
import uart_regif_pkg::*;

module uart_regif (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Bus Interface
    input  mem_req_t    mem_req_i,
    output mem_resp_t   mem_resp_o,

    // Hardware Interface: Status
    input  logic [9:0]  tx_fifo_count,
    input  logic [9:0]  rx_fifo_count,
    input  logic        tx_busy,
    input  logic        rx_busy,

    // TX FIFO Interface
    output logic [7:0]  tx_data_o,
    output logic        tx_data_valid_o,
    input  logic        tx_data_ready_i,

    // RX FIFO Interface
    input  logic [7:0]  rx_data_i,
    input  logic        rx_data_valid_i,
    output logic        rx_data_ready_o,

    // Hardware Interface: Configuration
    output uart_ctrl_t  ctrl_o,
    output uart_cfg_t   cfg_o,
    output uart_intr_t  intr_o
);

    // ---------------------------------------------------------
    // Internal register declarations
    // ---------------------------------------------------------
    uart_ctrl_t   ctrl_reg;
    uart_cfg_t    cfg_reg;
    uart_intr_t   intr_reg;
    uart_status_t status_reg;

    logic [7:0] reg_addr;

    logic addr_ctrl;
    logic addr_cfg;
    logic addr_status;
    logic addr_txd;
    logic addr_rxd;
    logic addr_intr;

    // ---------------------------------------------------------
    // Combinational Logic: Address Decoding
    // ---------------------------------------------------------
    assign reg_addr = mem_req_i.addr[7:0];

    always_comb begin
        addr_ctrl   = (reg_addr == ADDR_CTRL);
        addr_cfg    = (reg_addr == ADDR_CFG);
        addr_status = (reg_addr == ADDR_STATUS);
        addr_txd    = (reg_addr == ADDR_TXD);
        addr_rxd    = (reg_addr == ADDR_RXD);
        addr_intr   = (reg_addr == ADDR_INTR);
    end

    // Status register update
    always_comb begin
        status_reg = '0;
        status_reg.rx_busy       = rx_busy;
        status_reg.tx_busy       = tx_busy;
        status_reg.rx_fifo_count = rx_fifo_count;
        status_reg.tx_fifo_count = tx_fifo_count;
    end

    // ---------------------------------------------------------
    // Combinational Logic: FIFO Handshake
    // ---------------------------------------------------------
    assign tx_data_o = mem_req_i.wdata[7:0];

    assign tx_data_valid_o =
        mem_req_i.valid &&
        mem_req_i.write &&
        addr_txd;

    assign rx_data_ready_o =
        mem_req_i.valid &&
        !mem_req_i.write &&
        addr_rxd &&
        rx_data_valid_i;

    // ---------------------------------------------------------
    // Combinational Logic: Memory Bus Response
    // ---------------------------------------------------------
    always_comb begin
        mem_resp_o.ready = 1'b0;
        mem_resp_o.rdata = 32'h0000_0000;
        mem_resp_o.error = 1'b0;

        if (mem_req_i.valid) begin
            if (addr_ctrl) begin
                mem_resp_o.ready = 1'b1;
                mem_resp_o.rdata = ctrl_reg;
            end
            else if (addr_cfg) begin
                mem_resp_o.ready = 1'b1;
                mem_resp_o.rdata = cfg_reg;
            end
            else if (addr_status) begin
                if (!mem_req_i.write) begin
                    mem_resp_o.ready = 1'b1;
                    mem_resp_o.rdata = status_reg;
                end
                else begin
                    mem_resp_o.ready = 1'b1;
                    mem_resp_o.error = 1'b1;
                end
            end
            else if (addr_txd) begin
                if (mem_req_i.write) begin
                    mem_resp_o.ready = tx_data_ready_i;
                end
                else begin
                    mem_resp_o.ready = 1'b1;
                    mem_resp_o.error = 1'b1;
                end
            end
            else if (addr_rxd) begin
                if (!mem_req_i.write) begin
                    mem_resp_o.ready = rx_data_valid_i;
                    mem_resp_o.rdata = {24'h000000, rx_data_i};
                end
                else begin
                    mem_resp_o.ready = 1'b1;
                    mem_resp_o.error = 1'b1;
                end
            end
            else if (addr_intr) begin
                mem_resp_o.ready = 1'b1;
                mem_resp_o.rdata = intr_reg;
            end
            else begin
                mem_resp_o.ready = 1'b1;
                mem_resp_o.error = 1'b1;
            end
        end
    end

    // ---------------------------------------------------------
    // Sequential Logic: Register Update and Write Operation
    // ---------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_reg <= CTRL_RST;
            cfg_reg  <= CFG_RST;
            intr_reg <= INTR_RST;
        end
        else begin
            // Flush signals automatically clear to 0 (Pulse generation)
            ctrl_reg.tx_flush <= 1'b0;
            ctrl_reg.rx_flush <= 1'b0;

            if (mem_req_i.valid &&
                mem_req_i.write &&
                mem_resp_o.ready &&
                !mem_resp_o.error) begin

                case (reg_addr)
                    ADDR_CTRL: begin
                        if (mem_req_i.strb[0]) begin
                            ctrl_reg.tx_en    <= mem_req_i.wdata[0];
                            ctrl_reg.rx_en    <= mem_req_i.wdata[1];
                            ctrl_reg.tx_flush <= mem_req_i.wdata[2];
                            ctrl_reg.rx_flush <= mem_req_i.wdata[3];
                        end
                    end

                    ADDR_CFG: begin
                        if (mem_req_i.strb[0]) begin
                            cfg_reg.baud_div[7:0] <= mem_req_i.wdata[7:0];
                        end

                        if (mem_req_i.strb[1]) begin
                            cfg_reg.baud_div[15:8] <= mem_req_i.wdata[15:8];
                        end

                        if (mem_req_i.strb[2]) begin
                            cfg_reg.num_bits    <= mem_req_i.wdata[17:16];
                            cfg_reg.parity_en   <= mem_req_i.wdata[18];
                            cfg_reg.parity_type <= mem_req_i.wdata[19];
                            cfg_reg.extra_stop  <= mem_req_i.wdata[20];
                        end
                    end

                    ADDR_INTR: begin
                        if (mem_req_i.strb[0]) begin
                            intr_reg.tx_full  <= mem_req_i.wdata[0];
                            intr_reg.rx_full  <= mem_req_i.wdata[1];
                            intr_reg.tx_empty <= mem_req_i.wdata[2];
                            intr_reg.rx_empty <= mem_req_i.wdata[3];
                        end
                    end

                    default: begin
                        // Invalid address is handled in combinational logic
                    end
                endcase
            end
        end
    end

    // ---------------------------------------------------------
    // Output Assignments
    // ---------------------------------------------------------
    assign ctrl_o = ctrl_reg;
    assign cfg_o  = cfg_reg;
    assign intr_o = intr_reg;

endmodule