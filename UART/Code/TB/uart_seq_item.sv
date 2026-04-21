`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_seq_item extends uvm_sequence_item;
    rand logic [7:0] tx_data;
    logic [7:0] rx_data;  // output

    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(rx_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("tx_data = 0x%02h rx_data = 0x%02h", tx_data, rx_data);
    endfunction

endclass

`endif
