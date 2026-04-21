interface uart_if (
    input logic clk,
    input logic rst
);
    logic uart_rx;
    logic uart_tx;

    clocking drv_cb @(posedge clk);
        default output #0;
        output uart_rx;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input uart_tx;
    endclocking

endinterface
