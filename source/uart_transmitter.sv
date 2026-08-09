module uart_transmitter (
    input logic arst_ni,
    input logic clk_i,

    input logic [7:0] data_i,
    input logic [1:0] num_bits_i,
    input logic       parity_en_i,
    input logic       parity_type_i,
    input logic       extra_stop_i,
    input logic       data_valid_i,

    output logic data_ready_o,
    output logic tx_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPE DEFINITIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [2:0] {
    IDLE,       // 0
    START,      // 1
    DATA,       // 2
    PARITY,     // 3
    STOP,       // 4
    EXTRA_STOP  // 5
  } tx_state_t;

  tx_state_t state;
  tx_state_t state_next;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [2:0] data_count;
  logic [2:0] data_count_next;

  logic parity[4];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COMBINATIONALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb parity[0] = ^data_i[4:0];
  always_comb parity[1] = parity[0] ^ data_i[5];
  always_comb parity[2] = parity[1] ^ data_i[6];
  always_comb parity[3] = parity[2] ^ data_i[7];

  // data count next
  always_comb begin
    case (state)
      DATA: data_count_next = data_count + 1;
      default: data_count_next = 0;
    endcase
  end

  // state next
  always_comb begin
    state_next   = state;
    data_ready_o = 0;
    tx_o         = 1;

    case (state)

      IDLE: begin
        if (data_valid_i) state_next = START;
      end

      START: begin
        if (data_valid_i) begin
          state_next = DATA;
          tx_o = 0;
        end else state_next = IDLE;
      end

      DATA: begin
        tx_o = data_i[data_count];
        if (data_count == (4 + num_bits_i)) begin
          if (parity_en_i) state_next = PARITY;
          else state_next = STOP;
        end
      end

      PARITY: begin
        if (parity_type_i) tx_o = ~parity[num_bits_i];
        else tx_o = parity[num_bits_i];
        state_next = STOP;
      end

      STOP: begin
        data_ready_o = 1;
        if (extra_stop_i) state_next = EXTRA_STOP;
        else if (data_valid_i) state_next = START;
        else state_next = IDLE;
      end

      EXTRA_STOP: begin
        if (data_valid_i) state_next = START;
        else state_next = IDLE;
      end

      default: state_next = IDLE;

    endcase
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // data count registers
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_count <= 0;
    end else begin
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

endmodule
