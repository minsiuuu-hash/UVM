`ifndef ENVIRONMENT_SV 
`define ENVIRONMENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)
	apb_agent agt;
	apb_scoreboard scb;
	apb_coverage cov;

	function new(string name, uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agt = apb_agent::type_id::create("agt",this);
		scb = apb_scoreboard::type_id::create("scb",this);
		cov = apb_coverage::type_id::create("cov",this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agt.mon.ap.connect(scb.ap_imp);
		agt.mon.ap.connect(cov.analysis_export);
	endfunction

endclass

`endif
