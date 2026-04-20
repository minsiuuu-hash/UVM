`timescale 1ns / 1ps

module i2c_top_simple (
    input logic clk,
    input logic reset,

    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    input logic [7:0] master_tx_data,
    input logic [7:0] slave_tx_data,

    output logic [7:0] master_rx_data,
    output logic [7:0] slave_rx_data,

    output logic master_done,
    output logic slave_done,
    output logic master_busy,
    output logic master_ack_out,
    output logic slave_ack_out,

    output logic scl,
    output logic sda
);

    logic master_sda_o;
    logic slave_sda_o;

    logic master_sda_i;
    logic slave_sda_i;

    assign sda = master_sda_o & slave_sda_o;

    assign master_sda_i = sda;
    assign slave_sda_i = sda;

    i2c_master U_I2C_MASTER (
        .clk  (clk),
        .reset(reset),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),

        .tx_data(master_tx_data),
        .ack_in (1'b0),

        .rx_data(master_rx_data),
        .done   (master_done),
        .ack_out(master_ack_out),
        .busy   (master_busy),

        .sda_i(master_sda_i),
        .scl  (scl),
        .sda_o(master_sda_o)
    );

    i2c_slave U_I2C_SLAVE (
        .clk  (clk),
        .reset(reset),

        .tx_data(slave_tx_data),
        .sda_i  (slave_sda_i),
        .ack_in (1'b0),

        .scl(scl),

        .rx_data(slave_rx_data),
        .sda_o  (slave_sda_o),
        .ack_out(slave_ack_out),
        .done   (slave_done)
    );

endmodule
