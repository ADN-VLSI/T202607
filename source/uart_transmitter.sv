module uart_transmitter(
    input       clk,
    input       rst_n,
        
    input       [7:0] data,
    input       [1:0] num_bits,
    input       parity_en,
    input       pariy_type,
    input       data_valid,


    output data_ready,
    output tx
);
    
    reg [2:0] data_count;
    reg [7:0] shift_reg;
    reg [3:0] data_len;

    reg parity_bit;


    typedef enum logic[2:0]{
        IDLE,
        START,
        DATA,
        PARITY,
        STOP,
        EXTRA_STOP
    }tx_state_t;
    state tx_state_t;


    always @(posedge clk) begin
        if(!rst_n) begin
            tx <= 1'b1;
            data <= 0;
            data_ready <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    tx <= 1'b1;
                    data_ready <= 0'b0;
                    state <= START;
                end
                
                START: begin
                    tx <= 0'b0;
                    state <= DATA;
                end

                DATA: begin
                    if(data_count <= (4 + num_bits)) begin
                        shift_reg<=data[data_count];
                        data_count<=data_count+1;
                        shift_reg<= shift_reg>>1;
                    end
                    else begin
                        state <= DATA;
                    end
                    if (parity_en == 1) begin
                        state <= PARITY;
                    end
                    else if(parity_en == 0) begin
                        state <= STOP;
                    end
                
                end

                PARITY: begin
                    if(parity_type==1) begin
                        shift_reg[data_count+1]= 1'b1;
                        state <= STOP;
                    end 
                    else if(parity_type==0) begin
                        shift_reg[data_count+1]= 1'b0;
                        state <= STOP;
                    end

                end

                STOP: begin
                    if(data_ready == 1) begin
                        state <= START;
                    end


                    
                end
                EXTRA_STOP: begin
                    
                end
            endcase
        end
    end
endmodule