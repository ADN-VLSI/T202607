module apb_mem #(
    parameter int ADDR_WIDTH = 5,
    parameter int DATA_WIDTH = 32
) (
    input logic preset_ni,
    input logic pclk_i,

    input logic                  psel_i,
    input logic                  penable_i,
    input logic [ADDR_WIDTH-1:0] paddr_i,
    input logic                  pwrite_i,
    input logic [DATA_WIDTH-1:0] pwdata_i,

    output logic                  pready_o,
    output logic [DATA_WIDTH-1:0] prdata_o
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
        if (psel_i & ~penable_i) begin
          next_state = SETUP;
        end
      end

      SETUP: begin
        if (psel_i & penable_i) begin
          next_state = pready_o ? ACCESS : WAIT;
        end
      end

      WAIT: begin
        if (psel_i & penable_i & pready_o) begin
          next_state = ACCESS;
        end
      end

      ACCESS: begin
        if (~psel_i) begin
          next_state = IDLE;
        end else if (psel_i & ~penable_i) begin
          next_state = SETUP;
        end
      end

    endcase

  end

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  always_ff @(posedge pclk_i) begin
    if (state == SETUP && next_state != SETUP) begin
      if (pwrite_i) begin
        mem[paddr_i[ADDR_WIDTH-1:drop_bits]] <= pwdata_i;
      end
    end
  end

  always_comb prdata_o = mem[paddr_i[ADDR_WIDTH-1:drop_bits]];
  always_comb pready_o = '1;

endmodule
