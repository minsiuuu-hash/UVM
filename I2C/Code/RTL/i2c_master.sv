`timescale 1ns / 1ps

module I2C_Master (
    input  logic       clk,
    input  logic       reset,
    // command port
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    // internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    output logic       scl,
    inout  logic       sda
);

    logic sda_o, sda_i;
    logic btn_u, btn_d, btn_r, btn_l;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_master U_I2C_MASTER (
        .clk(clk),
        .reset(reset),
        .cmd_start(btn_r),
        .cmd_write(btn_u),
        .cmd_read(btn_d),
        .cmd_stop(btn_l),
        .tx_data(tx_data),
        .ack_in(1'b0),
        .rx_data(rx_data),
        .done(done),
        .ack_out(ack_out),
        .busy(busy),
        .sda_i(sda_i),
        .scl(scl),
        .sda_o(sda_o)
    );
    btn_debounce U_BTN_START_RIGHT (
        .clk  (clk),
        .reset(reset),
        .i_btn(cmd_start),
        .o_btn(btn_r)
    );
    btn_debounce U_BTN_STOP_LEFT (
        .clk  (clk),
        .reset(reset),
        .i_btn(cmd_stop),
        .o_btn(btn_l)
    );
    btn_debounce U_BTN_WRITE_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(cmd_write),
        .o_btn(btn_u)
    );
    btn_debounce U_BTN_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(cmd_read),
        .o_btn(btn_d)
    );
endmodule

module i2c_master (
    input  logic       clk,
    input  logic       reset,
    // command port
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    // internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    input  logic       sda_i,
    output logic       scl,
    output logic       sda_o
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e state;

    logic [7:0] div_cnt;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [7:0] bit_cnt;
    logic [1:0] step;
    logic qtr_tick;
    logic scl_r;
    logic sda_r;
    logic is_read;
    logic ack_in_r;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 249) begin  // scl : 100Khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            sda_r        <= 1'b1;
            scl_r        <= 1'b1;
            step         <= 2'd0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            is_read      <= 1'b0;
            bit_cnt      <= 0;
            ack_in_r     <= 1'b1;
            rx_data      <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    sda_r <= 1'b1;
                    scl_r <= 1'b1;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 2'd0;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 0;
                        is_read      <= 1'b0;
                        state        <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 0;
                        bit_cnt      <= 0;
                        is_read      <= 1'b1;
                        ack_in_r     <= ack_in;
                        state        <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end
                end
                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (is_read) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                if (bit_cnt == 7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                if (is_read) begin
                                    sda_r <= ack_in_r;
                                end else begin
                                    sda_r <= 1'b1;  // sda input setting
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (!is_read) begin  // ack receive
                                    ack_out <= sda_i;
                                end
                                if (is_read) begin
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
