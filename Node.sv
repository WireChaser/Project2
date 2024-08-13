`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Node #(parameter NODEID = 0) (
	input wire clock, reset_n,
	
	//Interface to testbench: the blue arrows
	input  wire pkt_t pkt_in,        // Data packet from the TB
	input  wire pkt_in_avail,  // The packet from TB is available
	output logic cQ_full,       // The queue is full
	
	output pkt_t pkt_out,       // Outbound packet from node to TB
	output logic pkt_out_avail, // The outbound packet is available
	
	//Interface with the router: black arrows
	input  wire        free_outbound,    // Router is free
	output logic       put_outbound,     // Node is transferring to router
	output logic [7:0] payload_outbound, // Data sent from node to router
	
	output logic       free_inbound,     // Node is free
	input  wire       put_inbound,      // Router is transferring to node
	input  wire [7:0] payload_inbound); // Data sent from router to node
	
	logic [1:0] pkt_out_ptr, pkt_in_ptr; 
	logic [3:0] [7:0] data_pkt_in, data_pkt_out;
	logic empty, latched;
	logic [3:0] counter;
	logic read;
	
	assign read = free_outbound && !latched;
	
	FIFO FIFO_inst
		(.clock(clock), 
		.reset_n(reset_n),
		.wr(pkt_in_avail), 
		.rd(read),
		.data_in(pkt_in), 
		.full(cQ_full), 
		.empty(empty),
		.data_out(data_pkt_out));
		
	assign payload_outbound = data_pkt_out[pkt_out_ptr];
		
	// Node to Receiver Protocol 
	always_ff @(posedge clock) begin 
		if (!reset_n) begin
			put_outbound <= '0;
			pkt_out_ptr <= 2'd3;
			latched <= '0;
		end else if (latched || free_outbound) begin 
			latched <= 1'd1;
			put_outbound <= 1'd1;
			if (latched) begin pkt_out_ptr <= pkt_out_ptr - 2'd1; end
			if (pkt_out_ptr == 0) begin 
				pkt_out_ptr <= 2'd3;
				latched <= '0;
				put_outbound <= '0;
			end 
		end 
	end
	
	assign pkt_out = (pkt_out_avail) ? data_pkt_in : 'z;
	assign free_inbound = (!pkt_out_avail) ? '1 : '0;
	
	// Node to Testbench Protocol 
	always_ff @(posedge clock) begin 
		if (!reset_n) begin 
			pkt_out_avail 	<= '0;
			pkt_in_ptr <= 2'd3;
			data_pkt_in <= '0;
		end else if (free_inbound && put_inbound) begin 
			data_pkt_in[pkt_in_ptr] <= payload_inbound;
			if (pkt_in_ptr == 0) begin 
				pkt_in_ptr <= 2'd3;
				pkt_out_avail <= 1'd1;
			end else pkt_in_ptr <= pkt_in_ptr - 2'd1;
		end else if (pkt_out_avail) begin 
			pkt_out_avail <= '0;
		end
	end 

endmodule : Node

