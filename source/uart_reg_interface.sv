module uart_reg_interface #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32
)(
    input  logic                  clk_i,
    input  logic                  rst_ni,

    // Flat Memory Bus (From Converter)
    input  logic                  mreq,
    input  logic                  mwe,
    input  logic [ADDR_WIDTH-1:0] maddr,
    input  logic [DATA_WIDTH-1:0] mwdata,
    output logic                  mack,
    output logic [DATA_WIDTH-1:0] mrdata,
    output logic                  mresp,

    // UART Config & Control
    output logic        tx_en,
    output logic        rx_en,
    output logic [15:0] baud_div,
    output logic [1:0]  num_bits,
    output logic        parity_en,
    output logic        parity_type,
    output logic        extra_stop,

    // Status inputs
    input  logic        tx_busy,
    input  logic        rx_busy,
    input  logic [9:0]  tx_fifo_count,
    input  logic [9:0]  rx_fifo_count,

    // CDC TX FIFO Interface
    output logic [7:0]  tx_data_o,
    output logic        tx_push_o,
    input  logic        tx_ready_i,

    // CDC RX FIFO Interface
    input  logic [7:0]  rx_data_i,
    output logic        rx_pop_o,
    input  logic        rx_valid_i
);
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_CFG    = 8'h04;
    localparam ADDR_STATUS = 8'h08;
    localparam ADDR_TXD    = 8'h0C;
    localparam ADDR_RXD    = 8'h10;

    logic write_en, read_en;
    assign write_en = mreq && mwe;
    assign read_en  = mreq && !mwe;

    // Sequential: Register Writes
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_en <= 0; rx_en <= 0;
            baud_div <= 16'h28B0;
            num_bits <= 2'd3;
            parity_en <= 0; parity_type <= 0; extra_stop <= 0;
        end else if (write_en && !mack) begin
            if (maddr[7:0] == ADDR_CTRL) begin
                tx_en <= mwdata[0];
                rx_en <= mwdata[1];
            end else if (maddr[7:0] == ADDR_CFG) begin
                baud_div    <= mwdata[15:0];
                num_bits    <= mwdata[17:16];
                parity_en   <= mwdata[18];
                parity_type <= mwdata[19];
                extra_stop  <= mwdata[20];
            end
        end
    end

    // FIFO Push/Pop Logic
    assign tx_data_o = mwdata[7:0];
    assign tx_push_o = write_en && (maddr[7:0] == ADDR_TXD) && !mack && tx_ready_i;
    assign rx_pop_o  = read_en  && (maddr[7:0] == ADDR_RXD) && !mack && rx_valid_i;

    // Combinational: Register Reads & Response
    always_comb begin
        mack   = 1'b0;
        mrdata = 32'd0;
        mresp  = 1'b0;
        
        if (mreq) begin
            mack = 1'b1; 
            if (read_en) begin
                case (maddr[7:0])
                    ADDR_CTRL:   mrdata = {30'd0, rx_en, tx_en};
                    ADDR_CFG:    mrdata = {11'd0, extra_stop, parity_type, parity_en, num_bits, baud_div};
                    ADDR_STATUS: mrdata = {10'd0, rx_busy, tx_busy, rx_fifo_count, tx_fifo_count};
                    ADDR_RXD:    mrdata = {24'd0, rx_data_i};
                    default:     mresp  = 1'b1;
                endcase
            end else if (write_en) begin
                if (maddr[7:0] != ADDR_CTRL && maddr[7:0] != ADDR_CFG && maddr[7:0] != ADDR_TXD) begin
                    mresp = 1'b1;
                end
            end
        end
    end
endmodule