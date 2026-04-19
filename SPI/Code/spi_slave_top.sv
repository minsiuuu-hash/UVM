`timescale 1ns / 1ps

module spi_slave_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    input  logic       cs_n,
    input  logic [7:0] tx_data,
    output logic       miso,
    output logic       rx_done,
    output logic [7:0] rx_data,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n),
        .tx_data(tx_data),
        .miso   (miso),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    fnd_controller U_FND_CNT (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data(rx_data),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );
endmodule
