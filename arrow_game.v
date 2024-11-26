module arrow_game(
    input CLOCK_50,
    input reset,
    input [3:0] player_a_keys,     // Player A inputs
    input [3:0] player_b_keys,     // Player B inputs
    input pattern_valid,
    input [7:0] pattern_out,
	 input game_over,
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
	 
	 reg [7:0] box_flash;
	 reg [19:0] flash_counter;
	 parameter FLASH_DURATION = 1000000;
    
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
		  box_flash = 8'b0;
		  flash_counter = 20'b0;
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
            arrow_x[1] <= 30;  // P1 Up
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
		  else if (!game_over)begin
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
								box_flash[i] <= 1;
								flash_counter <= 0;
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
								box_flash[i] <= 1;
								flash_counter <= 0;
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
				
				if (|box_flash) begin
					if (flash_counter >= FLASH_DURATION) begin
						box_flash <= 8'b0;
						flash_counter <= 0;
					end
					else begin
						flash_counter <= flash_counter + 1;
					end
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
		  
		  if (game_over) begin
            pixel_color = 3'b000;  // Black screen when game is over
        end
        else begin
        // Draw background colour
			pixel_color = 3'b000;  // Black background
			
        // Draw score boxes/target zones
        // Player 1 boxes
        for (i = 0; i < 4; i = i + 1) begin
            if (y_counter >= TARGET_Y - BOX_SIZE && y_counter < TARGET_Y + BOX_SIZE && x_counter >= (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) && x_counter < (P1_TARGET_X +(i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)) begin
                pixel_color = box_flash[i] ? 3'b111 : 3'b101;
            end
        end
        
        // Player 2 boxes
        for (i = 0; i < 4; i = i + 1) begin
            if (y_counter >= TARGET_Y - BOX_SIZE && y_counter < TARGET_Y + BOX_SIZE && 
                x_counter >= (P2_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) && 
                x_counter < (P2_TARGET_X + (i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)) begin
                pixel_color = box_flash[i+4] ? 3'b111 : 3'b101;
            end
        end
        
        // Draw all arrows
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