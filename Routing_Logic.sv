`include "Router.svh"
`include "RouterPkg.pkg"

// This module implements a routing logic with a crossbar switch and round-robin arbiter 
// to manage packet switching between input and output ports. It includes conditional arbitration
// to optimize for low-traffic scenarios

module Routing_Logic #(parameter ROUTERID = 0)(
	 input logic clock, reset_n,
    input logic [3:0] ob_ready_to_recv, // Indicates if output buffers are ready to receive packets
    input logic [3:0] pkt_in_avail,     // Indicates if packets are available at input ports
    input pkt_t [3:0] pkt_in,           // Packets arriving at input ports
    output logic [3:0] read_from_ib,    // Signals to read from input buffers
    output pkt_t [3:0] pkt_out,         // Packets sent out from output ports
    output logic [3:0] pkt_out_avail);  // Indicates if packets are available at output ports
	
    // Intermediate Signals for Cross Bar Switch
	logic pkt_accepted [3:0];           // Array to track if a packet was accepted and routed
	logic [1:0] port_sel [3:0];
	logic port_assigned [3:0]; // Array to track if an output port has already been assigned in this cycle

	// Intermediate Signals for Arbiter
	logic [3:0][3:0] request;
	logic [3:0] grant;
   logic [5:0] num_requests;
	logic port_contention;

	typedef enum logic [3:0] {NODE0, NODE1, NODE2, NODE3, NODE4, NODE5} node_t;
	typedef enum logic [1:0] {PORT0, PORT1, PORT2, PORT3} port_t;

	/*** Cross Bar Switch***/
	always_comb begin
	pkt_out = '{default: '0};
	pkt_out_avail = '{default: '0};
	pkt_accepted = '{default: '0};
	read_from_ib = '{default: '0};
	port_assigned = '{default: '0};

	for (int i = 0; i < 4; i++) begin
		for (int j = 0; j < 4; j++) begin	// Tallies requests for all 4 input ports for each output port 
				request[i][j] = (port_sel[i] == j) && pkt_in_avail[i];	// Request made if output port (j) is selected
		end
		// Check if this input port has been granted access
      if (grant[i] || !port_contention) begin
			// Only proceed if the output port hasn't been assigned yet
			if (!port_assigned[port_sel[i]] && ob_ready_to_recv[port_sel[i]] && pkt_in_avail[i]) begin
				pkt_out[port_sel[i]] = pkt_in[i];
				pkt_out_avail[port_sel[i]] = 1'b1;
				pkt_accepted[i] = 1'b1;                    // Accept the packet from the input port
				port_assigned[port_sel[i]] = 1'b1;  // Mark the output port as assigned
			end
		end
			// Always update read_from_ib based on the current cycle's pkt_accepted
			read_from_ib[i] = pkt_accepted[i] && pkt_in_avail[i];
		end
	end
  
   /*** Checks for Contention based on requests ***/
  	always_comb begin
		 port_contention = '0; 
		 // Iterate over each Input Port
		 for (int j = 0; j < 4; j++) begin 
			  num_requests = '0;
			  // Iterate over each Output Port
			  for (int i = 0; i < 4; i++) begin 
					num_requests += request[i][j]; // Checks all
			  end
			  if (num_requests > 1) begin 
					port_contention = 1'b1; // Contention detected for this output port
			  end
		 end
	end

	/*** Round Robin Arbiter ***/
  typedef enum logic [3:0] {OUT0 = 4'b0001, OUT1 = 4'b0010, OUT2 = 4'b0100, OUT3 = 4'b1000} out_t;
	out_t current_grant;

	always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			grant <= '0;
			current_grant <= OUT0;
		end else if (port_contention) begin
			case (current_grant)
				OUT0: current_grant <= OUT1;
				OUT1: current_grant <= OUT2;
				OUT2: current_grant <= OUT3;
				OUT3: current_grant <= OUT0;
			endcase
			grant <= current_grant;
		end 
	end
									
	/*** Static Routing Table based on ROUTERID ***/
	always_comb begin
		if (ROUTERID[0] == 0) begin
		// Selector Array for Packet Destination
			for (int i = 0; i < 4; i++) begin
				case(pkt_in[i].dest)
					NODE0: port_sel[i] = PORT0;
					NODE1: port_sel[i] = PORT2;
					NODE2: port_sel[i] = PORT3;
					default: port_sel[i] = PORT1;
				endcase
			end
		end else begin
			// Selector Array for Packet Destination
			for (int i = 0; i < 4; i++) begin
				case(pkt_in[i].dest)
					NODE3: port_sel[i] = PORT0;
					NODE4: port_sel[i] = PORT1;
					NODE5: port_sel[i] = PORT2;
					default: port_sel[i] = PORT3;
				endcase
			end
		end
	end

endmodule : Routing_Logic
