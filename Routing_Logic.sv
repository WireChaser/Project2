`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Routing_Logic (
	input wire clock, reset_n,
	input pkt_t data_in [3:0],
	input wire data_ready_in [3:0],
	input wire data_routed_in [3:0],
	output pkt_t data_out [3:0],
	output logic data_ready_out [3:0],
	output logic data_routed_out [3:0]);
	
	typedef enum logic [3:0] {NODE0, NODE1, NODE2, NODE3, NODE4, NODE5} node_t;
	typedef enum logic [1:0] {PORT0, PORT1, PORT2, PORT3} port_t;
	
	logic [1:0] port_sel [3:0];
	
	always_comb begin
		data_out = '{default: '0};
		data_routed_out = '{default: '0};
		data_ready_out = '{default: '0};
		
		for (int i = 0; i < 4; i++) begin
			case(port_sel[i])
				PORT0:	data_out[0] = data_in[i];
				PORT1:	data_out[1] = data_in[i];
				PORT2:	data_out[2] = data_in[i];
				PORT3:	data_out[3] = data_in[i];
			endcase
		end
		
		for (int i = 0; i < 4; i++) begin
			case(port_sel[i])
				PORT0:	data_ready_out[0] = data_ready_in[i];
				PORT1:	data_ready_out[1] = data_ready_in[i];
				PORT2:	data_ready_out[2] = data_ready_in[i];
				PORT3:	data_ready_out[3] = data_ready_in[i];
			endcase
		end
		
		for (int i = 0; i < 4; i++) begin
			case(port_sel[i])
				PORT0:	data_routed_out[i] = data_routed_in[0];
				PORT1:	data_routed_out[i] = data_routed_in[1];
				PORT2:	data_routed_out[i] = data_routed_in[2];
				PORT3:	data_routed_out[i] = data_routed_in[3];
			endcase
		end

	end
	
	// Selector Array for Packet Destination 
	// Include Routing table Here
	// Also import ROUTERID for routing table
	always_comb begin
		for (int i = 0; i < 4; i++) begin
			case (data_in[i].dest)
			NODE0: port_sel[i] = PORT0;
			NODE1: port_sel[i] = PORT2;
			NODE2: port_sel[i] = PORT3;
			NODE3: port_sel[i] = PORT1;
			NODE4: port_sel[i] = PORT1;
			NODE5: port_sel[i] = PORT1;
			default: port_sel[i] = PORT0;
			endcase
		end
	end

endmodule
