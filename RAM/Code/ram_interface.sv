interface ram_if(input logic clk);
	logic wr;
	logic [7:0] addr;
	logic [15:0] wdata;
	logic [15:0] rdata;

	clocking drv_cb @(posedge clk);
		default output #0;
		 output wr;
		 output addr;
		 output wdata;
	endclocking

	clocking mon_cb @(posedge clk);
		default input #1step;
		 input wr;
		 input addr;
		 input wdata;
		 input rdata;
	endclocking

endinterface
