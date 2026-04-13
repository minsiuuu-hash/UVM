`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if u_if;
    uvm_analysis_port #(uart_seq_item) ap;

    localparam int BIT_PERIOD = 10416;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "u_if", u_if))
            `uvm_fatal(get_type_name(), "can't find u_if");
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_init();
        wait (u_if.rst == 0);
        `uvm_info(get_type_name(), "check reset off, wait for transaction..",
                  UVM_MEDIUM);

        forever begin
            uart_seq_item tx;
            uart_seq_item tx_cp;

            seq_item_port.get_next_item(tx);

            tx_cp = uart_seq_item::type_id::create("tx_cp");
            tx_cp.copy(tx);
            ap.write(tx_cp);

            transmitter_tx(tx);
            seq_item_port.item_done();
        end
    endtask

    task uart_init();
        u_if.drv_cb.uart_rx <= 1;
    endtask

    task transmitter_tx(uart_seq_item tx);
        //START STATE
        u_if.drv_cb.uart_rx <= 0;
        repeat (BIT_PERIOD) @(u_if.drv_cb);
        // DATA STATE
        for (int i = 0; i < 8; i++) begin
            u_if.drv_cb.uart_rx <= tx.tx_data[i];
            repeat (BIT_PERIOD) @(u_if.drv_cb);
        end
        // STOP STATE
        u_if.drv_cb.uart_rx <= 1;
        repeat (BIT_PERIOD) @(u_if.drv_cb);
        // IDLE STATE
        repeat (BIT_PERIOD) @(u_if.drv_cb);
    endtask
endclass

`endif
