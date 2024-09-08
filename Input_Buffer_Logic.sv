module Input_Buffer_Logic (
    input logic clock, reset_n,
	 input logic recv_data, read_data,  	// Input data valid, read from FIFO
    input logic [7:0] payload,            // Serial input data (8 bits)
    output logic pkt_out_avail, full,     // Packet available in FIFO, FIFO full
    output pkt_t pkt_out);                // Output packet

    // Intermediate Signals
    pkt_t pkt;               			 // Assembled packet
    logic pkt_avail;        			 // Indicates a complete packet is ready
    logic q_empty, buffer_free;      // FIFO empty status, buffer free status

    // Serial to Packet assembly
    logic [0:3][7:0] buffer_out; // Buffer to store incoming serial data
    logic [2:0] pkt_ptr;        // Pointer to current position in buffer

    // Assemble incoming serial data into packets
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            buffer_free <= '1;   // Buffer is initially free
            pkt_ptr <= '0;      // Reset pointer
            buffer_out <= '0;   // Clear buffer
        end else if (recv_data) begin 
            pkt_ptr <= pkt_ptr + 3'd1;     // Increment pointer on valid input
            buffer_out[pkt_ptr] <= payload; // Store payload in buffer
            buffer_free <= ~recv_data;   // Buffer is not free while receiving data
        end else begin
            pkt_ptr <= '0;      						// Reset pointer when not receiving data
            buffer_out <= '0;   						// Clear buffer
            buffer_free <= ~recv_data;       // Buffer is free unless receiving data
        end
    end

    // Assign assembled packet and availability signal
    assign pkt = buffer_out;
    assign pkt_avail = (!buffer_free && !recv_data); // Packet is available when buffer is full and not receiving

    // Instantiate FIFO to store assembled packets
    FIFO queue (
        .clock(clock), 
        .reset_n(reset_n),
        .data_in(pkt), 
        .we(pkt_avail),   // Write to FIFO when packet is available
        .re(read_data),   // Read from FIFO when requested
        .full(full), 
        .empty(q_empty),
        .data_out(pkt_out));

    // Packet is available at output if FIFO is not empty
    assign pkt_out_avail = ~q_empty;

endmodule : Input_Buffer_Logic