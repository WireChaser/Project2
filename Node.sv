`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Node #(parameter NODEID = 0) (
    input wire clock, reset_n,

    // Interface to Testbench (TB)
    input pkt_t pkt_in,          // Packet received from the TB
    input  wire pkt_in_avail,    // Indicates a valid packet is available from the TB
    output logic cQ_full,        // Indicates if the node's internal queue is full

    output pkt_t pkt_out,        // Packet sent to the TB
    output logic pkt_out_avail,  // Indicates a valid packet is available to be sent to the TB

    // Interface with the Router
    input  wire        free_outbound,    // Indicates the router is ready to receive a packet
    output logic       put_outbound,    // Indicates the node is sending a packet to the router
    output logic [7:0] payload_outbound, // Serialized payload data sent to the router

    output logic       free_inbound,    // Indicates the node is ready to receive a packet from the router
    input  wire       put_inbound,     // Indicates the router is sending a packet to the node
    input  wire [7:0] payload_inbound  // Serialized payload data received from the router
);

    // Internal Signals
    logic [3:0][7:0] q_out;       // Data output from the FIFO
    logic q_empty, q_ready, fifo_read; // FIFO empty status, FIFO ready status (not empty), FIFO read enable

    assign q_ready = ~q_empty;    // FIFO is ready if it's not empty

    // FIFO to buffer packets received from the TB
    FIFO FIFO ( 
        .clock(clock), 
        .reset_n(reset_n), 
        .data_in(pkt_in), 
        .we(pkt_in_avail),      // Write enable: when a packet is available from the TB
        .data_out(q_out),
        .re(fifo_read),          // Read enable: controlled by the node's state machine
        .full(cQ_full), 
        .empty(q_empty)
    );

    // Packet to Serial Conversion (for sending to the router)
    logic [3:0][7:0] buffer_in;     // Buffer to hold the packet being serialized
    logic [2:0] serial_ptr;        // Pointer for serializing packet data

    // Load packet from FIFO into buffer when `fifo_read` is asserted
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            buffer_in <= 0;
        end else begin 
            buffer_in <= (fifo_read) ? q_out : buffer_in;
        end 
    end

    // Serialize packet data based on `serial_ptr`
    assign payload_outbound = buffer_in[4 - serial_ptr];

    // Finite State Machine to control packet sending
    logic done;                                // Indicates completion of packet serialization

    typedef enum logic [1:0] {HOLD, LOAD, SEND} state_t;  
    // States: 
    // - HOLD: Wait for a packet in the FIFO and for the router to be ready
    // - LOAD: Load packet from FIFO into the buffer
    // - SEND: Serialize and send the packet to the router
    state_t state;

    // State transitions
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= HOLD;
        end else begin 
            case(state)
                HOLD: state <= (q_ready) ? LOAD : HOLD;          // If FIFO has a packet, go to LOAD state
                LOAD: state <= (free_outbound) ? SEND : LOAD;   // If router is ready, go to SEND state
                SEND: state <= (serial_ptr == 4) ? ((q_ready) ? LOAD : HOLD) : SEND; 
                // If serialization is done, go to LOAD if there's another packet, else go to HOLD. Otherwise, stay in SEND
            endcase
        end
    end

    // Control `serial_ptr` for serialization
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            serial_ptr <= '0;
        end else if (serial_ptr == 4) begin 
            serial_ptr <= '0;               // Reset pointer after serialization is complete
        end else if (state == SEND || (free_outbound && state == LOAD)) begin
            serial_ptr <= serial_ptr + 3'd1; // Increment pointer during serialization
        end else begin
            serial_ptr <= '0;
        end
    end

    // Output signals for packet sending
    assign done = (state == SEND && serial_ptr == 4);      // Serialization is done
    assign put_outbound = (serial_ptr > 0);                // Assert when serializing
    assign fifo_read = (state == HOLD || done);           // Read from FIFO in HOLD or after serialization is done

    // Serial to Packet Conversion (for receiving from the router)
    logic [0:3][7:0] buffer_out;    // Buffer to hold the received packet
    logic [2:0] pkt_ptr;           // Pointer for deserializing packet data

    // Deserializer: assemble incoming serial data into packets
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            free_inbound <= 1'b1;        // Node is initially ready to receive
            pkt_ptr <= '0;
            buffer_out <= '0;
        end else if (put_inbound) begin 
            pkt_ptr <= pkt_ptr + 3'd1;   // Increment pointer on valid input
            buffer_out[pkt_ptr] <= payload_inbound; // Store payload in buffer
            free_inbound <= ~put_inbound; // Node is not free while receiving data
        end else begin
            pkt_ptr <= '0;
            buffer_out <= '0;
            free_inbound <= ~put_inbound; // Node is free unless receiving data
        end
    end

    // Output signals for packet receiving
    assign pkt_out = buffer_out;                // Assembled packet
    assign pkt_out_avail = (!free_inbound && !put_inbound); // Packet is available when buffer is full and not receiving

endmodule : Node
