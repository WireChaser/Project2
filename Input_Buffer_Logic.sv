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

  FIFO queue (.clock(clock), 
			.reset_n(reset_n),
			.data_in(pkt), 
			.we(pkt_avail),
			.re(read), 
			.full(full), 
			.empty(q_empty),
			.data_out(pkt_out));

  assign pkt_out_avail = ~q_empty;

endmodule : Input_Buffer_Logic
