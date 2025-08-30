# SHA-1 Hardware Implementation (SystemVerilog)

This project provides a **SystemVerilog implementation of the SHA-1 cryptographic hash algorithm**, designed using a **finite state machine (FSM)** for control flow.  
It includes a **testbench** that simulates the SHA-1 core, converts input strings into 512-bit padded messages, and verifies hash computation.

---

## Project Structure
├── state_machine_definitions.sv &nbsp;# FSM state definitions<br>
├── sha_1.sv &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# SHA-1 core module<br>
├── sha_1_tb.sv &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# Testbench for simulation<br>


---

## Features
- **FSM-based design** with states: RESET, IDLE, PROC, DONE  
- **80-round computation** with SHA-1 round functions  
- **String-to-512-bit padded message conversion** for testbench input  
- **Cycle counter** for performance measurement  
- **Supports chaining with previous hash values**

---

## How to Run Simulation

1. Open your preferred Verilog/SystemVerilog simulator (e.g., ModelSim, Questa, VCS).  
2. Compile all files:
   ```bash
   vlog state_machine_definitions.sv sha_1.sv sha_1_tb.sv
3. Run simulation:
vsim sha_1_tb
run -all
