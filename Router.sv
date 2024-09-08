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

  // Intermediate Signals 
  pkt_t [3:0] outbound_pkts;         // Outbound Packets 
  logic [3:0] outbound_pkts_avail;	 // Availability of Outbound Packets 
  pkt_t [3:0] inbound_pkts;          // Inbound Packets 
  logic [3:0] inbound_pkts_avail;	 // Availability of Inbound Packets
  logic [3:0] ob_ready_to_recv;      // Output Buffer is ready to receive packets
  logic [3:0] ob_q_full, ib_q_full, read_from_ib;  

  genvar a;
  generate
    for (a = 0; a < 4; a++) begin: Input_Buffers
	  Input_Buffer_Logic ib (.clock				(clock), 
									.reset_n				(reset_n),
									.payload				(payload_inbound[a]),
									.recv_data  		(put_inbound[a]),
									.read_data			(read_from_ib[a]), 
									.pkt_out				(inbound_pkts[a]), 
									.pkt_out_avail		(inbound_pkts_avail[a]),
									.full					(ib_q_full[a]));
		
			always_comb begin
				// Router ready to receive if input buffers are not full
				free_inbound[a]	 =  ~ib_q_full[a];	
			end
		end
	endgenerate 
	
	Routing_Logic #(ROUTERID) 
					rt (.clock						(clock), 
						.reset_n						(reset_n),
						.ob_ready_to_recv			(ob_ready_to_recv),
						.pkt_in						(inbound_pkts), 
						.pkt_in_avail				(inbound_pkts_avail),
						.read_from_ib				(read_from_ib),
						.pkt_out						(outbound_pkts), 
						.pkt_out_avail				(outbound_pkts_avail));
						
  genvar b;
  generate
    for (b = 0; b < 4; b++) begin: Output_Buffers
	  Output_Buffer_Logic ob 	(.clock				(clock), 
										.reset_n				(reset_n),
										.pkt					(outbound_pkts[b]),
										.pkt_avail			(outbound_pkts_avail[b]),
										.payload_outbound	(payload_outbound[b]), 
										.put_outbound		(put_outbound[b]),
										.full					(ob_q_full[b]), 
										.read_from_ob		(free_outbound[b]));
										
			always_comb begin
				// Output buffers are ready to receive if its buffers are not full
				ob_ready_to_recv [b] =  ~ob_q_full[b];
			end
		end
	endgenerate 

endmodule : Router
