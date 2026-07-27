module apb_mem #(
    parameter int ADDR_WIDTH = 5,
    parameter int DATA_WIDTH = 32
) (
    input logic presetn,
    input logic pclk,

    input logic                  psel,
    input logic                  penable,
    input logic [ADDR_WIDTH-1:0] paddr,
    input logic                  pwrite,
    input logic [DATA_WIDTH-1:0] pwdata,

    input logic                  pready,
    input logic [DATA_WIDTH-1:0] prdata
);

  typedef enum logic [1:0] {
    IDLE,
    SETUP,
    WAIT,
    ACCESS
  } state_t;

  localparam int drop_bits = $clog2(DATA_WIDTH / 8);

  logic [DATA_WIDTH-1:0] mem[2**(ADDR_WIDTH-drop_bits)];

  state_t state, next_state;

  always_comb begin
    next_state = state;
    case (state)

      IDLE: begin
        if (psel & ~penable) begin
          next_state = SETUP;
        end
      end

      SETUP: begin
        if (psel & penable) begin
          next_state = pready ? ACCESS : WAIT;
        end
      end

      WAIT: begin
        if (psel & penable & pready) begin
          next_state = ACCESS;
        end
      end

      ACCESS: begin
        if (~psel) begin
          next_state = IDLE;
        end else if (psel & ~penable) begin
          next_state = SETUP;
        end
      end

    endcase

  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  always_ff @(posedge pclk) begin
    if (state == SETUP && next_state != SETUP) begin
      if (pwrite) begin
        mem[paddr[ADDR_WIDTH-1:drop_bits]] <= pwdata;
      end
    end
  end

  always_comb prdata = mem[paddr[ADDR_WIDTH-1:drop_bits]];
  always_comb pready = '1;

endmodule
