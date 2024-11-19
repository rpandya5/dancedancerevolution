module score_tracker (
    input clock,                  // 50MHz clock
    input reset,                  // Global reset
    input game_active,           // From controller - true when game is running
    
    // Player inputs (from input_processing module)
    input [3:0] a_input,         // Player A inputs (up,down,left,right)
    input [3:0] b_input,         // Player B inputs
    
    // Current arrow pattern to match
    input [3:0] pattern_a,       // Current expected pattern for player A
    input [3:0] pattern_b,       // Current expected pattern for player B
    input pattern_valid,         // True when there's a valid pattern to match
    
    // Timing input (from pattern generator/controller)
    input [19:0] pattern_timer,  // Time since current pattern appeared
    
    // Score outputs
    output reg [13:0] score_a,   // Player A score (0-9999)
    output reg [13:0] score_b,   // Player B score
    output reg [1:0] last_hit_a, // 2'b00: miss, 2'b01: good, 2'b10: perfect
    output reg [1:0] last_hit_b
);

    // Timing parameters (in clock cycles at 50MHz)
    parameter PERFECT_WINDOW = 20'd125_000;  // 2.5ms for perfect hit
    parameter GOOD_WINDOW    = 20'd250_000;  // 5ms for good hit
    parameter TOTAL_WINDOW   = 20'd500_000;  // 10ms total window

    // Point values
    parameter PERFECT_POINTS = 14'd10;
    parameter GOOD_POINTS    = 14'd5;
    parameter PENALTY_POINTS = 14'd5;

    // Previous input states for edge detection
    reg [3:0] prev_a_input, prev_b_input;
    
    // Score calculation logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset all scores and states
            score_a <= 14'd0;
            score_b <= 14'd0;
            last_hit_a <= 2'b00;
            last_hit_b <= 2'b00;
            prev_a_input <= 4'b0;
            prev_b_input <= 4'b0;
        end
        else if (game_active) begin
            // Store previous inputs for edge detection
            prev_a_input <= a_input;
            prev_b_input <= b_input;
            
            // Process Player A input
            if ((a_input != prev_a_input) && pattern_valid) begin
                // New button press detected
                if (pattern_timer <= PERFECT_WINDOW && a_input == pattern_a) begin
                    // Perfect hit
                    score_a <= score_a + PERFECT_POINTS;
                    last_hit_a <= 2'b10;
                end
                else if (pattern_timer <= GOOD_WINDOW && a_input == pattern_a) begin
                    // Good hit
                    score_a <= score_a + GOOD_POINTS;
                    last_hit_a <= 2'b01;
                end
                else if (pattern_timer <= TOTAL_WINDOW) begin
                    if (a_input != pattern_a && |a_input) begin
                        // Wrong button within window - penalty
                        if (score_a >= PENALTY_POINTS)
                            score_a <= score_a - PENALTY_POINTS;
                        last_hit_a <= 2'b00;
                    end
                end
            end
            
            // Process Player B input (similar logic)
            if ((b_input != prev_b_input) && pattern_valid) begin
                if (pattern_timer <= PERFECT_WINDOW && b_input == pattern_b) begin
                    score_b <= score_b + PERFECT_POINTS;
                    last_hit_b <= 2'b10;
                end
                else if (pattern_timer <= GOOD_WINDOW && b_input == pattern_b) begin
                    score_b <= score_b + GOOD_POINTS;
                    last_hit_b <= 2'b01;
                end
                else if (pattern_timer <= TOTAL_WINDOW) begin
                    if (b_input != pattern_b && |b_input) begin
                        if (score_b >= PENALTY_POINTS)
                            score_b <= score_b - PENALTY_POINTS;
                        last_hit_b <= 2'b00;
                    end
                end
            end
            
            // Reset hit indicators when pattern window expires
            if (pattern_timer > TOTAL_WINDOW) begin
                last_hit_a <= 2'b00;  // Clear player A hit status
                last_hit_b <= 2'b00;  // Clear player B hit status
                // No penalty for misses, only wrong hits are penalized
            end
        end
    end

endmodule
