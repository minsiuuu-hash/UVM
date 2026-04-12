`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_seq extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_seq)
    int num_transaction = 0;

    function new(string name = "uart_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (num_transaction) begin
            uart_seq_item item = uart_seq_item::type_id::create("item");

            start_item(item);
            if (!item.randomize())
                `uvm_fatal(get_type_name(), "Randomization Fail!");
            finish_item(item);
        end
    endtask
endclass

`endif
