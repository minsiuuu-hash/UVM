`ifndef TEST_SV
`define TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_base_test extends uvm_test;
    `uvm_component_utils(apb_base_test)
    apb_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== UVM hierarchical structure =====",
                  UVM_MEDIUM);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);

    endtask

endclass

class apb_write_read_test extends apb_base_test;
    `uvm_component_utils(apb_write_read_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_read_seq seq;
        phase.raise_objection(this);
        seq = apb_write_read_seq::type_id::create("seq");
        seq.num_loop = 10;
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

endclass

class apb_rand_test extends apb_base_test;
    `uvm_component_utils(apb_rand_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_rand_seq seq;
        phase.raise_objection(this);
        seq = apb_rand_seq::type_id::create("seq");
        seq.num_loop = 10;
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

endclass
`endif
