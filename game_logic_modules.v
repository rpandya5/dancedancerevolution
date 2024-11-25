//updated nov 25 at 4:47 pm -- COMPILED VERSION

module arrow_pattern_generator (
    input wire clock,                    
    input wire reset,                    
    input wire game_active,            
    output reg [7:0] pattern_out,     
    output reg pattern_valid           
);
    // Pattern definitions - 4'b(UDLR)
    localparam PATTERN_UP    = 4'b1000;
    localparam PATTERN_DOWN  = 4'b0100;
    localparam PATTERN_LEFT  = 4'b0010;
    localparam PATTERN_RIGHT = 4'b0001;
    
    // Valid pairs
    localparam PAIR_UP_DOWN   = 4'b1100;
    localparam PAIR_UP_LEFT   = 4'b1010;
    localparam PAIR_UP_RIGHT  = 4'b1001;
    localparam PAIR_DOWN_LEFT = 4'b0110;
    localparam PAIR_DOWN_RIGHT= 4'b0101;
    localparam PAIR_LEFT_RIGHT= 4'b0011;

    reg [15:0] lfsr;
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    reg [24:0] spawn_counter;
    localparam SPAWN_INTERVAL = 25000000;
    
    initial begin
        lfsr = 16'hACE1;
        pattern_valid = 0;
        pattern_out = 8'b0000;
        spawn_counter = 0;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            lfsr <= 16'hACE1;
            pattern_valid <= 0;
            pattern_out <= 8'b0000;
            spawn_counter <= 0;
        end 
        else begin
            if (game_active) begin
                if (spawn_counter >= SPAWN_INTERVAL) begin
                    spawn_counter <= 0;
                    lfsr <= {lfsr[14:0], feedback};
                    
                    case (lfsr[3:0])
                        4'b0000: pattern_out <= {PATTERN_UP, PATTERN_UP};
                        4'b0001: pattern_out <= {PATTERN_DOWN, PATTERN_DOWN};
                        4'b0010: pattern_out <= {PATTERN_LEFT, PATTERN_LEFT};
                        4'b0011: pattern_out <= {PATTERN_RIGHT, PATTERN_RIGHT};
                        4'b0100, 4'b0101: pattern_out <= {PAIR_UP_DOWN, PAIR_UP_DOWN};
                        4'b0110, 4'b0111: pattern_out <= {PAIR_UP_LEFT, PAIR_UP_LEFT};
                        4'b1000, 4'b1001: pattern_out <= {PAIR_UP_RIGHT, PAIR_UP_RIGHT};
                        4'b1010, 4'b1011: pattern_out <= {PAIR_DOWN_LEFT, PAIR_DOWN_LEFT};
                        4'b1100, 4'b1101: pattern_out <= {PAIR_DOWN_RIGHT, PAIR_DOWN_RIGHT};
                        4'b1110, 4'b1111: pattern_out <= {PAIR_LEFT_RIGHT, PAIR_LEFT_RIGHT};
                    endcase
                    
                    pattern_valid <= 1;
                end
                else begin
                    spawn_counter <= spawn_counter + 1;
                    pattern_valid <= 0;
                end
            end
            else begin
                pattern_valid <= 0;
                pattern_out <= 8'b0000;
                spawn_counter <= 0;
            end
        end
    end
endmodule

