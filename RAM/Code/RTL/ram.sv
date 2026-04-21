
module ram(
	input logic clk,
	input logic wr,
	input logic [7:0] addr,
	input logic [15:0] wdata,
	output logic [15:0] rdata
);

	logic [15:0] mem[0:2**8-1];

	always_ff @(posedge clk)begin
		if(wr)begin
			mem[addr]<= wdata;
		end else begin
			rdata <= mem[addr];
		end
	end

endmodule
