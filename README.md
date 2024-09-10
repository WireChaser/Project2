# Network On Chip (NoC)
## Project Overview
This project implements a simple Network on Chip (NoC) in SystemVerilog. The NoC consists of interconnected routers and nodes, offering a more efficient alternative to traditional bus-based communication, especially for parallel message transfers.

Each component connects to a node, and communication occurs by sending packets through a series of routers to the destination node. The project involves designing logic for nodes and routers, while testbenches simulate components sending and receiving messages within the network.

**Specifics of the NoC Implementation:**

- **Topology:** The NoC comprises two routers (numbered 0 and 1) connected at four ports each. Each port can connect to another router or a node. The configuration includes six nodes (N0-N5) connected to the routers, with the routers also connected to each other.
- **Packet Structure:** Information is transmitted in 32-bit packets containing source and destination node IDs and 24 bits of data.
- **Communication Protocols:**
   - Testbench to Node: 32-bit transfers per clock cycle.
   - Node/Router to Node/Router: 8-bit transfers per clock cycle. Packets are disassembled into bytes for transmission and reassembled at the destination.
## Module Summaries
**Top**
1. Orchestrates the entire NoC simulation.
2. Instantiates routers, nodes, and a testbench.
3. Defines the network topology by connecting routers to each other and to nodes.
4. Manages data flow between nodes and routers, ensuring packets are routed correctly.
5. Provides clock and reset signals for simulation control.
      
**Router**        
1. Receives packets from nodes or other routers.
2. Makes routing decisions based on packet destinations and router configuration.
3. Forwards packets to the appropriate output port.
4. Employs input and output buffers for packet storage.      

**Routing_Logic**
1. Uses a static routing table based on the router's ID to determine output ports.
2. Handles contention between multiple packets destined for the same output port using a round-robin arbiter.
3. Implements a crossbar switch for flexible packet routing.    

**Input_Buffer_Logic**
1. Buffers incoming packets at a router's input ports.
2. Assembles serial data into packets.
3. Uses a FIFO to store assembled packets.

**Output_Buffer_Logic**
1. Buffers outgoing packets at a router's output ports.
2. Disassembles packets into serial data for transmission.
3. Employs a FIFO to queue packets for transmission.

**Node**
1. Represents an endpoint in the NoC 
2. Sends and receives packets.
3. Uses a FIFO to buffer incoming and outgoing packets.
4. Converts packets to/from serial data for communication with routers.

**FIFO**
1. Used for buffering packets within nodes and routers.
2. Supports write and read operations and provides full and empty status signals.

## Design Choices and Limitations
- **Conditional Round-Robin Arbitration:** The router employs a conditional round-robin arbitration scheme to handle port contention.
   - **Contention Resolution:** If multiple packets are destined for the same output port in a given cycle, the arbiter grants access to one packet, and the others are queued for subsequent cycles using a round-robin approach to ensure fairness
   - **No Contention Optimization:** If each of the four input ports has a packet destined for a different output port, the routing is performed instantly without arbitration, maximizing throughput in scenarios without contention.
   
## Design Issues and Optimization
**Issues:**
- **Router Port Awareness:** Initially, the router logic lacked inherent knowledge of its port numbers, making routing decisions challenging. This was addressed by creating a static  routing table for ports, enabling a single, generalized Router module.
- **Deadlock with Multiplexer-Based Switch:** The initial routing implementation using a multiplexer-based switch led to deadlocks due to difficulties in implementing an effective arbitration scheme.
- **Fairness and Starvation:** The use of four separate arbiters without coordination caused fairness issues and potential packet starvation.
- **Single Request Bottleneck:** The original arbitration scheme could create bottlenecks when only a single request was present.

**Solutions:**
- **Static Routing Table:** Implemented a static routing table to provide port awareness to the router logic, allowing for a single, reusable Router module.
- **Crossbar Switch:** Replaced the multiplexer-based switch with a crossbar switch, offering greater control over arbitration and resolving deadlock issues
- **Centralized Arbiter:** Introduced a central arbiter to coordinate between the four separate arbiters, ensuring fairness and preventing starvation.
- **Conditional Round-Robin Arbitration:** Modified the arbitration scheme to a conditional round-robin approach, where arbitration only occurs when there's contention for an output port, improving efficiency.

## Design Testing and Verification 
** **The testbenches listed here were adapted from the 18341 repository and were not written by me (see Acknowledgments).** **  

**Verification Methodology:** The project utilizes a combination of simulation and assertions to ensure the design meets its specifications. The testbenches include checks for packet integrity, correct routing, fairness, and performance.       

**NodeTB:**
- Tests an individual Node module in isolation.
- Simulates sending and receiving packets to/from the node, mimicking communication with a testbench and a router
- Verifies correct packet handling, data integrity, and adherence to communication protocols
- Includes checks for FIFO full status and proper handshaking signals.
  
**RouterTB:**
- Tests the entire NoC system with multiple nodes and routers.
- Includes various test scenarios like basic send/receive, across-router communication, broadcast concurrency, stress tests, and fairness checks.
- Monitors packet transmission and reception to ensure correctness and performance.
- Employs mailboxes and semaphores for inter-process synchronization and control
- Includes the following test scenarios:
  - BASIC: Transfers one packet at a time between every node pair within the same router
  - ACROSS: Transfers one packet at a time between every node pair across the router-to-router connection
  - BROADCAST: Tests concurrent packet transmission between node pairs within the same router to evaluate handling of simultaneous requests
  - STRESS_SRC: Stresses a single source node by having it send packets to all other destinations
  - STRESS_DEST: Stresses a single destination node by having all other nodes send packets to it
  - FAIRNESS: Checks for fairness in packet transmission across the router-to-router connection by sending multiple packets simultaneously and verifying balanced reception at the destination
  - PERFORMANCE: Measures the NoC's performance under real-world conditions by sending a large number of packets and tracking the cycle count

## Implementation Details and Results      
- **Simulation Environment:** Due to lack of access to the Synopsys VCS simulator, the RouterTB was simulated using EDA Playground, while the NodeTB was simulated using Modelsim
- **Test Results:** At the time of writing, the design has passed the following RouterTB tests: +BASIC, +ACROSS, +BROADCAST, +STRESS_SRC, and +FAIRNESS. However it failed the +STRESS_DEST and +PERFORMANCE tests

## Acknowledgments

This project was inspired by a project assignment in the Logic Design and Verification course at Carnegie Mellon University.  The original assignment provided the foundation for this implementation. All testbench files were from the 18341 repository and were slightly modified to use in EDA Playground.
Below are files from the 18341 repository that were used or modified for this project. 

Files used: NodeTB.sv RouterTB.sv Top.sv Router.svh RouterPkg.pkg                               
Files used and modified: Node.sv Router.sv 
