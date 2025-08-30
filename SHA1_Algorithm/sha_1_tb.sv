`timescale 1ns/1ps

`define HALF_CLOCK_PERIOD   10
`define RESET_PERIOD        100
`define DELAY               200
`define SIM_DURATION        5000

module sha_1_tb();

    // Testbench parameters
    logic tb_local_clock = 0;
    logic tb_local_reset_n = 0;
    logic tb_q_start;
    logic tb_q_done;
    logic [511:0] tb_data;
    logic [159:0] tb_previous_hash;
    logic [159:0] tb_q;
    logic [1:0] tb_q_state;

    parameter INPUT_STRING = "FSOC24/25 is fun!";

    // Clock signal generation
    initial begin : clock_generation_process
        forever #`HALF_CLOCK_PERIOD tb_local_clock = ~tb_local_clock;
    end

    // Simulation start and reset
    initial begin : reset_generation_process
        $display ("Simulation starts ...");
        #`RESET_PERIOD tb_local_reset_n = 1'b1;
        tb_data = 0;
        tb_previous_hash = 160'h67452301EFCDAB8998BADCFE10325476C3D2E1F0;
        #200 tb_data = string_to_512bit(INPUT_STRING);
        #`SIM_DURATION
        $display ("Simulation done ...");
        $stop();
    end

    // Helper function: Convert string to 512-bit padded message
    function [511:0] string_to_512bit(input string str);
        integer i;
        reg [7:0] padded_message [0:63];
        reg [63:0] length_bits;
        reg [511:0] result;
        begin
            for (i = 0; i < 64; i++) padded_message[i] = 8'h00;
            for (i = 0; i < str.len(); i++) padded_message[i] = str[i];
            padded_message[str.len()] = 8'h80;
            length_bits = str.len() * 8;
            padded_message[56] = length_bits[63:56];
            padded_message[57] = length_bits[55:48];
            padded_message[58] = length_bits[47:40];
            padded_message[59] = length_bits[39:32];
            padded_message[60] = length_bits[31:24];
            padded_message[61] = length_bits[23:16];
            padded_message[62] = length_bits[15:8];
            padded_message[63] = length_bits[7:0];
            for (i = 0; i < 64; i++)
                result[511 - i * 8 -: 8] = padded_message[i];
            $display("Final 512-bit block: %h", result);
            return result;
        end
    endfunction

    // Start pulse generation using a counter
    logic [7:0] counter = 0;
    always_ff @(posedge tb_local_clock)
        counter <= counter + 1;

    logic tb_start;
    assign tb_start = (counter > 128) ? 1'b1 : 1'b0;

    // Instantiate the DUT (SHA-1 module)
    sha_1 dut (
        .clk(tb_local_clock),
        .reset_n(tb_local_reset_n),
        .start(tb_start),
        .q_start(tb_q_start),
        .q_done(tb_q_done),
        .data(tb_data),
        .previous_hash(tb_previous_hash),
        .q(tb_q),
        .done(tb_q_done),
        .q_state(tb_q_state)
    );

    // Cycle counter for performance measurement
    logic counting = 0;
    integer cycle_count = 0;

    always_ff @(posedge tb_local_clock) begin
        if (!tb_local_reset_n) begin
            counting <= 0;
            cycle_count <= 0;
        end else begin
            if (tb_q_start && !counting)
                counting <= 1;

            if (counting && !tb_q_done)
                cycle_count <= cycle_count + 1;

            if (tb_q_done && counting) begin
                counting <= 0;
                $display("SHA-1 computation completed in %0d cycles.", cycle_count);
            end
        end
    end

endmodule
