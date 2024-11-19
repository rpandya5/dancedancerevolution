`timescale 1ns/1ps

module score_system_tb();
    // Test bench signals
    reg clock;
    reg reset;
    reg game_active;
    reg game_over;
    reg [3:0] a_input;
    reg [3:0] b_input;
    reg [3:0] pattern_a;
    reg [3:0] pattern_b;
    reg pattern_valid;
    reg [19:0] pattern_timer;

    // Output monitoring
    wire [13:0] score_a;
    wire [13:0] score_b;
    wire [1:0] last_hit_a;
    wire [1:0] last_hit_b;
    wire [1:0] winner;
    wire [13:0] final_score_a;
    wire [13:0] final_score_b;

    // Constants for timing windows (copied from score_tracker)
    localparam PERFECT_WINDOW = 20'd125_000;  // 2.5ms
    localparam GOOD_WINDOW    = 20'd250_000;  // 5ms
    localparam TOTAL_WINDOW   = 20'd500_000;  // 10ms

    // Point values (copied from score_tracker)
    localparam PERFECT_POINTS = 14'd10;
    localparam GOOD_POINTS    = 14'd5;
    localparam PENALTY_POINTS = 14'd5;

    // Button patterns
    localparam [3:0] UP    = 4'b0001;
    localparam [3:0] DOWN  = 4'b0010;
    localparam [3:0] LEFT  = 4'b0100;
    localparam [3:0] RIGHT = 4'b1000;
    localparam [3:0] NONE  = 4'b0000;

    // Instantiate the device under test (DUT)
    score_system_test dut(
        .clock(clock),
        .reset(reset),
        .game_active(game_active),
        .game_over(game_over),
        .a_input(a_input),
        .b_input(b_input),
        .pattern_a(pattern_a),
        .pattern_b(pattern_b),
        .pattern_valid(pattern_valid),
        .pattern_timer(pattern_timer),
        .score_a(score_a),
        .score_b(score_b),
        .last_hit_a(last_hit_a),
        .last_hit_b(last_hit_b),
        .winner(winner),
        .final_score_a(final_score_a),
        .final_score_b(final_score_b)
    );

    // Clock generation (50MHz = 20ns period)
    initial begin
        clock = 0;
        forever #10 clock = ~clock;  // Toggle every 10ns
    end

    // Main test sequence
    initial begin
        // Initialize waveform dump
        $dumpfile("score_system.vcd");
        $dumpvars(0, score_system_tb);

        // Initial values
        reset = 0;
        game_active = 0;
        game_over = 0;
        a_input = NONE;
        b_input = NONE;
        pattern_a = NONE;
        pattern_b = NONE;
        pattern_valid = 0;
        pattern_timer = 0;

        // Test 1: Reset Test
        $display("Test 1: Reset Behavior");
        #20 reset = 1;
        #40 reset = 0;
        #20;

        // Test 2: Perfect Hit Test for Player A
        $display("Test 2: Perfect Hit Test - Player A");
        game_active = 1;
        pattern_valid = 1;
        pattern_a = UP;
        pattern_b = DOWN;
        pattern_timer = 0;
        #40;  // Wait 2 clock cycles
        a_input = UP;  // Perfect hit for player A
        #20;  // One clock cycle for the hit to register
        a_input = NONE;
        #40;  // Wait for score update
        
        // Test 3: Good Hit Test for Player B
        $display("Test 3: Good Hit Test - Player B");
        pattern_timer = PERFECT_WINDOW + 1;  // Just outside perfect window
        #40;
        b_input = DOWN;  // Good hit for player B
        #20;
        b_input = NONE;
        #40;

        // Test 4: Miss Test
        $display("Test 4: Miss Test");
        pattern_timer = TOTAL_WINDOW + 1;  // Outside all windows
        #40;
        a_input = UP;
        b_input = DOWN;
        #20;
        a_input = NONE;
        b_input = NONE;
        #40;

        // Test 5: Wrong Button Test (Penalty)
        $display("Test 5: Wrong Button Test");
        pattern_timer = 20'd100_000;  // Within timing window
        pattern_a = UP;
        pattern_b = DOWN;
        #40;
        a_input = DOWN;  // Wrong button for pattern
        #20;
        a_input = NONE;
        #40;

        // Test 6: Game Over Test
        $display("Test 6: Game Over Test");
        game_over = 1;
        #100;  // Wait for winner selection
        
        // End simulation
        $display("All tests completed");
        #100 $finish;
    end

    // Monitor score changes
    always @(posedge clock) begin
        if (score_a !== 14'bx && score_b !== 14'bx) begin  // Valid scores
            if (last_hit_a == 2'b10)
                $display("Time %0t: Player A PERFECT hit! Score: %0d", $time, score_a);
            else if (last_hit_a == 2'b01)
                $display("Time %0t: Player A GOOD hit! Score: %0d", $time, score_a);
            else if (last_hit_a == 2'b00 && a_input != NONE)
                $display("Time %0t: Player A MISS! Score: %0d", $time, score_a);

            if (last_hit_b == 2'b10)
                $display("Time %0t: Player B PERFECT hit! Score: %0d", $time, score_b);
            else if (last_hit_b == 2'b01)
                $display("Time %0t: Player B GOOD hit! Score: %0d", $time, score_b);
            else if (last_hit_b == 2'b00 && b_input != NONE)
                $display("Time %0t: Player B MISS! Score: %0d", $time, score_b);
        end

        if (game_over && winner !== 2'b00) begin
            case(winner)
                2'b01: $display("Game Over - Player A wins! Final Scores: A=%0d, B=%0d", final_score_a, final_score_b);
                2'b10: $display("Game Over - Player B wins! Final Scores: A=%0d, B=%0d", final_score_a, final_score_b);
                2'b11: $display("Game Over - It's a tie! Final Scores: A=%0d, B=%0d", final_score_a, final_score_b);
            endcase
        end
    end

endmodule