module score_tracker(
    input CLOCK_50,            // System clock
    input reset,               // Reset signal
    input [3:0] player_a_keys,     // Player A inputs
    input [3:0] player_b_keys,     // Player B inputs
    input perfect_hit_a,           // Perfect hit signal for player A
    input perfect_hit_b,           // Perfect hit signal for player B
    input game_active,             // Game is in active state
    input show_game_over,          // Game has ended
    output reg [6:0] HEX0,     // 7-segment display outputs
    output reg [6:0] HEX1,
    output reg [6:0] HEX2,
    output reg [6:0] HEX3,
    output reg player_a_won,    // Player A win signal
    output reg player_b_won     // Player B win signal
);
    // Internal score counters (0-99) for each player
    reg [7:0] score_a;
    reg [7:0] score_b;
    
    // 7-segment display patterns (active low)
    reg [6:0] seg7 [0:9];
    
    initial begin
        seg7[0] = 7'b1000000;  // 0
        seg7[1] = 7'b1111001;  // 1
        seg7[2] = 7'b0100100;  // 2
        seg7[3] = 7'b0110000;  // 3
        seg7[4] = 7'b0011001;  // 4
        seg7[5] = 7'b0010010;  // 5
        seg7[6] = 7'b0000010;  // 6
        seg7[7] = 7'b1111000;  // 7
        seg7[8] = 7'b0000000;  // 8
        seg7[9] = 7'b0010000;  // 9
        score_a = 8'd0;
        score_b = 8'd0;
        player_a_won = 1'b0;
        player_b_won = 1'b0;
    end
    
    // Edge detection for perfect_hit signals
    reg prev_perfect_hit_a, prev_perfect_hit_b;
    
    // Score update logic and winner determination
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            score_a <= 8'd0;
            score_b <= 8'd0;
            prev_perfect_hit_a <= 0;
            prev_perfect_hit_b <= 0;
            player_a_won <= 0;
            player_b_won <= 0;
        end 
        else if (game_active) begin
            // Player A score update
            prev_perfect_hit_a <= perfect_hit_a;
            if (perfect_hit_a && !prev_perfect_hit_a) begin
                if (score_a < 8'd99) begin
                    score_a <= score_a + 1'd1;
                end
            end
            
            // Player B score update
            prev_perfect_hit_b <= perfect_hit_b;
            if (perfect_hit_b && !prev_perfect_hit_b) begin
                if (score_b < 8'd99) begin
                    score_b <= score_b + 1'd1;
                end
            end
            
            // Clear win signals during gameplay
            player_a_won <= 0;
            player_b_won <= 0;
        end
        else if (show_game_over) begin
            // Determine winner when game ends
            if (score_a > score_b) begin
                player_a_won <= 1;
                player_b_won <= 0;
            end
            else if (score_b > score_a) begin
                player_a_won <= 0;
                player_b_won <= 1;
            end
            else begin
                player_a_won <= 0;  // Tie game - no winner
                player_b_won <= 0;
            end
        end
    end
	 
    // Display update logic
    always @(posedge CLOCK_50) begin
        // Update 7-segment displays
        HEX0 <= seg7[score_a % 10];       // Player A ones digit
        HEX1 <= seg7[score_a / 10];       // Player A tens digit
        HEX2 <= seg7[score_b % 10];       // Player B ones digit
        HEX3 <= seg7[score_b / 10];       // Player B tens digit
    end

endmodule

module arrow_game(
    input CLOCK_50,
    input reset,
    input [3:0] player_a_keys,     // Player A inputs
    input [3:0] player_b_keys,     // Player B inputs
    input pattern_valid,
    input [7:0] pattern_out,
	 input game_active,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output reg perfect_hit_a,      // Perfect hit for player A
    output reg perfect_hit_b       // Perfect hit for player B
);

    // Parameters for arrow dimensions and positions
    parameter ARROW_WIDTH = 7;    
    parameter ARROW_HEIGHT = 7;   
    parameter SCREEN_WIDTH = 160;
    parameter SCREEN_HEIGHT = 120;
    
    // Target zone parameters (score boxes)
    parameter P1_TARGET_X = 10;       // Player 1 score box x position
    parameter P2_TARGET_X = 90;       // Player 2 score box x position
    parameter TARGET_Y = SCREEN_HEIGHT - 30;          // Score box height
    parameter TARGET_WIDTH = 40;      // Score box width
    parameter HIT_RANGE = 10;         // How close to target counts as hit
    parameter BOX_SIZE = 11;          // Size of each individual box
    parameter BOX_SPACING = 7;        // Space between boxes
    
    // Arrow positions and states
    reg [7:0] arrow_x [7:0];        // X positions for all arrows
    reg [6:0] arrow_y [7:0];        // Y positions for all arrows
    reg [7:0] arrow_active;         // Active state for each arrow
    reg [19:0] move_counter;
    
    // X and Y counters for pixel position
    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [2:0] pixel_color;
    
    // Movement speed
    parameter MOVE_SPEED = 1000000;
    
    // Key press edge detection
    reg [3:0] prev_player_a_keys;
    reg [3:0] prev_player_b_keys;
    reg [7:0] in_target_zone;
    
    // Initialize all registers at declaration
    initial begin
        arrow_active = 8'b0;
        move_counter = 20'b0;
        perfect_hit_a = 1'b0;
        perfect_hit_b = 1'b0;
        prev_player_a_keys = 4'b0;
        prev_player_b_keys = 4'b0;
        in_target_zone = 8'b0;
        x_counter = 8'b0;
        y_counter = 7'b0;
    end

    // Counter for pixel position
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            x_counter <= 8'd0;
            y_counter <= 7'd0;
        end
        else begin
            if (x_counter == SCREEN_WIDTH-1) begin
                x_counter <= 0;
                if (y_counter == SCREEN_HEIGHT-1)
                    y_counter <= 0;
                else
                    y_counter <= y_counter + 1;
            end
            else begin
                x_counter <= x_counter + 1;
            end
        end
    end

    // Combined arrow movement, initialization, and game logic
    always @(posedge CLOCK_50 or posedge reset) begin
        integer i;  // Moved integer declaration to beginning of block
        
        if (reset) begin
            // Initialize X positions
            arrow_x[0] <= 12;  // P1 Left
            arrow_x[1] <= 29;  // P1 Up
            arrow_x[2] <= 48;  // P1 Right
            arrow_x[3] <= 66;  // P1 Down
            arrow_x[4] <= 92;  // P2 Left
            arrow_x[5] <= 110; // P2 Up
            arrow_x[6] <= 128; // P2 Right
            arrow_x[7] <= 146; // P2 Down
            
            // Reset game state
            move_counter <= 0;
            perfect_hit_a <= 0;
            perfect_hit_b <= 0;
            prev_player_a_keys <= 0;
            prev_player_b_keys <= 0;
            in_target_zone <= 0;
            arrow_active <= 0;
            
				//Reset Y positions
            for (i = 0; i < 8; i = i + 1) begin
                arrow_y[i] <= 0;
            end
        end
        else if (game_active) begin
            // Pattern processing
            if (pattern_valid) begin
            // Player A arrows (lower 4 bits)
            if (pattern_out[3]) begin  // Up arrow for Player A
                if (!arrow_active[1]) begin
                    arrow_active[1] <= 1;
                    arrow_y[1] <= 0;
                end
            end
            if (pattern_out[2]) begin  // Down arrow for Player A
                if (!arrow_active[3]) begin
                    arrow_active[3] <= 1;
                    arrow_y[3] <= 0;
                end
            end
            if (pattern_out[1]) begin  // Left arrow for Player A
                if (!arrow_active[0]) begin
                    arrow_active[0] <= 1;
                    arrow_y[0] <= 0;
                end
            end
            if (pattern_out[0]) begin  // Right arrow for Player A
                if (!arrow_active[2]) begin
                    arrow_active[2] <= 1;
                    arrow_y[2] <= 0;
                end
            end
            
            // Player B arrows (upper 4 bits)
            if (pattern_out[7]) begin  // Up arrow for Player B
                if (!arrow_active[5]) begin
                    arrow_active[5] <= 1;
                    arrow_y[5] <= 0;
                end
            end
            if (pattern_out[6]) begin  // Down arrow for Player B
                if (!arrow_active[7]) begin
                    arrow_active[7] <= 1;
                    arrow_y[7] <= 0;
                end
            end
            if (pattern_out[5]) begin  // Left arrow for Player B
                if (!arrow_active[4]) begin
                    arrow_active[4] <= 1;
                    arrow_y[4] <= 0;
                end
            end
            if (pattern_out[4]) begin  // Right arrow for Player B
                if (!arrow_active[6]) begin
                    arrow_active[6] <= 1;
                    arrow_y[6] <= 0;
                end
            end
				else begin  // When game is not active
					// Reset necessary values
					perfect_hit_a <= 0;
					perfect_hit_b <= 0;
					arrow_active <= 0;
					move_counter <= 0;
					for (i = 0; i < 8; i = i + 1) begin
						 arrow_y[i] <= 0;
					end
				end
        end
       
            // Update target zone status
            perfect_hit_a <= 0;
            perfect_hit_b <= 0;
            prev_player_a_keys <= player_a_keys;
            prev_player_b_keys <= player_b_keys;
            
            // Check for hits and update target zones
            // Check for hits - Player A
            for (i = 0; i < 4; i = i + 1) begin
                in_target_zone[i] <= (
                    arrow_y[i] >= (TARGET_Y - HIT_RANGE) && 
                    arrow_y[i] <= (TARGET_Y + HIT_RANGE) &&
                    arrow_x[i] >= (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) &&
                    arrow_x[i] < (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)
                );
                
                if (player_a_keys[i] && !prev_player_a_keys[i]) begin
                    if (arrow_active[i] && in_target_zone[i]) begin
                        perfect_hit_a <= 1;
                        arrow_active[i] <= 0;
                    end
                end
            end
            
            // Check for hits - Player B
            for (i = 4; i < 8; i = i + 1) begin
                in_target_zone[i] <= (
                    arrow_y[i] >= (TARGET_Y - HIT_RANGE) && 
                    arrow_y[i] <= (TARGET_Y + HIT_RANGE) &&
                    arrow_x[i] >= (P2_TARGET_X + ((i-4) * (BOX_SIZE + BOX_SPACING))) &&
                    arrow_x[i] < (P2_TARGET_X + ((i-4) * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)
                );
                
                if (player_b_keys[i-4] && !prev_player_b_keys[i-4]) begin
                    if (arrow_active[i] && in_target_zone[i]) begin
                        perfect_hit_b <= 1;
                        arrow_active[i] <= 0;
                    end
                end
            end

            // Move arrows
            if (move_counter >= MOVE_SPEED) begin
                move_counter <= 0;
                for (i = 0; i < 8; i = i + 1) begin
                    if (arrow_active[i]) begin
                        if (arrow_y[i] >= SCREEN_HEIGHT) begin
                            arrow_y[i] <= 0;
                            arrow_active[i] <= 0;
                        end
                        else begin
                            arrow_y[i] <= arrow_y[i] + 1;
                        end
                    end
                end
            end
            else begin
                move_counter <= move_counter + 1;
            end
        end
    end

    // Function to determine if current pixel is part of an arrow
    function is_arrow_pixel;
        input [7:0] x, arrow_x;
        input [6:0] y, arrow_y;
        input [1:0] direction; // 0=left, 1=up, 2=right, 3=down
        begin
            case (direction)
                0: begin // Left arrow
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_HEIGHT &&
                                    y >= arrow_y && y < arrow_y + ARROW_WIDTH &&
                                    ((y == arrow_y + 3) ||  // Horizontal shaft
                                     (x == arrow_x && y == arrow_y + 3) || // Left point
                                     (x == arrow_x + 1 && y >= arrow_y + 2 && y <= arrow_y + 4) ||
                                     (x == arrow_x + 2 && y >= arrow_y + 1 && y <= arrow_y + 5) ||
                                     (x >= arrow_x + 3 && x <= arrow_x + 6 && y == arrow_y + 3))); // Tail extension
                end
                
                1: begin // Up arrow
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_WIDTH &&
                                    y >= arrow_y && y < arrow_y + ARROW_HEIGHT &&
                                    ((x == arrow_x + 3) || // Shaft
                                     (y == arrow_y && x == arrow_x + 3) || // Top point
                                     (y == arrow_y + 1 && x >= arrow_x + 2 && x <= arrow_x + 4) ||
                                     (y == arrow_y + 2 && x >= arrow_x + 1 && x <= arrow_x + 5)));
                end
                
                2: begin // Right arrow
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_HEIGHT &&
                                    y >= arrow_y && y < arrow_y + ARROW_WIDTH &&
                                    ((y == arrow_y + 3) ||  // Horizontal shaft
                                     (x == arrow_x + 6 && y == arrow_y + 3) || // Right point
                                     (x == arrow_x + 5 && y >= arrow_y + 2 && y <= arrow_y + 4) ||
                                     (x == arrow_x + 4 && y >= arrow_y + 1 && y <= arrow_y + 5) ||
                                     (x >= arrow_x && x <= arrow_x + 3 && y == arrow_y + 3))); // Tail extension
                end
                
                3: begin // Down arrow
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_WIDTH &&
                                    y >= arrow_y && y < arrow_y + ARROW_HEIGHT &&
                                    ((x == arrow_x + 3) || // Shaft
                                     (y == arrow_y + ARROW_HEIGHT - 1 && x == arrow_x + 3) || // Bottom point
                                     (y == arrow_y + ARROW_HEIGHT - 2 && x >= arrow_x + 2 && x <= arrow_x + 4) ||
                                     (y == arrow_y + ARROW_HEIGHT - 3 && x >= arrow_x + 1 && x <= arrow_x + 5)));
                end
            endcase
        end
    endfunction

    // Color generation logic
    always @(*) begin
        integer i;  // Moved integer declaration to beginning of block
        
        // Draw background colour
        pixel_color = 3'b000;  // Black background
        
        // Draw score boxes/target zones
        // Player 1 boxes
        for (i = 0; i < 4; i = i + 1) begin
            if (y_counter >= TARGET_Y - BOX_SIZE && y_counter < TARGET_Y + BOX_SIZE && 
                x_counter >= (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) && 
                x_counter < (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)) begin
                pixel_color = 3'b101;  // magenta box
            end
        end
        
        // Player 2 boxes
        for (i = 0; i < 4; i = i + 1) begin
            if (y_counter >= TARGET_Y - BOX_SIZE && y_counter < TARGET_Y + BOX_SIZE && 
                x_counter >= (P2_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) && 
                x_counter < (P2_TARGET_X + (i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)) begin
                pixel_color = 3'b101;  // magenta box
            end
        end
        
        // Draw all arrows
		  // Only draw arrows when game is active
        if (game_active) begin
			  for (i = 0; i < 8; i = i + 1) begin
					if (arrow_active[i] && is_arrow_pixel(x_counter, arrow_x[i], y_counter, arrow_y[i], i[1:0])) begin
						 case(i % 4)  // Use same colors for both players' arrows
							  0: pixel_color = 3'b100; // left arrow red
							  1: pixel_color = 3'b110; // up arrow yellow
							  2: pixel_color = 3'b010; // right arrow green
							  3: pixel_color = 3'b011; // down arrow cyan
						 endcase
					end
			  end
		  end
    end
    
    // VGA adapter instantiation
    vga_adapter VGA(
        .resetn(!reset),
        .clock(CLOCK_50),
        .colour(pixel_color),
        .x(x_counter),
        .y(y_counter),
        .plot(1'b1),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
	 
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "gameplay.mif";

endmodule
