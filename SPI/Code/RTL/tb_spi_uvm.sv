import uvm_pkg::*;
`include "uvm_macros.svh"

interface spi_if (
    input logic clk,
    input logic reset
);

    logic       cpol;
    logic       cpha;
    logic [5:0] clk_div;
    logic [7:0] master_tx_data;
    logic       start;

    logic [7:0] slave_rx_data;
    logic       slave_done;

    logic [7:0] master_rx_data;
    logic       master_done;
    logic       busy;

    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output cpol;
        output cpha;
        output clk_div;
        output master_tx_data;
        output start;

        input busy;
        input master_done;
        input slave_done;
        input slave_rx_data;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input cpol;
        input cpha;
        input clk_div;
        input master_tx_data;
        input start;

        input slave_rx_data;
        input slave_done;

        input master_rx_data;
        input master_done;
        input busy;

        input sclk;
        input mosi;
        input miso;
        input cs_n;
    endclocking

endinterface

class spi_seq_item extends uvm_sequence_item;
    rand logic [7:0] tx_data;
    logic [7:0] rx_data;

    constraint c_tx_data {tx_data inside {[8'h00 : 8'hff]};}

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(rx_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return
            $sformatf("tx_data = 0x%02h, rx_data = 0x%02h", tx_data, rx_data);
    endfunction

endclass

class spi_rand_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_rand_seq)

    int num_trans = 0;

    function new(string name = "spi_rand_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        repeat (num_trans) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize()) begin
                `uvm_fatal(get_type_name(), "spi_seq_item randomize() fail!")
            end
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
            finish_item(item);
        end
    endtask

endclass

