`ifndef COMPONENT_SV
`define COMPONENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ram_coverage extends uvm_subscriber #(ram_seq_item);
    `uvm_component_utils(ram_coverage)

    ram_seq_item item;

    covergroup ram_cg;
        cp_wr: coverpoint item.wr {bins write_op = {1}; bins read_op = {0};}
        cp_addr: coverpoint item.addr {
            bins low = {[8'h00 : 8'h3f]};
            bins mid = {[8'h40 : 8'hbf]};
            bins high = {[8'hc0 : 8'hff]};
        }
        cp_rdata: coverpoint item.rdata iff (!item.wr) {
            bins low = {[16'h0000 : 16'h00ff]};
            bins mid = {[16'h0100 : 16'hfeff]};
            bins high = {[16'hff00 : 16'hffff]};
        }
        cx_wr_addr: cross cp_wr, cp_addr;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ram_cg = new();
    endfunction

    virtual function void write(ram_seq_item t);
        item = t;
        ram_cg.sample();
        `uvm_info(get_type_name(), $sformatf(
                  "ram_cg sampled: %s", item.convert2string()), UVM_MEDIUM);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n===== Coverage Summary =====", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf(
                  "Overall : %.1f%%", ram_cg.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf(
                  "Write/Read : %.1f%%", ram_cg.cp_wr.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf(
                  "Addr : %.1f%%", ram_cg.cp_addr.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf(
                  "Rdata : %.1f%%", ram_cg.cp_rdata.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf(
                  "cross(write,addr) : %.1f%%", ram_cg.cx_wr_addr.get_coverage()
                  ), UVM_LOW);
        `uvm_info(get_type_name(), " ===== Coverage Summary =====\n\n",
                  UVM_LOW);
    endfunction
endclass
`endif
