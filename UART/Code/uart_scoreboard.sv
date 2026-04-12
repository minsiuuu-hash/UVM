`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    uvm_tlm_analysis_fifo #(uart_seq_item) exp_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) act_fifo;

    int pass_cnt;
    int fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
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

            if (exp_item.tx_data == act_item.rx_data) begin
                pass_cnt++;
                `uvm_info(get_type_name(), $sformatf(
                                               "PASS exp=0x%02h act=0x%02h",
                                               exp_item.tx_data,
                                               act_item.rx_data), UVM_MEDIUM)
            end else begin
                fail_cnt++;
                `uvm_error(get_type_name(), $sformatf(
                           "FAIL exp=0x%02h act=0x%02h",
                           exp_item.tx_data,
                           act_item.rx_data
                           ))
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        string result = (fail_cnt == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "******** Report Summary ********",
                  UVM_MEDIUM);
        `uvm_info(get_type_name(), $sformatf(" Result : %s", result),
                  UVM_MEDIUM);
        `uvm_info(get_type_name(), $sformatf(
                  " Overall : %0d", pass_cnt + fail_cnt), UVM_MEDIUM);
        `uvm_info(get_type_name(), $sformatf(" Pass num : %0d", pass_cnt),
                  UVM_MEDIUM);
        `uvm_info(get_type_name(), $sformatf(" Fail  num : %0d", fail_cnt),
                  UVM_MEDIUM);
        `uvm_info(get_type_name(), "***************************", UVM_MEDIUM);
    endfunction
endclass

`endif
