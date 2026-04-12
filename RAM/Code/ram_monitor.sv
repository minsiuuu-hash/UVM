`ifndef RAM_MONITOR_SV
`define RAM_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "ram_seq_item.sv"

class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    virtual ram_if r_if;

    uvm_analysis_port #(ram_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "can't find ram_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            ram_seq_item item = ram_seq_item::type_id::create("item");
            @(r_if.mon_cb);
            item.wr = r_if.mon_cb.wr;
            item.addr = r_if.mon_cb.addr;
            item.wdata = r_if.mon_cb.wdata;
            if (!item.wr) begin
                @(r_if.mon_cb);
                item.rdata = r_if.mon_cb.rdata;
            end
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
            ap.write(item);
        end
    endtask


endclass

`endif
