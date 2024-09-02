`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Router #(parameter ROUTERID = 0) (
	input wire           	  	clock, reset_n,
	
	input wire [3:0]       		free_outbound,     // Node is free (4 signals)
	input wire [3:0] 		   	put_inbound,       // Node is transferring to router (4 signals)
	input wire [3:0][7:0] 		payload_inbound,   // Data sent from node to router
	
	output logic [3:0] 			free_inbound,      // Router is free (4 signals)
	output logic [3:0] 			put_outbound,      // Router is transferring to node (4 signals)
	output logic [3:0][7:0]		payload_outbound); // Data sent from router to node

  // internal data
  pkt_t [3:0] outbound_pkts;         // from Output_Buffer_Logic, to node
  logic [3:0] outbound_pkts_avail;
  pkt_t [3:0] inbound_pkts;          // from node, to channel_sel
  logic [3:0] inbound_pkts_avail;
  logic [3:0] ready_to_recv;        // tell Routing_Logic outbuffer couldn't read
	 
  logic [3:0] ob_q_full, ib_q_full, read_from_ib;  

  genvar a;
  generate
    for (a = 0; a < 4; a++) begin: Input_Buffers
	  Input_Buffer_Logic ib (.clock		    (clock), 
							.reset_n		(reset_n),
							.payload		(payload_inbound[a]),
							.put			(put_inbound[a]),
							.read			(read_from_ib[a]), 
							.pkt_out		(inbound_pkts[a]), 
							.pkt_out_avail	(inbound_pkts_avail[a]),
							.full			(ib_q_full[a]));
		
			always_comb begin
				free_inbound[a]	 =  ~ib_q_full[a];
			end
		end
	endgenerate 
	
	Routing_Logic #(ROUTERID) 
					rt (.clock				(clock), 
						.reset_n			(reset_n),
						.ready_to_recv	    (ready_to_recv),
						.pkt_in				(inbound_pkts), 
						.pkt_in_avail		(inbound_pkts_avail),
						.read_from_ib		(read_from_ib),
						.pkt_out			(outbound_pkts), 
						.pkt_out_avail		(outbound_pkts_avail));
						
  genvar b;
  generate
    for (b = 0; b < 4; b++) begin: Output_Buffers
	  Output_Buffer_Logic ob 	(.clock				(clock), 
								.reset_n			(reset_n),
								.pkt				(outbound_pkts[b]),
								.pkt_avail			(outbound_pkts_avail[b]),
								.payload_outbound	(payload_outbound[b]), 
								.put_outbound		(put_outbound[b]),
								.full				(ob_q_full[b]), 
								.read_from_ob		(free_outbound[b]));
										
			always_comb begin
				ready_to_recv [b] =  ~ob_q_full[b];
			end
		end
	endgenerate 

endmodule : Router





