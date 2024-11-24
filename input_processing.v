// THIS IS RIGHT AND CORRECT. updated nov 11

module input_processing (
    input clock,              // clock
    input reset,             // single reset signal for both players
    
    // raw inputs (up,down,left,right)
    input [3:0] a_in,       // Player A raw inputs
    input [3:0] b_in,       // Player B raw inputs
    
    // cleaned outputs
    output reg [3:0] a_out,
    output reg [3:0] b_out,
    
    // LED indicators
    output reg [3:0] a_led,
    output reg [3:0] b_led
);
    // parameters
    parameter DB = 1_000_000;  // 20ms at 50MHz (50M * 0.02)
    
    // synchronizer registers for each player
    reg [3:0] a_sync1, a_sync2;  // Two flip-flops for player A
    reg [3:0] b_sync1, b_sync2;  // Two flip-flops for player B
    
    // debounce counters - one for each button
    reg [19:0] a_count [3:0];  // 20 bits for counting to 1M
    reg [19:0] b_count [3:0];
    
    // current button states
    reg [3:0] a_state;
    reg [3:0] b_state;
    
    // two-stage synchronizer
    always @(posedge clock) begin
        // Player A synchronizer
        a_sync1 <= a_in;
        a_sync2 <= a_sync1;
        
        // Player B synchronizer
        b_sync1 <= b_in;
        b_sync2 <= b_sync1;
    end
    
    // debouncing and output logic
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            // Reset player A
            a_out <= 4'b0;
            a_led <= 4'b0;
            a_state <= 4'b0;
            
            // Reset player B
            b_out <= 4'b0;
            b_led <= 4'b0;
            b_state <= 4'b0;
            
            // Reset all counters
            for (i = 0; i < 4; i = i + 1) begin
                a_count[i] <= 20'd0;
                b_count[i] <= 20'd0;
            end
        end
        else begin
            // Process Player A buttons
            for (i = 0; i < 4; i = i + 1) begin
                if (a_sync2[i] != a_state[i]) begin // Current state != previous state
                    if (a_count[i] < DB)
                        a_count[i] <= a_count[i] + 1'b1;
                    else begin // Button pressed for enough time
                        a_state[i] <= a_sync2[i];
                        a_out[i] <= a_sync2[i];
                        a_led[i] <= a_sync2[i];
                        a_count[i] <= 20'd0;
                    end
                end
                else
                    a_count[i] <= 20'd0;  // Reset counter, no change
            end
            
            // Process Player B buttons
            for (i = 0; i < 4; i = i + 1) begin
                if (b_sync2[i] != b_state[i]) begin // Current state != previous state
                    if (b_count[i] < DB)
                        b_count[i] <= b_count[i] + 1'b1;
                    else begin // Button pressed for enough time
                        b_state[i] <= b_sync2[i];
                        b_out[i] <= b_sync2[i];
                        b_led[i] <= b_sync2[i];
                        b_count[i] <= 20'd0;
                    end
                end
                else
                    b_count[i] <= 20'd0;  // Reset counter, no change
            end
        end
    end
endmodule
