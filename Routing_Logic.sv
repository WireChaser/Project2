module Routing_Logic #(parameter ROUTERID = 0)(
  input logic clock, reset_n, 
  input logic [3:0] ready_to_recv,
  input logic [3:0] pkt_in_avail,
  input pkt_t [3:0] pkt_in,
  output logic [3:0] read_from_ib,
  output pkt_t [3:0] pkt_out,
  output logic [3:0] pkt_out_avail);
  
  // Intermediate Signals
  logic [3:0][3:0] pkt_accepted;
  logic [3:0][3:0] pkt_avail;
  logic [1:0] port_sel [3:0];
  pkt_t [3:0][3:0] pkt_q;
  
  typedef enum logic [3:0] {NODE0, NODE1, NODE2, NODE3, NODE4, NODE5} node_t;
  typedef enum logic [1:0] {PORT0, PORT1, PORT2, PORT3} port_t;
  
  pkt_t [3:0] pkts_sorted [3:0];
  logic [3:0] pkts_sorted_avail [3:0];
  logic [3:0] pkts_accepted [3:0];	 			
  
  always_comb begin
		pkt_q = '{default: '0};
		pkt_avail = '{default: '0};
		
		for (int i = 0; i < 4; i++) begin
			 // indicate whether the outbound buffer was full when we tried to send the last one
			 read_from_ib[i] = pkts_accepted[i][port_sel[i]] && pkt_in_avail[i];
			 
			 /*** Port Selection ***/
			 case(port_sel[i])
				PORT0: {pkt_q[0][i], pkt_avail[0][i]} = {pkt_in[i], pkt_in_avail[i]};
				PORT1: {pkt_q[1][i], pkt_avail[1][i]} = {pkt_in[i], pkt_in_avail[i]};
				PORT2: {pkt_q[2][i], pkt_avail[2][i]} = {pkt_in[i], pkt_in_avail[i]};
				PORT3: {pkt_q[3][i], pkt_avail[3][i]} = {pkt_in[i], pkt_in_avail[i]};
			 endcase
		end
  end
	
	
  always_comb begin
	 for (int i = 0; i < 4; i++) begin
		 pkts_accepted[i]		 = {pkt_accepted[3][i], pkt_accepted[2][i], pkt_accepted[1][i], pkt_accepted[0][i]}; 
		 pkts_sorted_avail[i] = {pkt_avail[3][i], pkt_avail[2][i],pkt_avail[1][i],pkt_avail[0][i]};
		 pkts_sorted[i]		 = {pkt_q[3][i], pkt_q[2][i], pkt_q[1][i], pkt_q[0][i]};
	  end
  end 
	
  logic [3:0][3:0] last_used;
  
  always_comb begin
	 pkt_out = '{default: '0};
	 for (int i = 0; i < 4; i++) begin 
		 if (!ready_to_recv) begin
			pkt_accepted[i] = '0;
			pkt_out_avail[i] = '0;
		 end else if (pkts_sorted_avail[0][i] == 1'b1 && !last_used[0][i]) begin
			pkt_out[i] = pkts_sorted[0][i];
			pkt_out_avail[i] = '1;
			pkt_accepted[i] = 4'b0001;
		 end else if (pkts_sorted_avail[1][i] == 1'b1 && !last_used[1][i]) begin
			pkt_out[i] = pkts_sorted[1][i];
			pkt_out_avail[i] = '1;
			pkt_accepted[i] = 4'b0010;
		 end else if (pkts_sorted_avail[2][i] == 1'b1 && !last_used[2][i]) begin
			pkt_out[i] = pkts_sorted[2][i];
			pkt_out_avail[i] = '1;
			pkt_accepted[i] = 4'b0100;
		 end else if (pkts_sorted_avail[3][i] == 1'b1 && !last_used[3][i]) begin
			pkt_out[i] = pkts_sorted[3][i];
			pkt_out_avail[i] = '1;
			pkt_accepted[i] = 4'b1000;
		 end else begin
			pkt_out[i] = '0;
			pkt_out_avail[i] = '0;
			pkt_accepted[i] = '0;
		 end 
	 end 
  end
  
  always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) last_used <= '0;
    else last_used <= {pkt_accepted[3], pkt_accepted[2], pkt_accepted[1], pkt_accepted[0]};
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