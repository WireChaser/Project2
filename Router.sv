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
  logic [3:0] ob_ready_to_recv;        // tell Routing_Logic outbuffer couldn't read
	 
  logic [3:0] ob_q_full, ib_q_full, read_from_ib;  

  genvar a;
  generate
    for (a = 0; a < 4; a++) begin: Input_Buffers
	  Input_Buffer_Logic ib (.clock				(clock), 
									.reset_n				(reset_n),
									.payload				(payload_inbound[a]),
									.put					(put_inbound[a]),
									.read					(read_from_ib[a]), 
									.pkt_out				(inbound_pkts[a]), 
									.pkt_out_avail		(inbound_pkts_avail[a]),
									.full					(ib_q_full[a]));
		
			always_comb begin
				free_inbound[a]	 =  ~ib_q_full[a];
			end
		end
	endgenerate 
	
	Routing_Logic #(ROUTERID) 
					rt (.clock						(clock), 
						.reset_n						(reset_n),
						.ob_ready_to_recv			   (ob_ready_to_recv),
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
										.read_from_ob					(free_outbound[b]));
										
			always_comb begin
				ob_ready_to_recv [b] =  ~ob_q_full[b];
			end
		end
	endgenerate 

endmodule : Router

 /*** Routing ***/
module Routing_Logic #(parameter ROUTERID = 0)(
  input logic clock, reset_n, 
  input logic [3:0] ob_ready_to_recv,
  input logic [3:0] pkt_in_avail,
  input pkt_t [3:0] pkt_in,
  output logic [3:0] read_from_ib,
  output pkt_t [3:0] pkt_out,
  output logic [3:0] pkt_out_avail);
  
  // Intermediate Signals
  logic pkt_accepted [3:0];
  logic [3:0][3:0] pkt_avail;
  logic [1:0] port_sel [3:0];
  logic [3:0] output_port_assigned; // Array to track if an output port has already been assigned in this cycle
  pkt_t [3:0][3:0] pkt_q;
  
  typedef enum logic [3:0] {NODE0, NODE1, NODE2, NODE3, NODE4, NODE5} node_t;
  typedef enum logic [1:0] {PORT0, PORT1, PORT2, PORT3} port_t;
  
  /*** Cross Bar Switch***/
  always_comb begin
    pkt_out = '{default: '0};
    pkt_out_avail = '{default: '0};
    pkt_accepted = '{default: '0};
    read_from_ib = '{default: '0};
	 output_port_assigned = '{default: '0};
	 
    for (int i = 0; i < 4; i++) begin 
        // Only proceed if the output port hasn't been assigned yet
        if (!output_port_assigned[port_sel[i]] && ob_ready_to_recv[port_sel[i]] && pkt_in_avail[i]) begin
            pkt_out[port_sel[i]]          = pkt_in[i];
            pkt_out_avail[port_sel[i]] = '1;
            pkt_accepted[i]           = '1;  // Accept the packet from the input port
            output_port_assigned[port_sel[i]] = '1;  // Mark the output port as assigned
        end 
        // Always update read_from_ib based on the current cycle's pkt_accepted
        read_from_ib[i] = pkt_accepted[i] && pkt_in_avail[i]; 
    end 
end
  
	// Routing Table based on ROUTERID
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

 /*** Recieves packets from a node, queues them, and passes queue ***/
module Input_Buffer_Logic (
  input logic clock, reset_n, put, read,
  input logic [7:0] payload,
  output logic pkt_out_avail, full,
  output pkt_t pkt_out);

  // output from serial to queue
  pkt_t pkt;
  logic pkt_avail;
  logic q_empty, free;

  // Serial to Packet
  logic [0:3][7:0] buffer_out;
  logic [2:0] pkt_ptr;

	always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			free <= '1;
			pkt_ptr <= '0;
			buffer_out <= '0;
		end else if (put) begin 
		   pkt_ptr <= pkt_ptr + 3'd1;
			buffer_out[pkt_ptr] <= payload;
			free <= ~put;
		end else begin
			pkt_ptr <= '0;
			buffer_out <= '0;
			free <= ~put;
		end
	end

  assign pkt = buffer_out;
  assign pkt_avail = (!free && !put);

  FIFO q 	(.clock(clock), 
				.reset_n(reset_n),
				.data_in(pkt), 
				.we(pkt_avail),
				.re(read), 
				.full(full), 
				.empty(q_empty),
				.data_out(pkt_out));

  assign pkt_out_avail = ~q_empty;

endmodule : Input_Buffer_Logic

 /*** Recieves packets from Routing_Logic, queues them, passes them on to node ***/
module Output_Buffer_Logic (
  input clock, reset_n, pkt_avail, read_from_ob,
  input pkt_t pkt,
  output [7:0] payload_outbound,
  output put_outbound, full);

  pkt_t pkt_out;
  logic read_in, q_empty, pkt_out_avail;
  assign pkt_out_avail = ~q_empty;

  FIFO q		(.clock(clock), 
				.reset_n(reset_n),
				.data_in(pkt), 
				.we(pkt_avail),
				.re(read_in), 
				.full(full), 
				.empty(q_empty),
				.data_out(pkt_out));
						 
  logic [2:0] serial_ptr;
  logic [3:0][7:0] buffer_in;
  
   always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		buffer_in <= 0;
    end else begin 
		buffer_in <= (read_in) ? pkt_out : buffer_in;
	 end 
  end

  assign payload_outbound = buffer_in[4 - serial_ptr];

  // Finite State Machine
  logic done;
  
  typedef enum logic [1:0] {HOLD, LOAD, SEND} state_t;
  state_t state;
  
  always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		state <= HOLD;
    end else begin 
		 case(state)
			HOLD: state <= (pkt_out_avail) ? LOAD : HOLD;
			LOAD: state <= (read_from_ob) ? SEND : LOAD;
			SEND: state <= (serial_ptr == 4) ? (pkt_out_avail) ? LOAD : HOLD : SEND;
		 endcase
	 end
  end
  
   always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			serial_ptr <= 0;
		end else if (serial_ptr == 4) begin 
			serial_ptr <= '0;
		end else if (state == SEND || (read_from_ob && state == LOAD)) begin
			serial_ptr <= serial_ptr + 3'd1;
		end else begin
			serial_ptr <= '0;
		end
	end

  assign done = (state == SEND && serial_ptr == 4);
  assign put_outbound = (serial_ptr > 0);
  assign read_in = (state == HOLD || done);
 
endmodule : Output_Buffer_Logic

/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
