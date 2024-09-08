`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Node #(parameter NODEID = 0) (
	input wire clock, reset_n,
	
	//Interface to testbench: the blue arrows
	input pkt_t pkt_in,        // Data packet from the TB
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
	
	logic [3:0][7:0] q_out;
	logic q_empty, q_ready, fifo_read;

	assign q_ready = ~q_empty;

	FIFO FIFO	(.clock(clock), 
					.reset_n(reset_n), 
					.data_in(pkt_in), 
					.we(pkt_in_avail), 
					.data_out(q_out),
					.re(fifo_read),
					.full(cQ_full), 
					.empty(q_empty));
					
  // Packet to Serial
  logic [3:0][7:0] buffer_in;
  logic [2:0] serial_ptr;

  always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
		buffer_in <= 0;
    end else begin 
		buffer_in <= (fifo_read) ? q_out : buffer_in;
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
			HOLD: state <= (q_ready) ? LOAD : HOLD;
			LOAD: state <= (free_outbound) ? SEND : LOAD;
			SEND: state <= (serial_ptr == 4) ? (q_ready) ? LOAD : HOLD : SEND;
		 endcase
	 end
  end
  
   always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			serial_ptr <= '0;
		end else if (serial_ptr == 4) begin 
			serial_ptr <= '0;
		end else if (state == SEND || (free_outbound && state == LOAD)) begin
			serial_ptr <= serial_ptr + 3'd1;
		end else begin
			serial_ptr <= '0;
		end
	end

  assign done = (state == SEND && serial_ptr == 4);
  assign put_outbound = (serial_ptr > 0);
  assign fifo_read = (state == HOLD || done);
									    
  // Serial to Packet
  logic [0:3][7:0] buffer_out;
  logic [2:0] pkt_ptr;

	always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			free_inbound <= '1;
			pkt_ptr <= '0;
			buffer_out <= '0;
		end else if (put_inbound) begin 
		   pkt_ptr <= pkt_ptr + 3'd1;
			buffer_out[pkt_ptr] <= payload_inbound;
			free_inbound <= ~put_inbound;
		end else begin
			pkt_ptr <= '0;
			buffer_out <= '0;
			free_inbound <= ~put_inbound;
		end
	end

  assign pkt_out = buffer_out;
  assign pkt_out_avail = (!free_inbound && !put_inbound);

endmodule






















