`timescale 1ns / 1ps

module tb_spi_top;

    logic       clk;
    logic       reset;
    logic       start;
    logic [7:0] master_tx_data;
    logic [7:0] slave_tx_data;
    logic [7:0] clk_div;

    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;
    logic       master_done;
    logic       slave_done;
    logic       busy;

    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;

    spi_top dut (
        .clk           (clk),
        .reset         (reset),
        .start         (start),
        .master_tx_data(master_tx_data),
        .slave_tx_data (slave_tx_data),
        .clk_div       (clk_div),
        .master_rx_data(master_rx_data),
        .slave_rx_data (slave_rx_data),
        .master_done   (master_done),
        .slave_done    (slave_done),
        .busy          (busy),
        .sclk          (sclk),
        .mosi          (mosi),
        .miso          (miso),
        .cs_n          (cs_n)
    );

    // 100MHz system clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task do_transfer(input [7:0] m_tx, input [7:0] s_tx);
        begin
            @(negedge clk);
            master_tx_data = m_tx;
            slave_tx_data  = s_tx;

            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Master가 먼저 done될 수 있음
            wait (master_done == 1'b1);

            // Slave rx_data가 갱신될 때까지 기다려야 함
            wait (slave_done == 1'b1);

            // nonblocking assignment 반영 여유
            @(posedge clk);

            $display("--------------------------------------------------");
            $display("TIME = %0t", $time);
            $display("MASTER TX = 0x%02h", m_tx);
            $display("SLAVE  TX = 0x%02h", s_tx);
            $display("MASTER RX = 0x%02h", master_rx_data);
            $display("SLAVE  RX = 0x%02h", slave_rx_data);

            if (master_rx_data == s_tx)
                $display("MASTER RX PASS");
            else
                $display("MASTER RX FAIL");

            if (slave_rx_data == m_tx)
                $display("SLAVE RX PASS");
            else
                $display("SLAVE RX FAIL");

            @(negedge clk);
        end
    endtask

    initial begin
        // init
        reset          = 1'b1;
        start          = 1'b0;
        master_tx_data = 8'h00;
        slave_tx_data  = 8'h00;
        clk_div        = 8'd4;  // SPI speed divider

        // reset release
        repeat (5) @(negedge clk);
        reset = 1'b0;

        // 1st transfer
        do_transfer(8'hA5, 8'h3C);

        // 2nd transfer
        do_transfer(8'h5A, 8'hC3);

        // finish
        repeat (20) @(negedge clk);
        $finish;
    end

endmodule