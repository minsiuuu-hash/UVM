`timescale 1ns / 1ps

module spi_master_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [5:0] clk_div,
    input  logic [7:0] tx_data,
    input  logic       btn_start,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       busy,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       cs_n
);

    logic o_btn;

    spi_master U_SPI_MASTER (
        .clk(clk),
        .reset(reset),
        .cpol(cpol),
        .cpha(cpha),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .start(o_btn),
        .rx_data(rx_data),
        .done(done),
        .busy(busy),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    btn_debounce U_BTN_D (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(o_btn)
    );
endmodule
