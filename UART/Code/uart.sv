`timescale 1ns / 1ps

module uart_top (
    input  logic clk,
    input  logic rst,
    input  logic uart_rx,
    output logic uart_tx
);

    logic       w_b_tick;
    logic       w_rx_done;
    logic [7:0] w_rx_data;

    uart_tx u_uart_tx (
        .clk     (clk),
        .rst     (rst),
        .tx_start(w_rx_done),
        .b_tick  (w_b_tick),
        .tx_data (w_rx_data),
        .tx_busy (),
        .tx_done (),
        .uart_tx (uart_tx)
    );

    uart_rx u_uart_rx (
        .clk    (clk),
        .rst    (rst),
        .rx     (uart_rx),
        .b_tick (w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    baud_tick u_baud_tick (
        .clk   (clk),
        .rst   (rst),
        .b_tick(w_b_tick)
    );

endmodule


module uart_rx (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t c_state, n_state;
    logic [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic done_reg, done_next;
    logic [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    always_comb begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                bit_cnt_next    = 3'd0;
                b_tick_cnt_next = 5'd0;
                done_next       = 1'b0;
                buf_next        = 8'd0;

                if (b_tick && !rx) begin
                    buf_next = 8'd0;
                    n_state  = START;
                end
            end

            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 5'd7) begin
                        b_tick_cnt_next = 5'd0;
                        if (rx == 1'b0) n_state = DATA;
                        else n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 5'd1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 5'd15) begin
                        buf_next = {rx, buf_reg[7:1]};

                        if (bit_cnt_reg == 3'd7) begin
                            b_tick_cnt_next = 5'd0;
                            bit_cnt_next    = 3'd0;
                            n_state         = STOP;
                        end else begin
                            b_tick_cnt_next = 5'd0;
                            bit_cnt_next    = bit_cnt_reg + 3'd1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 5'd1;
                    end
                end
            end

            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 5'd15) begin
                        b_tick_cnt_next = 5'd0;
                        done_next       = 1'b1;
                        n_state         = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 5'd1;
                    end
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule


module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       uart_tx,
    output       tx_busy,
    output       tx_done
);

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t c_state, n_state;
    logic tx_reg, tx_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic busy_reg, busy_next;
    logic done_reg, done_next;
    logic [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 3'd0;
            b_tick_cnt_reg  <= 4'd0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
        end
    end

    always_comb begin
        n_state          = c_state;
        tx_next          = tx_reg;
        bit_cnt_next     = bit_cnt_reg;
        b_tick_cnt_next  = b_tick_cnt_reg;
        busy_next        = busy_reg;
        done_next        = done_reg;
        data_in_buf_next = data_in_buf_reg;

        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 3'd0;
                b_tick_cnt_next = 4'd0;
                done_next       = 1'b0;

                if (tx_start) begin
                    n_state          = START;
                    busy_next        = 1'b1;
                    data_in_buf_next = tx_data;
                end
            end

            START: begin
                tx_next = 1'b0;

                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        n_state         = DATA;
                        b_tick_cnt_next = 4'd0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 4'd1;
                    end
                end
            end

            DATA: begin
                tx_next = data_in_buf_reg[0];

                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        if (bit_cnt_reg == 3'd7) begin
                            b_tick_cnt_next = 4'd0;
                            bit_cnt_next    = 3'd0;
                            n_state         = STOP;
                        end else begin
                            b_tick_cnt_next  = 4'd0;
                            bit_cnt_next     = bit_cnt_reg + 3'd1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 4'd1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;

                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        b_tick_cnt_next = 4'd0;
                        done_next       = 1'b1;
                        busy_next       = 1'b0;
                        n_state         = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 4'd1;
                    end
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule


module baud_tick #(
    parameter int BAUDRATE = 9600 * 16,
    parameter int CLK_FREQ = 100_000_000
) (
    input  logic clk,
    input  logic rst,
    output logic b_tick
);

    localparam int F_COUNT = CLK_FREQ / BAUDRATE;

    logic [$clog2(F_COUNT)-1:0] counter_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= '0;
            b_tick      <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= '0;
                b_tick      <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1'b1;
                b_tick      <= 1'b0;
            end
        end
    end

endmodule
