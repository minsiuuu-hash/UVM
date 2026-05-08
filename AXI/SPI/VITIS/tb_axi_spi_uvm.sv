import uvm_pkg::*;
`include "uvm_macros.svh"

interface spi_if #(
    parameter int C_S00_AXI_ADDR_WIDTH = 4,
    parameter int C_S00_AXI_DATA_WIDTH = 32
) (
    input logic clk,
    input logic resetn
);

    // SPI signals
    logic                                sclk;
    logic                                mosi;
    logic                                cs_n;
    logic                                miso;

    // AXI-Lite signals
    logic [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [                         2:0] s00_axi_awprot;
    logic                                s00_axi_awvalid;
    logic                                s00_axi_awready;

    logic [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic                                s00_axi_wvalid;
    logic                                s00_axi_wready;

    logic [                         1:0] s00_axi_bresp;
    logic                                s00_axi_bvalid;
    logic                                s00_axi_bready;

    logic [    C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [                         2:0] s00_axi_arprot;
    logic                                s00_axi_arvalid;
    logic                                s00_axi_arready;

    logic [    C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [                         1:0] s00_axi_rresp;
    logic                                s00_axi_rvalid;
    logic                                s00_axi_rready;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;

        output s00_axi_awaddr;
        output s00_axi_awprot;
        output s00_axi_awvalid;
        input s00_axi_awready;

        output s00_axi_wdata;
        output s00_axi_wstrb;
        output s00_axi_wvalid;
        input s00_axi_wready;

        input s00_axi_bresp;
        input s00_axi_bvalid;
        output s00_axi_bready;

        output s00_axi_araddr;
        output s00_axi_arprot;
        output s00_axi_arvalid;
        input s00_axi_arready;

        input s00_axi_rdata;
        input s00_axi_rresp;
        input s00_axi_rvalid;
        output s00_axi_rready;

        input sclk;
        input mosi;
        input cs_n;
        output miso;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;

        input s00_axi_awaddr;
        input s00_axi_awprot;
        input s00_axi_awvalid;
        input s00_axi_awready;

        input s00_axi_wdata;
        input s00_axi_wstrb;
        input s00_axi_wvalid;
        input s00_axi_wready;

        input s00_axi_bresp;
        input s00_axi_bvalid;
        input s00_axi_bready;

        input s00_axi_araddr;
        input s00_axi_arprot;
        input s00_axi_arvalid;
        input s00_axi_arready;

        input s00_axi_rdata;
        input s00_axi_rresp;
        input s00_axi_rvalid;
        input s00_axi_rready;

        input sclk;
        input mosi;
        input cs_n;
        input miso;
    endclocking

    task init();
        s00_axi_awaddr = '0;
        s00_axi_awprot = 3'b000;
        s00_axi_awvalid = 1'b0;

        s00_axi_wdata = '0;
        s00_axi_wstrb = 4'h0;
        s00_axi_wvalid = 1'b0;

        s00_axi_bready = 1'b0;

        s00_axi_araddr = '0;
        s00_axi_arprot = 3'b000;
        s00_axi_arvalid = 1'b0;

        s00_axi_rready = 1'b0;

        miso = 1'b0;
    endtask

endinterface

class spi_seq_item extends uvm_sequence_item;

    rand logic [7:0] tx_data;
    rand logic [5:0] clk_div;
    rand logic       cpol;
    rand logic       cpha;

    logic      [7:0] observed_mosi;

    constraint c_clk_div {clk_div inside {[6'd1 : 6'd63]};}

    constraint c_mode {
        cpol == 1'b0;
        cpha == 1'b0;
    }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(clk_div, UVM_ALL_ON)
        `uvm_field_int(cpol, UVM_ALL_ON)
        `uvm_field_int(cpha, UVM_ALL_ON)
        `uvm_field_int(observed_mosi, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "tx_data=0x%02h, observed_mosi=0x%02h, clk_div=%0d, cpol=%0b, cpha=%0b",
            tx_data,
            observed_mosi,
            clk_div,
            cpol,
            cpha
        );
    endfunction

