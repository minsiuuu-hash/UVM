`timescale 1ns / 1ps

module btn_debounce (
    input  logic clk,
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);

    // clock divider for debounce shift register
    // 100MHz -> 100kHz
    // counter = 100M / 100K = 1000
    parameter int CLK_DIV = 100_000;
    parameter int F_COUNT = 100_000_000 / CLK_DIV;

    logic [$clog2(F_COUNT)-1:0] counter_reg;
    logic clk_100khz_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_reg    <= '0;
            clk_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg    <= '0;
                clk_100khz_reg <= 1'b1;
            end else begin
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    // series 8-tap F/F (8-bit shift register)
    logic [7:0] q_reg, q_next;
    logic debounce;

    always_ff @(posedge clk_100khz_reg or posedge reset) begin
        if (reset) begin
            q_reg <= '0;
        end else begin
            q_reg <= q_next;
        end
    end

    always_comb begin
        q_next = {i_btn, q_reg[7:1]};
    end

    // debounce, 8-input AND
    assign debounce = &q_reg;

    logic edge_reg;

    // edge detection
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & ~edge_reg;

endmodule
