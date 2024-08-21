
`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Router #(parameter ROUTERID = 0) (
	input wire             	clock, reset_n,
	
	input wire [3:0]       		free_outbound,     // Node is free (4 signals)
	input wire [3:0] 		   	put_inbound,       // Node is transferring to router (4 signals)
	input wire [3:0][7:0] 		payload_inbound,   // Data sent from node to router
	
	output logic [3:0] 			free_inbound,      // Router is free (4 signals)
	output logic [3:0] 			put_outbound,      // Router is transferring to node (4 signals)
	output logic [3:0][7:0]		payload_outbound); // Data sent from router to node
	
	logic [31:0] data_to_routing [3:0];
	logic [31:0] data_from_routing [3:0];
	logic data_ready_in [3:0];
	logic data_ready_out [3:0];
	logic data_routed_in [3:0];
	logic data_routed_out [3:0];
	
	assign free_inbound[0] = ~data_ready_in[0];
	assign free_inbound[1] = ~data_ready_in[1];
	assign free_inbound[2] = ~data_ready_in[2];
	assign free_inbound[3] = ~data_ready_in[3];
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Input Buffer Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	genvar a;
	generate 
		for (a = 0; a < 4; a++) begin: generate_input_buffers
			Input_Buffer_Logic Input_Buffer (
				.clock					(clock), 
				.reset_n					(reset_n),
				.node_transfering		(put_inbound[a]), 	
				.data_routed			(data_routed_out[a]),			
				.data_in					(payload_inbound[a]), 
				.data_ready				(data_ready_in[a]),	
				.data_out				(data_to_routing[a])	 
			);		
		end
	endgenerate 
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Routing Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	Routing_Logic V1 (
		.clock					(clock),
		.reset_n					(reset_n),
		.data_in 		  		(data_to_routing),
		.data_routed_in  		(data_routed_in),
		.data_ready_in  		(data_ready_in),
		.data_out 		  		(data_from_routing),
		.data_routed_out 		(data_routed_out),
		.data_ready_out 		(data_ready_out)
	);
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Output Buffer Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	genvar b;
	generate
		for (b = 0; b < 4; b++) begin: generate_output_buffer
			Output_Buffer_Logic Output_Buffer (
				.clock						(clock), 
				.reset_n						(reset_n),
				.ready_to_receive			(free_outbound[b]),		  // Leave alone
				.input_buffer_loaded		(data_ready_out[b]),
				.data_in						(data_from_routing[b]),
				.data_routed				(data_routed_in[b]),
				.data_transfer_out		(put_outbound[b]),		  // Leave alone
				.output_buffer_data		(payload_outbound[b])	  // Leave alone
			);
		end
	endgenerate
	
	/////////////////////////////////////////////////////////////////////////////////
	
endmodule : Router
