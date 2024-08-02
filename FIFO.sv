/*  
 *  Create a FIFO (First In First Out) buffer with depth 4 using the given
 *  interface and constraints
 *    - The buffer is initally empty
 *    - Reads are combinational, so data_out is valid unless empty is asserted
 *    - Removal from the queue is processed on the clock edge.
 *    - Writes are processed on the clock edge
 *    - If a write is pending while the buffer is full, do nothing
 *    - If a read is pending while the buffer is empty, do nothing
 */
module FIFO 
	(input logic clock, reset_n,
	input logic wr, rd,
	input logic [31:0] data_in, 
	output logic full, empty,
	output logic [31:0] data_out);

	logic [31:0] data_queue [3:0]; 
	logic [31:0] data_pkt;
	logic [1:0] wr_ptr, rd_ptr;
	logic pkt_empty, hazard, valid_rd, valid_wr;
	
	// Status signals
	assign full  = (wr_ptr == 3 && rd_ptr == 0) || (wr_ptr + 1'd1 == rd_ptr);
	assign empty = (wr_ptr == rd_ptr);	// No more valid data to read in between pointers
	
	assign pkt_empty = wr && empty;
	assign hazard = (wr && full) || (rd && empty);
	assign data_out = (!hazard) ? data_pkt : 'z;
	
	assign valid_rd = !pkt_empty && rd && !empty;
	assign valid_wr = !pkt_empty && wr && !full;
	
	// Data Pkt Logic 
	always_ff @(posedge clock) begin
		if (!reset_n) begin
			data_pkt <= '0;
			data_queue[0] <= '0;
			data_queue[1] <= '0;
			data_queue[2] <= '0;
			data_queue[3] <= '0;
		end else if (pkt_empty) begin		// Stuck in infinte loop
			data_pkt <= data_in;
		end else if (valid_wr) begin
			data_queue[wr_ptr] <= data_in;
		end else if (valid_rd) begin 
			data_pkt <= data_queue[rd_ptr];
		end 
	end
	
	// Write Pointer Logic 
	always_ff @(posedge clock) begin
		if (!reset_n) begin
			wr_ptr <= 0;
		end else if (valid_wr) begin // Only write if not full
			data_queue[wr_ptr] <= data_in;
			if (wr_ptr == 3) wr_ptr <= 0;
         else wr_ptr <= wr_ptr + 2'd1; 
		end
	end
	
	// Read Pointer Logic 
	always_ff @(posedge clock) begin
		if (!reset_n) begin
			rd_ptr <= 0;
		end else if (valid_rd) begin // Only read if not empty
			if (rd_ptr == 3) rd_ptr <= 0;
         else rd_ptr <= rd_ptr + 2'd1; 
		end
	end	
	
endmodule : FIFO
