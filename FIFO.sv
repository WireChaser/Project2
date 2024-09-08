module FIFO #(parameter WIDTH = 32) ( 
  input wire clock, reset_n,          
  input wire [WIDTH-1:0] data_in,      // Data to be written into the FIFO
  input wire we,                       // Write enable signal
  input wire re,                       // Read enable signal
  output logic full,                   // Indicates if the FIFO is full
  output logic empty,                  // Indicates if the FIFO is empty
  output logic [WIDTH-1:0] data_out);  // Data read from the FIFO

  logic [3:0][WIDTH-1:0] queue;
  logic [1:0] w_ptr, r_ptr;
  logic [2:0] count;
  logic valid_re, valid_we, hazard;
  
  assign valid_re = re && !empty;
  assign valid_we = we && !full;
  
  // Hazard: simultaneous read and write when FIFO is not empty
  assign hazard = re && we && (count > 0);

  assign full = (count == 3'd4 && !re);
  assign empty = (count == 3'd0);
  
	always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin
			count <= 0; 
			w_ptr <= 0; 
			r_ptr <= 0; 
			queue <= 0;
		end else if (hazard) begin 
			// Handle simultaneous read and write
         queue[w_ptr] <= data_in;
         count <= count;
         w_ptr <= w_ptr + 2'd1;
         r_ptr <= r_ptr + 2'd1;
		end else if (valid_we) begin
        queue[w_ptr] <= data_in;
        count <= count + 2'd1;
        w_ptr <= w_ptr + 2'd1;
      end else if (valid_re) begin
        count <= count - 2'd1;
        r_ptr <= r_ptr + 2'd1;
      end
  end  
	
	// Output data is read from the current read pointer location
  assign data_out = queue[r_ptr];

endmodule
