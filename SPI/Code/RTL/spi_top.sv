`timescale 1ns / 1ps

module spi_top (
    input logic       clk,
    input logic       reset,
    input logic       start,
    input logic [7:0] master_tx_data,
    input logic [7:0] slave_tx_data,
    input logic [7:0] clk_div,

    output logic [7:0] master_rx_data,
    output logic [7:0] slave_rx_data,
    output logic       master_done,
    output logic       slave_done,
    output logic       busy,

    output logic sclk,
    output logic mosi,
    output logic miso,
    output logic cs_n
);

    logic cpol;
    logic cpha;

    assign cpol = 1'b0;  // mode 0
    assign cpha = 1'b0;  // mode 0

    spi_master u_spi_master (
        .clk    (clk),
        .reset  (reset),
        .cpol   (cpol),
        .cpha   (cpha),
        .clk_div(clk_div),
        .tx_data(master_tx_data),
        .start  (start),
        .rx_data(master_rx_data),
        .done   (master_done),
        .busy   (busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    spi_slave u_spi_slave (
        .clk    (clk),
        .reset  (reset),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n),
        .tx_data(slave_tx_data),
        .miso   (miso),
        .rx_done(slave_done),
        .rx_data(slave_rx_data)
    );

endmodule