endclass

class spi_rand_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_rand_seq)

    int num_trans = 10;

    function new(string name = "spi_rand_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info("SPI_RAND_SEQ", "Start SPI random sequence", UVM_LOW)
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

    localparam logic [3:0] CR_ADDR = 4'h0;
    localparam logic [3:0] CLKDIV_ADDR = 4'h4;
    localparam logic [3:0] TXDATA_ADDR = 4'h8;

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

        init_signals();

        wait (s_if.resetn == 1'b1);
        repeat (5) @(posedge s_if.clk);

        forever begin
            seq_item_port.get_next_item(item);

            drive_item(item);

            seq_item_port.item_done();
        end
    endtask


    task init_signals();
        s_if.s00_axi_awaddr = '0;
        s_if.s00_axi_awprot = 3'b000;
        s_if.s00_axi_awvalid = 1'b0;

        s_if.s00_axi_wdata = '0;
        s_if.s00_axi_wstrb = 4'h0;
        s_if.s00_axi_wvalid = 1'b0;

        s_if.s00_axi_bready = 1'b0;

        s_if.s00_axi_araddr = '0;
        s_if.s00_axi_arprot = 3'b000;
        s_if.s00_axi_arvalid = 1'b0;

        s_if.s00_axi_rready = 1'b0;

        s_if.miso = 1'b0;
    endtask


    task drive_item(spi_seq_item item);
        logic [31:0] ctrl;

        ctrl = 32'd0;
        ctrl[1] = item.cpol;
        ctrl[2] = item.cpha;

        `uvm_info(get_type_name(), $sformatf("[DRV] Drive item: %s",
                                             item.convert2string()), UVM_MEDIUM)

        axi_write(CLKDIV_ADDR, {26'd0, item.clk_div});
        axi_write(TXDATA_ADDR, {24'd0, item.tx_data});

        ctrl[0] = 1'b1;
        axi_write(CR_ADDR, ctrl);

        repeat (5) @(posedge s_if.clk);

        ctrl[0] = 1'b0;
        axi_write(CR_ADDR, ctrl);

        fork
            begin
                wait (s_if.cs_n == 1'b0);
                `uvm_info(get_type_name(), "[DRV] cs_n went LOW", UVM_MEDIUM)

                wait (s_if.cs_n == 1'b1);
                `uvm_info(get_type_name(),
                          "[DRV] cs_n went HIGH, SPI transfer completed",
                          UVM_MEDIUM)
            end
            begin
                repeat (10000) @(posedge s_if.clk);
                `uvm_error(get_type_name(),
                           "[DRV] TIMEOUT: cs_n did not toggle")
            end
        join_any
        disable fork;

        repeat (5) @(posedge s_if.clk);
    endtask


    task axi_write(input logic [3:0] addr, input logic [31:0] data);
        int timeout_cnt;

        `uvm_info(get_type_name(),
                  $sformatf("[AXI_WRITE_START] addr=0x%0h data=0x%08h", addr,
                            data), UVM_MEDIUM)

        @(posedge s_if.clk);

        s_if.s00_axi_awaddr  <= addr;
        s_if.s00_axi_awprot  <= 3'b000;
        s_if.s00_axi_awvalid <= 1'b1;

        s_if.s00_axi_wdata   <= data;
        s_if.s00_axi_wstrb   <= 4'hF;
        s_if.s00_axi_wvalid  <= 1'b1;

        s_if.s00_axi_bready  <= 1'b1;

        timeout_cnt = 0;
        while (!(s_if.s00_axi_awready && s_if.s00_axi_wready)) begin
            @(posedge s_if.clk);
            timeout_cnt++;

            if (timeout_cnt > 1000) begin
                `uvm_error(
                    get_type_name(),
                    $sformatf(
                        "[AXI_WRITE_TIMEOUT] AW/W handshake timeout addr=0x%0h data=0x%08h awready=%0b wready=%0b awvalid=%0b wvalid=%0b",
                        addr, data, s_if.s00_axi_awready, s_if.s00_axi_wready,
                        s_if.s00_axi_awvalid, s_if.s00_axi_wvalid))
                return;
            end
        end

        @(posedge s_if.clk);

        s_if.s00_axi_awvalid <= 1'b0;
        s_if.s00_axi_wvalid  <= 1'b0;

        timeout_cnt = 0;
        while (!s_if.s00_axi_bvalid) begin
            @(posedge s_if.clk);
            timeout_cnt++;

            if (timeout_cnt > 1000) begin
                `uvm_error(
                    get_type_name(),
                    $sformatf(
                        "[AXI_WRITE_TIMEOUT] BVALID timeout addr=0x%0h data=0x%08h bvalid=%0b bready=%0b",
                        addr, data, s_if.s00_axi_bvalid, s_if.s00_axi_bready))
                return;
            end
        end

        @(posedge s_if.clk);

        s_if.s00_axi_bready <= 1'b0;

        @(posedge s_if.clk);

        `uvm_info(get_type_name(),
                  $sformatf("[AXI_WRITE_DONE] addr=0x%0h data=0x%08h", addr,
                            data), UVM_MEDIUM)
    endtask

endclass

class spi_monitor extends uvm_monitor;

    `uvm_component_utils(spi_monitor)

    virtual spi_if s_if;

    uvm_analysis_port #(spi_seq_item) ap;

    localparam logic [3:0] CLKDIV_ADDR = 4'h4;
    localparam logic [3:0] TXDATA_ADDR = 4'h8;

    logic [7:0] expected_tx_q[$];
    logic [5:0] expected_clk_div_q[$];

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
        fork
            monitor_axi_write();
            monitor_spi_mosi();
        join
    endtask

    task monitor_axi_write();
        forever begin
            @(s_if.mon_cb);

            if (s_if.mon_cb.s00_axi_awvalid &&
                s_if.mon_cb.s00_axi_awready &&
                s_if.mon_cb.s00_axi_wvalid  &&
                s_if.mon_cb.s00_axi_wready) begin
                case (s_if.mon_cb.s00_axi_awaddr)
                    CLKDIV_ADDR: begin
                        expected_clk_div_q.push_back(
                            s_if.mon_cb.s00_axi_wdata[5:0]);
                        `uvm_info(get_type_name(), $sformatf(
                                  "[MON_AXI] captured clk_div=%0d",
                                  s_if.mon_cb.s00_axi_wdata[5:0]
                                  ), UVM_HIGH)
                    end
                    TXDATA_ADDR: begin
                        expected_tx_q.push_back(s_if.mon_cb.s00_axi_wdata[7:0]);

                        `uvm_info(get_type_name(), $sformatf(
                                  "[MON_AXI] captured tx_data=0x%02h",
                                  s_if.mon_cb.s00_axi_wdata[7:0]
                                  ), UVM_HIGH)
                    end
                    default: begin
                    end

                endcase
            end
        end
    endtask

    task monitor_spi_mosi();
        spi_seq_item item;
        logic [7:0] observed;

        forever begin
            wait (s_if.cs_n == 1'b0);

            observed = 8'h00;

            for (int i = 7; i >= 0; i--) begin
                @(posedge s_if.sclk);
                observed[i] = s_if.mosi;
            end

            wait (s_if.cs_n == 1'b1);

            item = spi_seq_item::type_id::create("item");

            if (expected_tx_q.size() > 0) begin
                item.tx_data = expected_tx_q.pop_front();
            end else begin
                item.tx_data = 8'hxx;
                `uvm_warning(get_type_name(),
                             "No expected tx_data found for observed MOSI")
            end

            if (expected_clk_div_q.size() > 0) begin
                item.clk_div = expected_clk_div_q.pop_front();
            end else begin
                item.clk_div = 6'hxx;
                `uvm_warning(get_type_name(),
                             "No expected clk_div found for observed MOSI")
            end

            item.cpol = 1'b0;
            item.cpha = 1'b0;

            item.observed_mosi = observed;

            `uvm_info(get_type_name(), $sformatf(
                      "[MON_SPI] observed_mosi=0x%02h expected=0x%02h clk_div=%0d",
                      item.observed_mosi,
                      item.tx_data,
                      item.clk_div
                      ), UVM_MEDIUM)

            ap.write(item);
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
        if (item.tx_data !== item.observed_mosi) begin
            fail_cnt++;
            `uvm_error(
                get_type_name(),
                $sformatf(
                    "[FAIL] MOSI mismatch expected=0x%02h observed=0x%02h",
                    item.tx_data, item.observed_mosi))
        end else begin
            pass_cnt++;
            `uvm_info(get_type_name(), $sformatf(
                      "[PASS] MOSI match expected=0x%02h observed=0x%02h",
                      item.tx_data,
                      item.observed_mosi
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
    logic [5:0] cov_clk_div;

    covergroup cg_spi;
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

        cp_clk_div: coverpoint cov_clk_div {
            bins fast = {[6'd1 : 6'd21]};
            bins mid = {[6'd22 : 6'd42]};
            bins slow = {[6'd43 : 6'd63]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_spi = new();
    endfunction

    function void write(spi_seq_item t);
        cov_tx_data = t.tx_data;
        cov_clk_div = t.clk_div;

        cg_spi.sample();
        `uvm_info(
            get_type_name(), $sformatf(
            "[COV] sample tx_data=0x%02h clk_div=%0d", cov_tx_data, cov_clk_div
            ), UVM_HIGH)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
                  "Coverage : cg_spi = %.1f%%", cg_spi.get_coverage()), UVM_LOW)
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

module tb_axi_spi_uvm;

    logic clk;
    logic resetn;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    initial begin
        resetn = 1'b0;
        repeat (5) @(posedge clk);
        resetn = 1'b1;
    end

    spi_if #(
        .C_S00_AXI_ADDR_WIDTH(4),
        .C_S00_AXI_DATA_WIDTH(32)
    ) s_if (
        .clk(clk),
        .resetn(resetn)
    );

    initial begin
        s_if.init();
    end

    SPI_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) dut (
        .sclk(s_if.sclk),
        .mosi(s_if.mosi),
        .cs_n(s_if.cs_n),
        .miso(s_if.miso),

        .s00_axi_aclk(clk),
        .s00_axi_aresetn(resetn),

        .s00_axi_awaddr (s_if.s00_axi_awaddr),
        .s00_axi_awprot (s_if.s00_axi_awprot),
        .s00_axi_awvalid(s_if.s00_axi_awvalid),
        .s00_axi_awready(s_if.s00_axi_awready),

        .s00_axi_wdata (s_if.s00_axi_wdata),
        .s00_axi_wstrb (s_if.s00_axi_wstrb),
        .s00_axi_wvalid(s_if.s00_axi_wvalid),
        .s00_axi_wready(s_if.s00_axi_wready),

        .s00_axi_bresp (s_if.s00_axi_bresp),
        .s00_axi_bvalid(s_if.s00_axi_bvalid),
        .s00_axi_bready(s_if.s00_axi_bready),

        .s00_axi_araddr (s_if.s00_axi_araddr),
        .s00_axi_arprot (s_if.s00_axi_arprot),
        .s00_axi_arvalid(s_if.s00_axi_arvalid),
        .s00_axi_arready(s_if.s00_axi_arready),

        .s00_axi_rdata (s_if.s00_axi_rdata),
        .s00_axi_rresp (s_if.s00_axi_rresp),
        .s00_axi_rvalid(s_if.s00_axi_rvalid),
        .s00_axi_rready(s_if.s00_axi_rready)
    );

    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "*", "s_if", s_if);
        run_test("spi_rand_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_axi_spi_uvm, "+all");
    end

endmodule
