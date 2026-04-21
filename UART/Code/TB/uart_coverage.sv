`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_coverage extends uvm_component;
    `uvm_component_utils(uart_coverage)

    uvm_tlm_analysis_fifo #(uart_seq_item) exp_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) act_fifo;

    logic [7:0] tx_data_cov;
    logic [7:0] rx_data_cov;
    bit match_cov;

    covergroup uart_cg;
        option.per_instance = 1;

        cp_tx: coverpoint tx_data_cov {bins all_vals[] = {[0 : 255]};}

        cp_rx: coverpoint rx_data_cov {bins all_vals[] = {[0 : 255]};}

        cp_match: coverpoint match_cov {bins pass = {1}; bins fail = {0};}

        tx_rx_cross : cross cp_tx, cp_rx;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        uart_cg = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_fifo = new("exp_fifo", this);
        act_fifo = new("act_fifo", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_seq_item exp_item;
        uart_seq_item act_item;

        forever begin
            exp_fifo.get(exp_item);
            act_fifo.get(act_item);

            tx_data_cov = exp_item.tx_data;
            rx_data_cov = act_item.rx_data;
            match_cov   = (exp_item.tx_data == act_item.rx_data);

            uart_cg.sample();
        end
    endtask
endclass

`endif
