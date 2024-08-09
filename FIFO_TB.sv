
module FIFO_TB;
	logic clock, reset_n;
	logic wr, rd;
	logic [31:0] data_in;
	logic full, empty;
	logic [31:0] data_out;
	
	FIFO DUT (.*);
	
	/***** Testbench Local Variables *****/
	logic [31:0] data_stored[$];
	logic [31:0] expected;     
	int errors = 0;				 // Error count for all tests
	
	initial begin
		clock = 1;
		forever #5 clock = ~clock;
	end

	/*** Testbench Tasks ***/
	task reset_dut();
		$display("Resetting dut...");
		wr = 0;
		rd = 0;
		data_in = 0;
		reset_n = 0;
		#5;
		reset_n = 1;
		$display("Reset complete");
	endtask
	
	task writing_to_fifo(input logic [31:0] data);
		 $display("Writing to FIFO...");
		 $display("Data: %h", data); //////////////////////////////
		 assert (full === 1'b0)
		 else begin $error("Trying to input data to FIFO but full is %b!", full); errors++; end
		 data_in <= data;
		 wr <= 1;
		 @(posedge clock);
		 wr <= 0;
		 data_stored.push_back(data);
		 @(posedge clock);
	endtask
	
	task reading_from_fifo();
		 $display("Reading from FIFO...");
		 assert (empty === 1'b0)
		 else begin $error("Trying to read from FIFO but empty is %b!", empty); errors++; end
		 rd <= 1;
		 @(posedge clock);
		 rd <= 0;
		 @(posedge clock);
	endtask
	
	task basic_test(input int num_writes, input int num_reads);
		for (int index = 0; index < num_writes; index++) begin
			if (!full) begin 
				writing_to_fifo($random);
			end
		end
		
		for (int index = 0; index < num_reads; index++) begin 
			if (!empty) begin
				reading_from_fifo();
			end
		end 
	endtask 
	 
	task stress_test();
		int num_writes, num_reads;
		event write_complete; 
		
		fork
			forever begin
				num_writes = $urandom_range(1, 5);
			
				for (int i = 0; i < num_writes; i++) begin
					if (!full) begin
						writing_to_fifo($random);
					end
					#5;
				end
				-> write_complete; 
			end
				
			forever begin
				@write_complete;
				
				num_reads = $urandom_range(1, 5); 
				
				for (int i = 0; i < num_reads; i++) begin
					if (!empty) begin  
						reading_from_fifo();
					end
					#5;
				end	
			end
				
			join_none
			#200;  
		
		disable fork; 
		
		if (errors > 0) begin
		$display("Stress test failed with %0d errors", errors);
		end else begin
		$display("Stress test passed");
		end
	endtask
	
	/*** Monitors and compares FIFO Data Out with expected value ***/
	always @(posedge clock) begin
		if (rd === 1'b1) begin
			expected = data_stored.pop_front();
			@(posedge clock);
			assert (expected == data_out) $display("%x from data_out matched %x, Read Ptr: %d", expected, data_out, DUT.rd_ptr);
		else begin $error("Expected %x from data_out, got %x, Read Ptr: %d, Data Queue: %h", expected, data_out, DUT.rd_ptr, DUT.data_queue[0]); errors++; end
		end
	end
	
	initial begin 
		$display("*********************************************");
		$display("***        FIFO module testbench          ***");
		$display("***       Last Modified: 8/06/2024        ***");
		$display("*********************************************");
		
		reset_dut();
		
		basic_test(1, 1);
		basic_test(5, 1);
		basic_test(1, 5);
		
		$display("*********************************************");
		if (errors > 0) begin
			$display("***       Final error count: %1d            ***", errors);
			$display("***            TEST FAILED                ***");
		end else begin
			$display("***            TEST PASSED                ***");
		end
		$display("*********************************************");
	
		$finish;
	end

endmodule
