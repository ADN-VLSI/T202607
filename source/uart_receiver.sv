module uart_receiver #(
    parameter int OVERSAMPLE = 8
) (
    input logic arst_ni,
    input logic clk_i,

    input logic [1:0] num_bits_i,
    input logic       parity_en_i,
    input logic       parity_type_i,
    input logic       rx_o,

    output logic [7:0] data_o,
    output logic       data_valid_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPE DEFINITIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [2:0] {
    IDLE,    // 0
    START,   // 1
    DATA,    // 2
    PARITY,  // 3
    STOP     // 4
  } tx_state_t;

  tx_state_t state;
  tx_state_t state_next;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [2:0] data_count;
  logic [2:0] data_count_next;

  logic [$clog2(OVERSAMPLE)-1:0] sample_count;
  logic [$clog2(OVERSAMPLE)-1:0] sample_count_next;

  logic parity[4];
  logic parity_bit;

  logic sample_now;

  logic data_valid;
  logic data_valid_next;

  logic [7:0] data_next;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COMBINATIONALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // parity calculation
  always_comb parity[0] = ^data_o[4:0];
  always_comb parity[1] = parity[0] ^ data_o[5];
  always_comb parity[2] = parity[1] ^ data_o[6];
  always_comb parity[3] = parity[2] ^ data_o[7];
  always_comb parity_bit = parity_type_i ? ~parity[3] : parity[3];

  // sample_count
  always_comb begin
    case (state)
      IDLE: sample_count_next = 0;
      default: sample_count_next = sample_count + 1;
    endcase
  end

  // data count next TODO
  always_comb begin
    case (state)
      DATA: data_count_next = data_count + 1;
      default: data_count_next = 0;
    endcase
  end

  always_comb sample_now = (sample_count == (OVERSAMPLE / 2));

  // state next
  always_comb begin

    state_next      = state;
    data_valid_o    = 0;
    data_valid_next = data_valid;
    data_next       = data_o;

    case (state)

      IDLE: begin
        if (!rx_o) state_next = START;
      end

      START: begin
        if (sample_now) begin
          if (!rx_o) state_next = DATA;
          else state_next = IDLE;
        end
      end

      DATA: begin
        if (sample_now) begin
          data_next[data_count] = rx_o;
          if (data_count == (4 + num_bits_i)) begin
            data_valid_next = 1;
            if (parity_en_i) state_next = PARITY;
            else state_next = STOP;
          end
        end
      end

      PARITY: begin
        if (sample_now) begin
          if (rx_o != parity_bit) begin
            data_valid_next = 0;
          end
          state_next = STOP;
        end
      end

      STOP: begin
        if (sample_now) begin
          data_valid_o = data_valid;
          state_next   = IDLE;
        end
      end

    endcase

  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // sample count registers
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      sample_count <= 0;
    end else begin
      sample_count <= sample_count_next;
    end
  end

  // data count registers
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_count <= 0;
    end else if (sample_now) begin
      data_count <= data_count_next;
    end
  end

  // state registers
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      state <= IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_valid <= 0;
    end else begin
      data_valid <= data_valid_next;
    end
  end

  // data registers
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_o <= 0;
    end else begin
      data_o <= data_next;
    end
  end

endmodule