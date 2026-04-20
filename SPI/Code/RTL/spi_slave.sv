`timescale 1ns / 1ps

module spi_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    input  logic       cs_n,
    input  logic [7:0] tx_data,
    output logic       miso,
    output logic       rx_done,
    output logic [7:0] rx_data
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;

    logic sclk_rising, sclk_falling;
    logic sclk_first, sclk_second;
    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;

    assign sclk_rising  = sclk_first & (~sclk_second);
    assign sclk_falling = (~sclk_first) & sclk_second;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_first  <= 1'b0;
            sclk_second <= 1'b0;
        end else begin
            sclk_first  <= sclk;
            sclk_second <= sclk_first;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            miso         <= 1'b1;
            bit_cnt      <= 0;
            rx_done      <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0; 
        end else begin
            rx_done <= 1'b0;
            case (state)
                IDLE: begin
                    miso <= 1'b1;
                    if (cs_n == 1'b0) begin
                        bit_cnt      <= 0;
                        miso         <= tx_data[7];
                        tx_shift_reg <= {tx_data[6:0], 1'b0};
                        state        <= DATA;
                    end
                end
                DATA: begin
                    if (sclk_rising) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                    end else if (sclk_falling) begin
                        if (bit_cnt < 7) begin
                            miso         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                        if (bit_cnt == 7) begin
                            state   <= STOP;
                            rx_data <= rx_shift_reg;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                STOP: begin
                    rx_done <= 1'b1;
                    miso    <= 1'b1;
                    if (cs_n == 1) begin
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
