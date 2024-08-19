`default_nettype none
`include "Router.svh"
`include "RouterPkg.pkg"

module Routing_Logic (
    input pkt_t data_in,
    output pkt_t data_out [3:0]);

    typedef enum logic [3:0] {NODE0, NODE1, NODE2, NODE3, NODE4, NODE5} node_t;

    always_comb begin 
        // Default assignments to prevent latches
        data_out[0] = '0;
        data_out[1] = '0;
        data_out[2] = '0;
        data_out[3] = '0;

        case (data_in.dest)    
        NODE0: data_out[0] = data_in;
        NODE1: data_out[2] = data_in;
        NODE2: data_out[3] = data_in;
        default: data_out[1] = data_in;
        endcase
    end 
	 
	 // Include Routing table Here
	 // Also import ROUTERID for routing table

endmodule
