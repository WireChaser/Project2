
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
	
	logic [31:0] data_internal_transfer [3:0];
	logic [31:0] data_out_transfer [3:0];
	logic input_buffer_loaded, data_routed;
	
	assign free_inbound[0] = ~input_buffer_loaded;
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Input Buffer Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	Input_Buffer_Logic Port0_Input_Buffer (
		.clock(clock), 
		.reset_n(reset_n),
		.node_transfering(put_inbound[0]), 
		.data_routed(data_routed),			
		.data_in(payload_inbound[0]),
		.input_buffer_loaded(input_buffer_loaded),	
		.input_buffer_data(data_internal_transfer[0])
	);	
	
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Routing Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	Routing_Logic V1 (
		.data_in (data_internal_transfer[0]),
		.data_out (data_out_transfer)
	);
	
	/////////////////////////////////////////////////////////////////////////////////
	/////// Output Buffer Logic
	/////////////////////////////////////////////////////////////////////////////////
	
	Output_Buffer_Logic Port2_Output_Buffer (
		.clock(clock), 
		.reset_n(reset_n),
		.ready_to_receive(free_outbound[2]),
		.input_buffer_loaded(input_buffer_loaded),
		.data_in(data_out_transfer[2]),
		.data_routed(data_routed),
		.data_transfer_out(put_outbound[2]),
		.output_buffer_data(payload_outbound[2])
	);
	
	/////////////////////////////////////////////////////////////////////////////////
	
endmodule : Router
