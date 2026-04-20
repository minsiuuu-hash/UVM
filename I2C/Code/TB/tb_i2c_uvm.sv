import uvm_pkg::*;
`include "uvm_macros.svh"

interface i2c_if (
    input logic clk,
    input logic reset
);

    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;

    logic [7:0] master_tx_data;
    logic [7:0] slave_tx_data;

    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;

    logic       master_done;
    logic       slave_done;
    logic       master_busy;
    logic       master_ack_out;
    logic       slave_ack_out;

    logic       scl;
    logic       sda;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;

        output cmd_start;
        output cmd_write;
        output cmd_read;
        output cmd_stop;

        output master_tx_data;
        output slave_tx_data;

        input master_done;
        input slave_done;
        input master_busy;
        input master_ack_out;
        input slave_ack_out;
        input master_rx_data;
        input slave_rx_data;
        input scl;
        input sda;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;

        input cmd_start;
        input cmd_write;
        input cmd_read;
        input cmd_stop;

        input master_tx_data;
        input slave_tx_data;

        input master_done;
        input slave_done;
        input master_busy;
        input master_ack_out;
        input slave_ack_out;
        input master_rx_data;
        input slave_rx_data;
        input scl;
        input sda;
    endclocking

endinterface


class i2c_seq_item extends uvm_sequence_item;

    rand logic [7:0] tx_data;
    logic [7:0] rx_data;

    constraint c_tx_data {tx_data inside {[8'h00 : 8'hff]};}

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(rx_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return
            $sformatf("tx_data = 0x%02h, rx_data = 0x%02h", tx_data, rx_data);
    endfunction

endclass


class i2c_rand_seq extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_rand_seq)

    int num_trans = 20;

    function new(string name = "i2c_rand_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;

        repeat (num_trans) begin
            item = i2c_seq_item::type_id::create("item");

            start_item(item);

            if (!item.randomize()) begin
                `uvm_fatal(get_type_name(), "i2c_seq_item randomize() fail!")
            end

            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)

            finish_item(item);
        end
    endtask

endclass


