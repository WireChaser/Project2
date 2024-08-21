`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Input_Buffer_Logic (
	input wire clock, reset_n,
	input wire data_routed,
	input wire node_transfering,
	input wire [7:0] data_in,
	output logic data_ready,
	output logic [3:0][7:0] data_out);
								
	logic [1:0] ptr;
	
	always_ff @(posedge clock) begin 
		if (!reset_n) begin
			data_ready <= '0;
			data_out <= '0;
			ptr <= 2'd3;
		end else if (node_transfering) begin
			data_out[ptr] <= data_in;
			ptr <= ptr - 2'd1;
			if (ptr == 0) data_ready <= '1;
		end else if (data_routed) begin 
			data_ready <= '0;
		end 
	end 

endmodule
