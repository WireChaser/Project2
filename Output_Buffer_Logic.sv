module Output_Buffer_Logic (
    input logic clock, reset_n,            
    input logic pkt_avail, read_from_ob,    // Packet available in FIFO, read enable from output buffer
    input pkt_t pkt,                        // Input packet
    output [7:0] payload_outbound,          // Serialized payload data to be sent out
    output put_outbound, full);             // Output buffer write enable, FIFO full status

    pkt_t pkt_out;                          // Packet read from FIFO
    logic read_in, q_empty, pkt_out_avail;  // FIFO read enable, FIFO empty status, packet available in FIFO
    assign pkt_out_avail = ~q_empty;        // Packet is available if FIFO is not empty

    // FIFO to buffer packets before serialization
    FIFO queue (
        .clock(clock), 
        .reset_n(reset_n),
        .data_in(pkt), 
        .we(pkt_avail),      // Write enable: write to FIFO when a new packet is available
        .re(read_in),        // Read enable: read from FIFO when serialization is in progress or buffer is empty
        .full(full), 
        .empty(q_empty),
        .data_out(pkt_out)
    );

    logic [2:0] serial_ptr;                 // Pointer for serializing packet data
    logic [3:0][7:0] buffer_in;             // Buffer to hold the packet being serialized

    // Load packet from FIFO into buffer when read_in is asserted
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            buffer_in <= 0;
        end else begin 
            buffer_in <= (read_in) ? pkt_out : buffer_in;
        end 
    end

    // Serialize packet data based on serial_ptr
    assign payload_outbound = buffer_in[4 - serial_ptr];

    logic done;  // Indicates completion of packet serialization                              

	 // States: HOLD (wait for packet), LOAD (load packet into buffer), SEND (serialize and send)
    typedef enum logic [1:0] {HOLD, LOAD, SEND} state_t;  
    state_t state;

    // State transitions
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= HOLD;
        end else begin 
            case(state)
					// Transition to LOAD if a packet is available in FIFO
                HOLD: state <= (pkt_out_avail) ? LOAD : HOLD;          
					 // Transition to SEND if output buffer is ready to read and we're in LOAD
                LOAD: state <= (read_from_ob) ? SEND : LOAD;          
					 // Transition to LOAD/HOLD if serialization is done, else stay in SEND
                SEND: state <= (serial_ptr == 4) ? ((pkt_out_avail) ? LOAD : HOLD) : SEND; 
            endcase
        end
    end

    // Control serial_ptr for serialization
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            serial_ptr <= 0;
        end else if (serial_ptr == 4) begin 
            serial_ptr <= '0;               // Reset pointer after serialization is complete
        end else if (state == SEND || (read_from_ob && state == LOAD)) begin
            serial_ptr <= serial_ptr + 3'd1; // Increment pointer during serialization
        end else begin
            serial_ptr <= '0;
        end
    end

    // Output signals
    assign done = (state == SEND && serial_ptr == 4);  // Serialization is done when in SEND state and pointer reaches the end
    assign put_outbound = (serial_ptr > 0);            // Assert put_outbound when serializing
    assign read_in = (state == HOLD || done);          // Read from FIFO when in HOLD state or serialization is done

endmodule : Output_Buffer_Logic