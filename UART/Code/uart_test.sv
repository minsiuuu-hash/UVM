`ifndef UART_TEST_SV
`define UART_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_test extends uvm_test;
    `uvm_component_utils(uart_test)

    uart_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== UVM hierarchical structure =====",
                  UVM_MEDIUM);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_seq seq;

        phase.raise_objection(this);

        seq = uart_seq::type_id::create("seq");
        seq.num_transaction = 15;
        seq.start(env.agent.sqr);

        #10000000;
        phase.drop_objection(this);
    endtask
endclass

`endif
