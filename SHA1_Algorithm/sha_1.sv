// state machine package definition
package state_machine_definitions;
	enum logic [1:0] {__RESET = 2'b00, __IDLE = 2'b01, __PROC = 2'b10, __DONE = 2'b11} state;
endpackage 



module sha_1 (
    input logic clk,							// Internal clock
    input logic reset_n,					// Internal reset
    input logic start,						// start signal
    output logic q_start,					// start trigger specifies when the computation needs to be started
    output logic q_done,					// done trigger specifies the computation is performed
    input logic [511:0] data,				// data to be hashed 512 bits
    input logic [159:0] previous_hash, // Optional, for chaining hashes
    output logic [159:0] q,				// Hash value
    output logic done, 
	 output logic [1:0] q_state			// State display
);
    
    import state_machine_definitions::*;
    
    // Initial Hash value stored in the local parameter
    localparam [31:0] H0_INIT = 32'h67452301;
    localparam [31:0] H1_INIT = 32'hEFCDAB89;
    localparam [31:0] H2_INIT = 32'h98BADCFE;
    localparam [31:0] H3_INIT = 32'h10325476;
    localparam [31:0] H4_INIT = 32'hC3D2E1F0;

    // Round constants stored in the local parameters
	 localparam [31:0] K0 = 32'h5A827999;
    localparam [31:0] K1 = 32'h6ED9EBA1;
    localparam [31:0] K2 = 32'h8F1BBCDC;
    localparam [31:0] K3 = 32'hCA62C1D6;

    // Internal registers
    logic [31:0] Hash [0:4]; 				// Register to store Hash 32bits of 5 words (ABCDE) 
    logic [31:0] Word [0:79]; 			// Register to store 32 bits of 80 words
    logic [31:0] A, B, C, D, E; 			// A,B,C,D, E are varibales used in function
    logic [31:0] Fun, K_reg; 				// Round-specific values
    logic [31:0] temp;						// temporarry variable used in A,B,C,D,E computation
  
    integer round;							// integer to monitor the counts
    
	 
	 // Rising edge detection logic, will assert a single pulse to start the computation 
	 logic [3:0] sync_reg = 0;
    always_ff@(posedge clk) 
		begin : start_detection
        if(reset_n == 1'b0)
            sync_reg <= 4'b0000;
        else
            sync_reg <= {sync_reg[2:0], start};
    end : start_detection
    
    logic sync_start; 
    assign sync_start = (sync_reg == 4'b0011) ? 1'b1 : 1'b0; 
    assign q_start = sync_start;
		
	// Round 1 function for rounds 0 to 19
	function [31:0] sha_round1(input logic [31:0]B, input logic [31:0]C, input logic [31:0]D);
		return  ((B & C) | (~B & D));
	endfunction
	// Round 2 function for rounds 20 to 39
	function [31:0] sha_round2(input logic [31:0]B, input logic [31:0]C, input logic [31:0]D);
		return  (B ^ C ^ D);
	endfunction
	// Round 3 function for rounds 40 to 59
	function [31:0] sha_round3(input logic [31:0]B, input logic [31:0]C, input logic [31:0]D);
		return  ((B & C) | (B & D) | (C & D));
	endfunction
	// Round 4 function for rounds 60 to 79
	function [31:0] sha_round4(input logic [31:0]B, input logic [31:0]C, input logic [31:0]D);
		return  (B ^ C ^ D);
	endfunction
    
	 
	 // Initialization of state and registers
	 // Start of the state machine
    always_ff @(posedge clk) 
		begin: state_machine
        if(reset_n == 1'b0) 
				begin
					$display("RESET: I am currently in RESET and state machine is OFF");
					state <= __RESET;
					Hash[0] <= H0_INIT;
					Hash[1] <= H1_INIT;
					Hash[2] <= H2_INIT;
					Hash[3] <= H3_INIT;
					Hash[4] <= H4_INIT;
					q<={160{1'b0}};
				end 
			else 
				begin
					case (state)
						__RESET: 
								begin
									$display("RESET: I am in State machine RESET after reset asserted");
									Hash[0] <= H0_INIT;
									Hash[1] <= H1_INIT;
									Hash[2] <= H2_INIT;
									Hash[3] <= H3_INIT;
									Hash[4] <= H4_INIT;
									state <= __IDLE;
								end
                __IDLE: 
								begin
									$display("IDLE: I am in State machine IDLE");
									A <= Hash[0];
									B <= Hash[1];
									C <= Hash[2];
									D <= Hash[3];
									E <= Hash[4];
									// Extracting the words from the data
									// W0 to W15 is calculated below
									for (round = 0; round < 16; round = round + 1) 
										begin
											Word[round] <= data[511 - round*32 -: 32];
										end
									// W16 to W79 is calculated here
									for (round = 16; round < 80; round = round + 1) 
										begin
											Word[round] <= ((Word[round - 3] ^ Word[round - 8] ^ Word[round - 14] ^ Word[round - 16]) << 1) | ((Word[round - 3] ^ Word[round - 8] ^ Word[round - 14] ^ Word[round - 16]) >> 31);
										end
									round <= 0;
									// Verify and move to PROC if trigger is asserted
									if(sync_start) 
											state <= __PROC;
									$display("IDLE: Got the trigger and moving to PROC state.");
									end

                __PROC: 
								begin
									$display("PROC: I am here in PROC state and computing the round operations");
									// Performing 80 rounds of computation
									// using the blocking statements as we donot need the 80 rotations to happen in parallel
									if (round < 80) 
										begin
											if (round < 20) 
												begin
													Fun = sha_round1(B,C,D);
													K_reg = K0;
												end 
											else if (round < 40) 
												begin
													Fun = sha_round2(B,C,D);
													K_reg = K1;
												end 
											else if (round < 60) 
												begin
													Fun = sha_round3(B,C,D);
													K_reg = K2;
												end 
											else 
												begin
													Fun = sha_round4(B,C,D);
													K_reg = K3;
												end

												temp = ((A << 5) | (A >> 27)) + Fun + E + K_reg + Word[round];
												E = D;
												D = C;
												C = (B << 30) | (B >> 2);
												B = A;
												A = temp;
												round = round + 1;
											end 
										// Move to state Done after 80 round operations
										else 
												begin
													state <= __DONE;
													$display("PROC: Completed all rounds, transitioning to DONE.");
												end
									end
							__DONE: 
									begin
										$display("DONE: I am in Done and initializing the final HASH value");
										Hash[0] = Hash[0] + A;
										Hash[1] = Hash[1] + B;
										Hash[2] = Hash[2] + C;
										Hash[3] = Hash[3] + D;
										Hash[4] = Hash[4] + E;
										// Assign the final HASH to q
										q <= {Hash[0], Hash[1], Hash[2], Hash[3], Hash[4]};
										done <= 1'b1;  // Set the done signal
										$monitor("DONE: Final hash: %h", q);
										state <= __RESET;  // Go back to reset state
										$display("DONE: Returning to RESET state.");
									end
							default:
								begin
									state 		  <= __RESET;
								end
            endcase	
        end
		end: state_machine
		
		// assert q_done once all states are executed
		assign q_done = (state == __DONE) ? 1'b1 : 1'b0;
		
		// assign q_state output
		assign q_state   = state;

endmodule