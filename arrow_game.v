//FINAL CODE - edited 9:46 AM

module arrow_game(
    input CLOCK_50,
    input reset,
    input [3:0] player_a_keys,
    input [3:0] player_b_keys,
    input pattern_valid, //checks if new pattern is ready
    input [7:0] pattern_out, //current arrow pattern
	 input game_over,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    output reg perfect_hit_a,
    output reg perfect_hit_b
);
	 
	 //arrow dimensions
    parameter ARROW_WIDTH = 7;    
    parameter ARROW_HEIGHT = 7;   
    parameter SCREEN_WIDTH = 160;
    parameter SCREEN_HEIGHT = 120;
    
	 //target boxes
    parameter P1_TARGET_X = 10; //p1 target box X
    parameter P2_TARGET_X = 90; //p2 target box X
    parameter TARGET_Y = SCREEN_HEIGHT - 30; //height of target box
    parameter TARGET_WIDTH = 40;
    parameter HIT_RANGE = 10; //how close to target counts as hit
    parameter BOX_SIZE = 11; //size of each target box
    parameter BOX_SPACING = 7; //spacing between targets
    
    reg [7:0] arrow_x [7:0]; //x position
    reg [6:0] arrow_y [7:0]; //y position
    reg [7:0] arrow_active; //current arrows on screen
    reg [19:0] move_counter; //arrow speed controller
	 
	 //flash feature
	 reg [7:0] box_flash;
	 reg [19:0] flash_counter;
	 parameter FLASH_DURATION = 1000000; //length of flash on hit
    
    reg [7:0] x_counter;
    reg [6:0] y_counter;
    reg [2:0] pixel_color;
    
    parameter MOVE_SPEED = 1000000;
    
    reg [3:0] prev_player_a_keys;
    reg [3:0] prev_player_b_keys;
    reg [7:0] in_target_zone;
    
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
	
	 //checking bounds of screen
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

    always @(posedge CLOCK_50 or posedge reset) begin
        integer i;
        
        if (reset) begin
            //initializing x positions
            arrow_x[0] <= 12; //left p1
            arrow_x[1] <= 30; //up p1
            arrow_x[2] <= 48; //right p1
            arrow_x[3] <= 66; //down p1
            arrow_x[4] <= 92; //left p2
            arrow_x[5] <= 110; //up p2
            arrow_x[6] <= 128; //right p2
            arrow_x[7] <= 146; //down p2
            
            //reset game state
            move_counter <= 0;
            perfect_hit_a <= 0;
            perfect_hit_b <= 0;
            prev_player_a_keys <= 0;
            prev_player_b_keys <= 0;
            in_target_zone <= 0;
            arrow_active <= 0;
            
				//reset y positions
            for (i = 0; i < 8; i = i + 1) begin
                arrow_y[i] <= 0;
            end
        end
		  else if (!game_over)begin
            if (pattern_valid) begin //new pattern from pattern generator
            if (pattern_out[3]) begin //player A up arrow
                if (!arrow_active[1]) begin //if no up arrow already active
                    arrow_active[1] <= 1; //activate up arrow
                    arrow_y[1] <= 0; //start at top of screen
                end
            end
            if (pattern_out[2]) begin //player A down arrow
                if (!arrow_active[3]) begin
                    arrow_active[3] <= 1;
                    arrow_y[3] <= 0;
                end
            end
            if (pattern_out[1]) begin //player A left arrow
                if (!arrow_active[0]) begin
                    arrow_active[0] <= 1;
                    arrow_y[0] <= 0;
                end
            end
            if (pattern_out[0]) begin //player A right arrow
                if (!arrow_active[2]) begin
                    arrow_active[2] <= 1;
                    arrow_y[2] <= 0;
                end
            end
            
            if (pattern_out[7]) begin //player B up arrow
                if (!arrow_active[5]) begin
                    arrow_active[5] <= 1;
                    arrow_y[5] <= 0;
                end
            end
            if (pattern_out[6]) begin //player B down arrow
                if (!arrow_active[7]) begin
                    arrow_active[7] <= 1;
                    arrow_y[7] <= 0;
                end
            end
            if (pattern_out[5]) begin //player B left arrow
                if (!arrow_active[4]) begin
                    arrow_active[4] <= 1;
                    arrow_y[4] <= 0;
                end
            end
            if (pattern_out[4]) begin //player B right arrow
                if (!arrow_active[6]) begin
                    arrow_active[6] <= 1;
                    arrow_y[6] <= 0;
                end
            end
        end
            //update target zone status
            perfect_hit_a <= 0;
            perfect_hit_b <= 0;
            prev_player_a_keys <= player_a_keys;
            prev_player_b_keys <= player_b_keys;
            
				//checks if arrow is at right height and column
            for (i = 0; i < 4; i = i + 1) begin //player A
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
            
            for (i = 4; i < 8; i = i + 1) begin //player B
                in_target_zone[i] <= (
                    arrow_y[i] >= (TARGET_Y - HIT_RANGE) && 
                    arrow_y[i] <= (TARGET_Y + HIT_RANGE) &&
                    arrow_x[i] >= (P2_TARGET_X + ((i-4) * (BOX_SIZE + BOX_SPACING))) &&
                    arrow_x[i] < (P2_TARGET_X + ((i-4) * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)
                );
                
                if (player_b_keys[i-4] && !prev_player_b_keys[i-4]) begin
                    if (arrow_active[i] && in_target_zone[i]) begin //when hit is detected
                        perfect_hit_b <= 1;
                        arrow_active[i] <= 0;
								box_flash[i] <= 1; //start flash
								flash_counter <= 0;
                    end
                end
            end

            //arrow movement - counter counts to MOVE_SPEED, when reached, move each arrow down a pixel and remove arrows that reach bottom
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

    function is_arrow_pixel;
        input [7:0] x, arrow_x;
        input [6:0] y, arrow_y;
        input [1:0] direction;
        begin
            case (direction)
                0: begin
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_HEIGHT &&
                                    y >= arrow_y && y < arrow_y + ARROW_WIDTH &&
                                    ((y == arrow_y + 3) || //horizontal shaft
                                     (x == arrow_x && y == arrow_y + 3) || //arrow tip
                                     (x == arrow_x + 1 && y >= arrow_y + 2 && y <= arrow_y + 4) || //arrow head one side
                                     (x == arrow_x + 2 && y >= arrow_y + 1 && y <= arrow_y + 5) || //arrow head other side
                                     (x >= arrow_x + 3 && x <= arrow_x + 6 && y == arrow_y + 3))); //back of shaft
                end
                
                1: begin
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_WIDTH &&
                                    y >= arrow_y && y < arrow_y + ARROW_HEIGHT &&
                                    ((x == arrow_x + 3) ||
                                     (y == arrow_y && x == arrow_x + 3) || 
                                     (y == arrow_y + 1 && x >= arrow_x + 2 && x <= arrow_x + 4) ||
                                     (y == arrow_y + 2 && x >= arrow_x + 1 && x <= arrow_x + 5)));
                end
                
                2: begin
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_HEIGHT &&
                                    y >= arrow_y && y < arrow_y + ARROW_WIDTH &&
                                    ((y == arrow_y + 3) ||
                                     (x == arrow_x + 6 && y == arrow_y + 3) ||
                                     (x == arrow_x + 5 && y >= arrow_y + 2 && y <= arrow_y + 4) ||
                                     (x == arrow_x + 4 && y >= arrow_y + 1 && y <= arrow_y + 5) ||
                                     (x >= arrow_x && x <= arrow_x + 3 && y == arrow_y + 3)));
                end
                
                3: begin 
                    is_arrow_pixel = (x >= arrow_x && x < arrow_x + ARROW_WIDTH &&
                                    y >= arrow_y && y < arrow_y + ARROW_HEIGHT &&
                                    ((x == arrow_x + 3) || 
                                     (y == arrow_y + ARROW_HEIGHT - 1 && x == arrow_x + 3) ||
                                     (y == arrow_y + ARROW_HEIGHT - 2 && x >= arrow_x + 2 && x <= arrow_x + 4) ||
                                     (y == arrow_y + ARROW_HEIGHT - 3 && x >= arrow_x + 1 && x <= arrow_x + 5)));
                end
            endcase
        end
    endfunction
	 
	 //colour logic
    always @(*) begin
        integer i;
		  
		  if (game_over) begin
            pixel_color = 3'b000; //black screen when game over
        end
        else begin
			pixel_color = 3'b000;  //black background
			
        //drawing target boxes
        //p1 boxes
        for (i = 0; i < 4; i = i + 1) begin
            if (y_counter >= TARGET_Y - BOX_SIZE && y_counter < TARGET_Y + BOX_SIZE && x_counter >= (P1_TARGET_X + (i * (BOX_SIZE + BOX_SPACING))) && x_counter < (P1_TARGET_X +(i * (BOX_SIZE + BOX_SPACING)) + BOX_SIZE)) begin
                pixel_color = box_flash[i] ? 3'b111 : 3'b101; //normal is magenta, flashing is white
            end
        end
        
        //p2 boxes
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
                case(i % 4)
                    0: pixel_color = 3'b100; //left arrow red
                    1: pixel_color = 3'b110; //up arrow yellow
                    2: pixel_color = 3'b010; //right arrow green
                    3: pixel_color = 3'b011; //down arrow cyan
                endcase
            end
        end
		  end
    end
    
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
