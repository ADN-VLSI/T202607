import mem_if_pkg::*;
import uart_regif_pkg::*;

module apb_uart_reg_interface (
    input  logic clk_i,
    input  logic rst_ni,

    // Bus Interface
    input  mem_req_t  req_i,
    output mem_resp_t resp_o,

    // Hardware Interface
    output uart_ctrl_t  ctrl_o,
    output uart_cfg_t   cfg_o,
    output uart_intr_t  intr_o,
    input  uart_status_t status_i,

    // CDC FIFO Interfaces
    output logic [7:0] tx_data_o,
    output logic       tx_push_o,
    input  logic [7:0] rx_data_i,
    output logic       rx_pop_o
);

    // =========================================================
    // Internal Registers Declaration
    // =========================================================
    uart_ctrl_t ctrl_q;
    uart_cfg_t  cfg_q;
    uart_intr_t intr_q;

    assign ctrl_o = ctrl_q;
    assign cfg_o  = cfg_q;
    assign intr_o = intr_q;

    // =========================================================
    // BLOCK 1: Combinational Address Decoding & Enables
    // =========================================================
    logic write_en;
    logic read_en;
    logic addr_ctrl, addr_cfg, addr_status, addr_txd, addr_rxd, addr_intr;

    assign write_en = req_i.valid && req_i.write;
    assign read_en  = req_i.valid && !req_i.write;

    assign addr_ctrl   = (req_i.addr == 8'h00);
    assign addr_cfg    = (req_i.addr == 8'h04);
    assign addr_status = (req_i.addr == 8'h08);
    assign addr_txd    = (req_i.addr == 8'h0C);
    assign addr_rxd    = (req_i.addr == 8'h10);
    assign addr_intr   = (req_i.addr == 8'h14);

    // FIFO Control Signals
    assign tx_data_o = req_i.wdata[7:0];
    assign tx_push_o = write_en && addr_txd && !resp_o.ready;
    assign rx_pop_o  = read_en  && addr_rxd && !resp_o.ready;

    // =========================================================
    // BLOCK 2: Sequential Logic (Register Updates Only)
    // =========================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_q <= CTRL_RST;
            cfg_q  <= CFG_RST;
            intr_q <= INTR_RST;
        end else begin
            // Pulse Generation: Auto-clear flush bits every clock cycle
            ctrl_q.rx_flush <= 1'b0;
            ctrl_q.tx_flush <= 1'b0;

            // Update registers only on a valid write request
            if (write_en && !resp_o.ready) begin
                if (addr_ctrl) begin
                    ctrl_q.tx_en    <= req_i.wdata[0];
                    ctrl_q.rx_en    <= req_i.wdata[1];
                    ctrl_q.tx_flush <= req_i.wdata[2];
                    ctrl_q.rx_flush <= req_i.wdata[3];
                end
                else if (addr_cfg) begin
                    cfg_q.baud_div    <= req_i.wdata[15:0];
                    cfg_q.num_bits    <= req_i.wdata[17:16];
                    cfg_q.parity_en   <= req_i.wdata[18];
                    cfg_q.parity_type <= req_i.wdata[19];
                    cfg_q.extra_stop  <= req_i.wdata[20];
                end
                else if (addr_intr) begin
                    intr_q.tx_full  <= req_i.wdata[0];
                    intr_q.rx_full  <= req_i.wdata[1];
                    intr_q.tx_empty <= req_i.wdata[2];
                    intr_q.rx_empty <= req_i.wdata[3];
                end
            end
        end
    end

    // =========================================================
    // BLOCK 3: Combinational Read Multiplexer & Bus Response
    // =========================================================
    always_comb begin
        // 1. Default assignments to prevent inferred latches
        resp_o.ready = 1'b0;
        resp_o.rdata = 32'd0;
        resp_o.error = 1'b0;

        if (req_i.valid) begin
            resp_o.ready = 1'b1; // Zero-wait state acknowledgment

            if (read_en) begin
                // Read Operation: Mux data based on address
                if      (addr_ctrl)   resp_o.rdata = {28'd0, ctrl_q.rx_flush, ctrl_q.tx_flush, ctrl_q.rx_en, ctrl_q.tx_en};
                else if (addr_cfg)    resp_o.rdata = {11'd0, cfg_q.extra_stop, cfg_q.parity_type, cfg_q.parity_en, cfg_q.num_bits, cfg_q.baud_div};
                else if (addr_status) resp_o.rdata = {10'd0, status_i.rx_busy, status_i.tx_busy, status_i.rx_fifo_count, status_i.tx_fifo_count};
                else if (addr_rxd)    resp_o.rdata = {24'd0, rx_data_i};
                else if (addr_intr)   resp_o.rdata = {28'd0, intr_q.rx_empty, intr_q.tx_empty, intr_q.rx_full, intr_q.tx_full};
                else                  resp_o.error = 1'b1; // Read from invalid address
            end 
            else if (write_en) begin
                // Write Operation: Check for invalid or read-only addresses
                if (!addr_ctrl && !addr_cfg && !addr_intr && !addr_txd) begin
                    resp_o.error = 1'b1; 
                end
            end
        end
    end

endmodule