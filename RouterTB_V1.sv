
`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module RouterTB_V1;
	logic             	clock, reset_n;
	
	logic [3:0]       	free_outbound;     // Node is free (4 signals)
	logic [3:0] 		   put_inbound;       // Node is transferring to router (4 signals)
	logic [3:0][7:0] 		payload_inbound;   // Data sent from node to router
	
	logic [3:0] 			free_inbound;      // Router is free (4 signals)
	logic [3:0] 			put_outbound;      // Router is transferring to node (4 signals)
	logic [3:0][7:0]		payload_outbound; // Data sent from router to node
	
	Router DUT (.*);
	
	int errors = 0; 
	
	// Testbench Queues
	logic [7:0] expect_router[$], expected;
	
	task reset_DUT ();
		$display("Resetting DUT...");
		reset_n = '0;
		free_outbound[2] = '0;
		put_inbound[0] = '0;
		payload_inbound[0] = '0;
		#5;
		reset_n = '1;
		$display("Reset complete"); 
	endtask 
	
	task send_To_Router (input pkt_t pkt);
		assert (free_inbound[0] == 1)
		else begin $error("Router input buffer not free!"); errors++; end
		put_inbound[0] <= '1;
	   free_outbound[2] <= '0;
		payload_inbound[0] <= {pkt.src, pkt.dest};
		expect_router.push_back({pkt.src, pkt.dest}); 
		@(posedge clock);
		payload_inbound[0] <= pkt.data[23:16];
		expect_router.push_back(pkt.data[23:16]); 
		@(posedge clock);
		payload_inbound[0] <= pkt.data[15:8];
		expect_router.push_back(pkt.data[15:8]); 
		@(posedge clock);
		payload_inbound[0] <= pkt.data[7:0];
		expect_router.push_back(pkt.data[7:0]); 
		@(posedge clock);
		put_inbound[0] <= '0;
		free_outbound[2] <= '1;
	endtask
	
	task read_Router_Data();
		repeat (5) begin 
			@(posedge clock);
		end 
		free_outbound[2] <= '0;
	endtask
	
	initial begin 
		clock = 1;
		forever #5 clock = ~clock;
	end
	
	always @(posedge clock) begin
		if (put_outbound[2] == 1'd1)  begin 
			expected = expect_router.pop_front();
			assert (expected == payload_outbound[2]) $display("%x from node interface, got %x", expected, payload_outbound[2]);
			else begin $error("Expected %x from node interface, got %x", expected, payload_outbound[2]); errors++; end
		end 
	end 
	
	initial begin 
		reset_DUT();
		send_To_Router(32'h01CADAEA);
		read_Router_Data();
		
		send_To_Router(32'h01CAACCA);
		read_Router_Data();
		
		send_To_Router(32'h01CADAEA);
		read_Router_Data();
		@(posedge clock);
		$display("*****************************************");

		if (errors > 0) begin
			$display("Final error count: %1d", errors);
			$display("TEST FAILED");
		end else begin 
			$display("TEST PASSED");
		end
		$finish;
	end 

endmodule 
