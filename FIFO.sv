module FIFO 
	(input logic clock, reset_n,
	input logic wr, rd,
	input logic [31:0] data_in, 
	output logic full, empty,
	output logic [31:0] data_out);

	logic [31:0] data_queue [3:0]; 
	logic [31:0] data_pkt;
	logic [1:0] wr_ptr, rd_ptr;
	logic [2:0] count;
	logic hazard, valid_rd, valid_wr;
	
	// Status signals
	assign hazard = (wr && full) || (rd && empty);
	assign valid_rd = rd && !empty;
	assign valid_wr = wr && !full;
	assign full = (count == 5);
	assign empty = (count == 0);
	
	assign data_out = (!hazard) ? data_pkt : 'z;
	
	// Write and Read Logic 
	always_ff @(posedge clock) begin
		if (!reset_n) begin
			data_pkt <= '0;
			rd_ptr <= '0;
			wr_ptr <= '0;
			count <= '0;
			data_queue <= '{default:'0};
		end else if (valid_wr) begin
			count <= count + 3'd1;
			if (empty) begin
				data_pkt <= data_in;
			end else begin
				data_queue[wr_ptr] <= data_in;
				wr_ptr <= wr_ptr + 2'd1;
			end
		end else if (valid_rd) begin 
			count <= count - 3'd1;
			if (!full) begin 
				rd_ptr <= rd_ptr + 2'd1;
				data_pkt <= data_queue[rd_ptr];
			end
		end
	end
	
endmodule : FIFO