class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    virtual i2c_if i_if;

    localparam logic [7:0] I2C_ADDR_W = 8'h54;
    // slave address = 7'b0101010
    // address + write bit = {7'b0101010, 1'b0} = 8'h54

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i_if", i_if)) begin
            `uvm_fatal(get_type_name(), "can't find i_if")
        end
    endfunction

    task automatic clear_cmd();
        i_if.drv_cb.cmd_start <= 1'b0;
        i_if.drv_cb.cmd_write <= 1'b0;
        i_if.drv_cb.cmd_read  <= 1'b0;
        i_if.drv_cb.cmd_stop  <= 1'b0;
    endtask

    task automatic wait_master_done();
        do begin
            @(i_if.drv_cb);
        end while (i_if.drv_cb.master_done !== 1'b1);

        @(i_if.drv_cb);
    endtask

    task automatic send_start();
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_start <= 1'b1;

        @(i_if.drv_cb);
        i_if.drv_cb.cmd_start <= 1'b0;

        wait_master_done();

        `uvm_info(get_type_name(), "[DRV] START complete", UVM_HIGH)
    endtask

    task automatic send_write(input logic [7:0] data);
        @(i_if.drv_cb);
        i_if.drv_cb.master_tx_data <= data;
        i_if.drv_cb.cmd_write      <= 1'b1;

        @(i_if.drv_cb);
        i_if.drv_cb.cmd_write <= 1'b0;

        wait_master_done();

        if (i_if.drv_cb.master_ack_out !== 1'b0) begin
            `uvm_error(
                get_type_name(),
                $sformatf(
                    "[DRV] NACK detected. write_data = 0x%02h, ack_out = %0b",
                    data, i_if.drv_cb.master_ack_out))
        end else begin
            `uvm_info(get_type_name(), $sformatf(
                      "[DRV] WRITE complete data = 0x%02h, ACK received", data),
                      UVM_HIGH)
        end
    endtask

    task automatic send_stop();
        @(i_if.drv_cb);
        i_if.drv_cb.cmd_stop <= 1'b1;

        @(i_if.drv_cb);
        i_if.drv_cb.cmd_stop <= 1'b0;

        wait_master_done();

        `uvm_info(get_type_name(), "[DRV] STOP complete", UVM_HIGH)
    endtask

    task run_phase(uvm_phase phase);
        i2c_seq_item item;

        i_if.drv_cb.cmd_start      <= 1'b0;
        i_if.drv_cb.cmd_write      <= 1'b0;
        i_if.drv_cb.cmd_read       <= 1'b0;
        i_if.drv_cb.cmd_stop       <= 1'b0;
        i_if.drv_cb.master_tx_data <= 8'h00;
        i_if.drv_cb.slave_tx_data  <= 8'h00;

        wait (i_if.reset == 1'b0);
        repeat (10) @(i_if.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);

            `uvm_info(get_type_name(), $sformatf(
                      "[DRV] start transaction : random tx_data = 0x%02h",
                      item.tx_data
                      ), UVM_MEDIUM)

            // I2C write sequence
            // START -> WRITE(address + W) -> WRITE(random data) -> STOP
            send_start();
            send_write(I2C_ADDR_W);
            send_write(item.tx_data);
            send_stop();

            `uvm_info(
                get_type_name(), $sformatf(
                "[DRV] complete transaction : tx_data = 0x%02h", item.tx_data),
                UVM_MEDIUM)

            repeat (10) @(i_if.drv_cb);

            seq_item_port.item_done();
        end
    endtask

endclass


class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual i2c_if                    i_if;
    uvm_analysis_port #(i2c_seq_item) ap;

    i2c_seq_item                      item;

    int                               write_count;
    logic                             data_captured;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i_if", i_if)) begin
            `uvm_fatal(get_type_name(), "can't find i_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
        write_count   = 0;
        data_captured = 1'b0;
        item          = null;

        forever begin
            @(i_if.mon_cb);

            // 수정된 부분
            if (i_if.reset) begin
                write_count   = 0;
                data_captured = 1'b0;
                item          = null;
            end

            if (i_if.mon_cb.cmd_start) begin
                write_count   = 0;
                data_captured = 1'b0;
                item          = null;

                `uvm_info(get_type_name(), "[MON] START detected", UVM_HIGH)
            end

            if (i_if.mon_cb.cmd_write) begin
                write_count++;

                if (write_count == 1) begin
                    `uvm_info(get_type_name(),
                              $sformatf("[MON] ADDR WRITE detected = 0x%02h",
                                        i_if.mon_cb.master_tx_data), UVM_HIGH)
                end else if (write_count == 2) begin
                    item = i2c_seq_item::type_id::create("item");
                    item.tx_data = i_if.mon_cb.master_tx_data;
                    data_captured = 1'b1;

                    `uvm_info(get_type_name(),
                              $sformatf("[MON] DATA WRITE detected = 0x%02h",
                                        item.tx_data), UVM_HIGH)
                end
            end

            if (i_if.mon_cb.slave_done) begin
                if (data_captured && item != null) begin
                    item.rx_data = i_if.mon_cb.slave_rx_data;

                    `uvm_info(get_type_name(),
                              $sformatf(
                                  "[MON] SLAVE DONE detected. rx_data = 0x%02h",
                                  item.rx_data), UVM_HIGH)

                    ap.write(item);

                    write_count   = 0;
                    data_captured = 1'b0;
                    item          = null;
                end
            end
        end
    endtask

endclass


class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) ap_imp;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(i2c_seq_item item);
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


class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
    `uvm_component_utils(i2c_coverage)

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

    function void write(i2c_seq_item t);
        cov_tx_data = t.tx_data;
        cg_data.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
                  "Coverage : cg_data = %.1f%%", cg_data.get_coverage()),
                  UVM_LOW)
    endfunction

endclass


class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)

    i2c_driver drv;
    i2c_monitor mon;
    uvm_sequencer #(i2c_seq_item) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        drv = i2c_driver::type_id::create("drv", this);
        mon = i2c_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(i2c_seq_item)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass


class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)

    i2c_agent      agt;
    i2c_scoreboard scb;
    i2c_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt = i2c_agent::type_id::create("agt", this);
        scb = i2c_scoreboard::type_id::create("scb", this);
        cov = i2c_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass


class i2c_rand_test extends uvm_test;
    `uvm_component_utils(i2c_rand_test)

    i2c_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = i2c_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_rand_seq seq;

        phase.raise_objection(this);

        seq = i2c_rand_seq::type_id::create("seq");
        seq.num_trans = 10;
        seq.start(env.agt.sqr);

        phase.drop_objection(this);
    endtask

endclass


module tb_i2c_uvm;

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

    i2c_if i_if (
        .clk  (clk),
        .reset(reset)
    );

    i2c_top_simple dut (
        .clk  (clk),
        .reset(reset),

        .cmd_start(i_if.cmd_start),
        .cmd_write(i_if.cmd_write),
        .cmd_read (i_if.cmd_read),
        .cmd_stop (i_if.cmd_stop),

        .master_tx_data(i_if.master_tx_data),
        .slave_tx_data (i_if.slave_tx_data),

        .master_rx_data(i_if.master_rx_data),
        .slave_rx_data (i_if.slave_rx_data),

        .master_done   (i_if.master_done),
        .slave_done    (i_if.slave_done),
        .master_busy   (i_if.master_busy),
        .master_ack_out(i_if.master_ack_out),
        .slave_ack_out (i_if.slave_ack_out),

        .scl(i_if.scl),
        .sda(i_if.sda)
    );

    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "i_if", i_if);
        run_test("i2c_rand_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_i2c_uvm, "+all");
    end

endmodule
