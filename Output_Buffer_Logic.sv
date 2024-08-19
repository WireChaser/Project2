
`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Output_Buffer_Logic (
	input wire clock, reset_n,
	input wire input_buffer_loaded,
	input wire ready_to_receive,
	input wire [3:0][7:0] data_in,
	output logic data_routed,
	output logic data_transfer_out,
	output logic [7:0] output_buffer_data);
								
	logic [1:0] ptr;
	logic [3:0][7:0] output_buffer;
	logic buffer_ready;
	logic stop;
	
	always_ff @(posedge clock) begin 
		if (!reset_n) begin
			output_buffer <= '0;
			data_routed <= '0;
			buffer_ready <= '0;
		end else if (input_buffer_loaded) begin  
			output_buffer <= data_in;
			data_routed <= '1;
			buffer_ready <= '1;
		end else if (stop) begin 
			buffer_ready <= '0;
		end 
	end
	
	always_ff @(posedge clock) begin 
		if (!reset_n) begin
			output_buffer_data <= '0;
			data_transfer_out <= '0;
			ptr <= 2'd3;
			stop <= '0;
		end else if (buffer_ready && ready_to_receive) begin  
			data_transfer_out <= '1;
			output_buffer_data <= output_buffer[ptr];
			ptr <= ptr - 2'd1;
			if (ptr == 0) stop <= '1;
		end else if (stop) begin 
			data_transfer_out <= '0;
			stop <= '0;
		end 
	end 

endmodule
