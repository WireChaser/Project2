module Output_Buffer_Logic (
  input clock, reset_n, pkt_avail, read_from_ob,
  input pkt_t pkt,
  output [7:0] payload_outbound,
  output put_outbound, full);

  pkt_t pkt_out;
  logic read_in, q_empty, pkt_out_avail;
  assign pkt_out_avail = ~q_empty;

  FIFO queue	(.clock(clock), 
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
