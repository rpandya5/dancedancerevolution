module winner_selector (
    input clock,                   // System clock
    input reset,                   // Global reset
    input game_over,              // High when game ends (from controller)
    input [13:0] score_a,         // Player A's score (0-9999)
    input [13:0] score_b,         // Player B's score (0-9999)
    
    // Outputs for VGA display
    output reg [1:0] winner,      // 2'b00: no winner yet, 2'b01: A wins, 2'b10: B wins, 2'b11: tie
    output reg [13:0] final_score_a, // Final score for player A
    output reg [13:0] final_score_b  // Final score for player B
);

    // Internal state to ensure we only latch scores once when game ends
    reg scores_latched;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset all outputs and internal state
            winner <= 2'b00;
            final_score_a <= 14'd0;
            final_score_b <= 14'd0;
            scores_latched <= 1'b0;
        end
        else if (game_over && !scores_latched) begin
            // Latch the final scores
            final_score_a <= score_a;
            final_score_b <= score_b;
            
            // Determine winner
            if (score_a > score_b)
                winner <= 2'b01;      // Player A wins
            else if (score_b > score_a)
                winner <= 2'b10;      // Player B wins
            else
                winner <= 2'b11;      // Tie game
                
            scores_latched <= 1'b1;   // Prevent further updates until reset
        end
        else if (!game_over) begin
            // Reset latch when game isn't over (for next game)
            scores_latched <= 1'b0;
            winner <= 2'b00;          // Clear winner status
        end
    end

endmodule
