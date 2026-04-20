`timescale 1ns / 1ps

module I2C_Slave (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    input  logic       scl,
    inout  logic       sda,
    output logic [7:0] rx_data,
    output logic       ack_out,
    output logic       done
);

    logic sda_o, sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave U_I2C_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .tx_data(tx_data),
        .sda_i  (sda_i),
        .ack_in (1'b0),
        .scl    (scl),
        .rx_data(rx_data),
        .sda_o  (sda_o),
        .ack_out(ack_out),
        .done   (done)
    );

endmodule

module i2c_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    input  logic       sda_i,
    input  logic       ack_in,
    input  logic       scl,
    output logic [7:0] rx_data,
    output logic       sda_o,
    output logic       ack_out,
    output logic       done
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        ADDR,
        ADDR_ACK,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e state;

    localparam address = 7'b0101010;

    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [2:0] bit_cnt;
    logic sda_r;
    logic sda_rising;
    logic sda_falling;
    logic scl_rising;
    logic scl_falling;
    logic sda_first, sda_second;
    logic scl_first, scl_second;
    logic ack_in_r;
    logic rw_flag;
    logic ack_phase;

    assign sda_o = sda_r;

    assign sda_rising = (sda_first) & (~sda_second) & scl_second;
    assign sda_falling = (~sda_first) & (sda_second) & scl_second;
    assign scl_rising = (scl_first) & (~scl_second);
    assign scl_falling = (~scl_first) & (scl_second);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_first  <= 1'b0;
            sda_second <= 1'b0;
            scl_first  <= 1'b0;
            scl_second <= 1'b0;
        end else begin
            sda_first  <= sda_i;
            sda_second <= sda_first;
            scl_first  <= scl;
            scl_second <= scl_first;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            rx_data      <= 0;
            ack_out      <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            sda_r        <= 1'b1;
            bit_cnt      <= 0;
            ack_in_r     <= 1'b1;
            rw_flag      <= 1'b0;
            ack_phase    <= 1'b0;
        end else begin
            done <= 1'b0;
            if (sda_rising) begin
                done         <= 1'b1;
                sda_r        <= 1'b1;  // release
                bit_cnt      <= 0;
                ack_phase    <= 1'b0;
                rx_shift_reg <= 8'd0;
                state        <= IDLE;
            end else begin
                case (state)
                    IDLE: begin
                        sda_r   <= 1'b1;
                        bit_cnt <= 0;
                        if (sda_falling) begin
                            state <= ADDR;
                        end
                    end
                    ADDR: begin
                        if (scl_rising) begin
                            tx_shift_reg <= {tx_shift_reg[6:0], sda_i};
                            if (bit_cnt == 7) begin
                                bit_cnt <= 0;
                                if (tx_shift_reg[6:0] == address) begin
                                    rw_flag <= sda_i;
                                    if (sda_i) begin
                                        tx_shift_reg <= tx_data;
                                    end else begin
                                        rx_shift_reg <= 0;
                                    end
                                    state     <= ADDR_ACK;
                                    ack_phase <= 1'b0;
                                    ack_in_r  <= ack_in;
                                end else begin
                                    state <= STOP;
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                    ADDR_ACK: begin
                        if (!ack_phase) begin
                            sda_r <= 1'b0;
                            if (scl_rising) begin
                                ack_out   <= 1'b0;
                                ack_phase <= 1'b1;
                            end
                        end else begin
                            if (scl_falling) begin
                                ack_phase <= 1'b0;
                                bit_cnt   <= 0;

                                if (rw_flag) begin
                                    // read일 때 첫 tx bit 미리 준비
                                    sda_r <= tx_shift_reg[7];
                                end else begin
                                    sda_r <= 1'b1;
                                end

                                state <= DATA;
                            end
                        end
                    end
                    DATA: begin
                        if (rw_flag) begin
                            if (scl_falling) begin
                                sda_r <= tx_shift_reg[7];
                            end
                            if (scl_rising) begin
                                if (bit_cnt == 7) begin
                                    bit_cnt <= 0;
                                    state   <= DATA_ACK;
                                end else begin
                                    bit_cnt      <= bit_cnt + 1;
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end
                        end else if (scl_rising) begin
                            sda_r <= 1'b1;
                            if (bit_cnt == 7) begin
                                rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                bit_cnt      <= 0;
                                ack_phase    <= 1'b0;
                                state        <= DATA_ACK;
                            end else begin
                                bit_cnt      <= bit_cnt + 1;
                                rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                            end
                        end
                    end
                    DATA_ACK: begin
                        if (rw_flag) begin
                            if (!ack_phase) begin
                                if (scl_falling) begin
                                    sda_r     <= 1'b1;  // release
                                    ack_phase <= 1'b1;
                                end
                            end else begin
                                if (scl_rising) begin
                                    ack_out   <= sda_i;
                                    ack_phase <= 1'b0;
                                    bit_cnt   <= 0;
                                    if (sda_i == 1'b0) begin
                                        tx_shift_reg <= tx_data;   
                                        state <= DATA;
                                    end else begin
                                        state <= STOP;
                                    end
                                end
                            end
                        end else begin
                            rx_data <= rx_shift_reg;
                            if (!ack_phase) begin
                                sda_r <= ack_in_r;  // 0 : ACK
                                if (scl_rising) begin
                                    ack_phase <= 1'b1;
                                end
                            end else begin
                                if (scl_falling) begin
                                    sda_r <= 1'b1;  // after ack : release
                                    ack_phase <= 1'b0;
                                    bit_cnt <= 0;
                                    rx_shift_reg <= 8'd0;
                                    state        <= DATA;  
                                end
                            end
                        end
                    end
                    STOP: begin
                        if (sda_rising) begin
                            done  <= 1'b1;
                            sda_r <= 1'b1;
                            state <= IDLE;
                        end
                    end
                    default: begin
                        state <= IDLE;
                    end
                endcase
            end
        end
    end
endmodule

