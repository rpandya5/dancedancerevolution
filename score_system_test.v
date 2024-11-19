module score_system_test(
    input clock,                  // System clock (50MHz)
    input reset,                  // Global reset
    input game_active,           // Game state control
    input game_over,            // Game over signal
    
    // Player inputs
    input [3:0] a_input,         // Player A buttons
    input [3:0] b_input,         // Player B buttons
    
    // Test pattern inputs
    input [3:0] pattern_a,       // Expected pattern for player A
    input [3:0] pattern_b,       // Expected pattern for player B
    input pattern_valid,         // Pattern validity flag
    input [19:0] pattern_timer,  // Pattern timing counter
    
    // Score and winner outputs
    output [13:0] score_a,       // Player A score
    output [13:0] score_b,       // Player B score
    output [1:0] last_hit_a,     // Player A hit quality
    output [1:0] last_hit_b,     // Player B hit quality
    output [1:0] winner,         // Winner indicator
    output [13:0] final_score_a, // Final score A
    output [13:0] final_score_b  // Final score B
);

    // Internal wires for connecting modules
    wire [13:0] score_a_wire;
    wire [13:0] score_b_wire;

    // Instantiate score tracker
    score_tracker score_track (
        .clock(clock),
        .reset(reset),
        .game_active(game_active),
        .a_input(a_input),
        .b_input(b_input),
        .pattern_a(pattern_a),
        .pattern_b(pattern_b),
        .pattern_valid(pattern_valid),
        .pattern_timer(pattern_timer),
        .score_a(score_a_wire),
        .score_b(score_b_wire),
        .last_hit_a(last_hit_a),
        .last_hit_b(last_hit_b)
    );

    // Instantiate winner selector
    winner_selector winner_select (
        .clock(clock),
        .reset(reset),
        .game_over(game_over),
        .score_a(score_a_wire),
        .score_b(score_b_wire),
        .winner(winner),
        .final_score_a(final_score_a),
        .final_score_b(final_score_b)
    );

    // Connect score outputs to top level
    assign score_a = score_a_wire;
    assign score_b = score_b_wire;

endmodule