class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_if s_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if)) begin
            `uvm_fatal(get_type_name(), "can't find s_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item item;

        s_if.drv_cb.cpol           <= 1'b0;
        s_if.drv_cb.cpha           <= 1'b0;
        s_if.drv_cb.clk_div        <= 6'd4;
        s_if.drv_cb.master_tx_data <= 8'h00;
        s_if.drv_cb.start          <= 1'b0;

        wait (s_if.reset == 1'b0);
        repeat (5) @(s_if.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);

            while (s_if.drv_cb.busy) begin
                @(s_if.drv_cb);
            end

            @(s_if.drv_cb);
            s_if.drv_cb.master_tx_data <= item.tx_data;
            s_if.drv_cb.start          <= 1'b1;

            @(s_if.drv_cb);
            s_if.drv_cb.start <= 1'b0;
            `uvm_info(get_type_name(), $sformatf(
                      "[DRV] start transmit tx_data = 0x%02h", item.tx_data),
                      UVM_MEDIUM)

            wait (s_if.drv_cb.slave_done == 1'b1);
            @(s_if.drv_cb);
            `uvm_info(get_type_name(), $sformatf(
                      "[DRV] complete transmit tx_data = 0x%02h", item.tx_data),
                      UVM_MEDIUM)

            seq_item_port.item_done();
        end
    endtask

endclass

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if                    s_if;
    uvm_analysis_port #(spi_seq_item) ap;

    spi_seq_item                      item;
    logic                             tx_captured;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "s_if", s_if)) begin
            `uvm_fatal(get_type_name(), "can't find s_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
        tx_captured = 1'b0;

        forever begin
            @(s_if.mon_cb);

            if (s_if.mon_cb.start) begin
                item = spi_seq_item::type_id::create("item");
                item.tx_data = s_if.mon_cb.master_tx_data;
                tx_captured = 1'b1;
                `uvm_info(get_type_name(), $sformatf(
                                               "[MON] captured TX = 0x%02h",
                                               item.tx_data), UVM_HIGH)
            end

            if (s_if.mon_cb.slave_done) begin
                if (!tx_captured) begin
                    `uvm_warning(get_type_name(),
                                 "slave_done detected before tx_data captured")
                end else begin
                    item.rx_data = s_if.mon_cb.slave_rx_data;
                    `uvm_info(get_type_name(), $sformatf(
                              "[MON] captured RX = 0x%02h", item.rx_data),
                              UVM_HIGH)
                    ap.write(item);
                    tx_captured = 1'b0;
                end
            end
        end
    endtask

endclass

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) ap_imp;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(spi_seq_item item);
        if (item.tx_data !== item.rx_data) begin
            fail_cnt++;
            `uvm_error(
                get_type_name(),
                $sformatf("[FAIL] mismatch tx_data = 0x%02h, rx_data = 0x%02h",
                          item.tx_data, item.rx_data))
        end else begin
            pass_cnt++;
            `uvm_info(get_type_name(), $sformatf(
                      "[PASS] match tx_data = 0x%02h, rx_data = 0x%02h",
                      item.tx_data,
                      item.rx_data
                      ), UVM_MEDIUM)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===== Scoreboard Summary =====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "Total transactions : %0d", pass_cnt + fail_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "Pass               : %0d", pass_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "Fail               : %0d", fail_cnt), UVM_LOW)
        if (fail_cnt > 0) begin
            `uvm_error(get_type_name(),
                       $sformatf("TEST FAILED: %0d mismatches detected",
                                 fail_cnt))
        end else begin
            `uvm_info(get_type_name(), $sformatf(
                      "TEST PASSED: all %0d transactions matched", pass_cnt),
                      UVM_LOW)
        end
    endfunction

endclass

class spi_coverage extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_coverage)

    logic [7:0] cov_tx_data;

    covergroup cg_data;
        cp_tx_data: coverpoint cov_tx_data {
            bins zero = {8'h00};
            bins max = {8'hff};
            bins alt_01 = {8'h55};
            bins alt_10 = {8'haa};
            bins lsb_only = {8'h01};
            bins msb_only = {8'h80};
            bins low = {[8'h00 : 8'h3f]};
            bins mid = {[8'h40 : 8'hbf]};
            bins high = {[8'hc0 : 8'hff]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_data = new();
    endfunction

    function void write(spi_seq_item t);
        cov_tx_data = t.tx_data;
        cg_data.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
                  "Coverage : cg_data = %.1f%%", cg_data.get_coverage()),
                  UVM_LOW)
    endfunction

endclass

class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)

    spi_driver drv;
    spi_monitor mon;
    uvm_sequencer #(spi_seq_item) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = spi_driver::type_id::create("drv", this);
        mon = spi_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(spi_seq_item)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

class spi_env extends uvm_env;
    `uvm_component_utils(spi_env)

    spi_agent      agt;
    spi_scoreboard scb;
    spi_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt = spi_agent::type_id::create("agt", this);
        scb = spi_scoreboard::type_id::create("scb", this);
        cov = spi_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass

class spi_rand_test extends uvm_test;
    `uvm_component_utils(spi_rand_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        spi_rand_seq seq;
        phase.raise_objection(this);
        seq = spi_rand_seq::type_id::create("seq");
        seq.num_trans = 20;
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

endclass

module tb_spi_uvm;

    logic clk;
    logic reset;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        repeat (5) @(posedge clk);
        reset = 1'b0;
    end

    spi_if s_if (
        .clk  (clk),
        .reset(reset)
    );

    spi_top_simple dut (
        .clk           (clk),
        .reset         (reset),
        .cpol          (s_if.cpol),
        .cpha          (s_if.cpha),
        .clk_div       (s_if.clk_div),
        .master_tx_data(s_if.master_tx_data),
        .start         (s_if.start),

        .slave_rx_data(s_if.slave_rx_data),
        .slave_done   (s_if.slave_done),

        .master_rx_data(s_if.master_rx_data),
        .master_done   (s_if.master_done),
        .busy          (s_if.busy),

        .sclk(s_if.sclk),
        .mosi(s_if.mosi),
        .miso(s_if.miso),
        .cs_n(s_if.cs_n)
    );

    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "*", "s_if", s_if);
        run_test("spi_rand_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_spi_uvm, "+all");
    end

endmodule
