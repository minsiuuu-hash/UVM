`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uvm_analysis_port #(uart_seq_item) ap;
    virtual uart_if u_if;

    localparam int BIT_PERIOD = 10416;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "u_if", u_if)) begin
            `uvm_fatal(get_type_name(), "can't find u_if")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "start UART Monitor ..", UVM_MEDIUM);

        forever begin
            uart_seq_item rx;
            rx = uart_seq_item::type_id::create("rx");
            receiver_rx(rx);
            ap.write(rx);
            `uvm_info(get_type_name(), rx.convert2string(), UVM_MEDIUM);
        end
    endtask

    task receiver_rx(uart_seq_item rx);
        @(negedge u_if.uart_tx);

        repeat (BIT_PERIOD / 2) @(u_if.mon_cb);

        if (u_if.mon_cb.uart_tx != 1'b0) begin
            `uvm_error(get_type_name(), "Invalid start bit");
            return;
        end

        repeat (BIT_PERIOD) @(u_if.mon_cb);

        for (int i = 0; i < 8; i++) begin
            rx.rx_data[i] = u_if.mon_cb.uart_tx;
            repeat (BIT_PERIOD) @(u_if.mon_cb);
        end

        if (u_if.mon_cb.uart_tx != 1'b1)
            `uvm_error(get_type_name(), "Invalid stop bit");
    endtask

endclass

`endif
