module FIFO #(parameter WIDTH = 32) (
  input wire clock, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire we, //write enable
  input wire re, //read enable
  output logic full, 
  output logic empty,
  output logic [WIDTH-1:0] data_out);

  logic [3:0][WIDTH-1:0] queue;
  logic [1:0] w_ptr, r_ptr;
  logic [2:0] count;
  logic valid_re, valid_we, hazard;
  
  assign valid_re = re && !empty;
  assign valid_we = we && !full;
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

  assign data_out = queue[r_ptr];

endmodule
