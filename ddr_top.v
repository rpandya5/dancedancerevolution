// UPDATED AS OF NOV 25 12:06 am 

/* THIS IS THE TOP MODULE ONLY FOR THE INPUT PROCESSING MODULE */

module ddr_top (
    input CLOCK_50,            // 50MHz clock
    input [3:0] KEY,          // Keys (active low) - for start/pause/reset
    input [9:0] GPIO_0,       // GPIO inputs for buttons
    output [9:0] LEDR         // LED outputs

    // VGA outputs
    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B,
    output reg VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,

    // FROM JIYAS TOP
    input [9:0] SW;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
);

    //////////////////////////////////////////////////////////////////////////////////////
    // FOR INPUT PROCESSING
    //////////////////////////////////////////////////////////////////////////////////////

    // Internal wires for button signals
    wire [3:0] player_a_raw;  // Raw inputs for player A
    wire [3:0] player_b_raw;  // Raw inputs for player B
    wire [3:0] player_a_clean; // Debounced outputs for player A
    wire [3:0] player_b_clean; // Debounced outputs for player B
    wire [3:0] player_a_led;   // LED outputs for player A
    wire [3:0] player_b_led;   // LED outputs for player B

    // Assign GPIO pins to player inputs
    // Player A (using even GPIO pins)
    assign player_a_raw[0] = ~GPIO_0[0];  // up
    assign player_a_raw[1] = ~GPIO_0[2];  // down
    assign player_a_raw[2] = ~GPIO_0[4];  // right
    assign player_a_raw[3] = ~GPIO_0[6];  // left

    // Player B (using odd GPIO pins)
    assign player_b_raw[0] = ~GPIO_0[1];  // up
    assign player_b_raw[1] = ~GPIO_0[3];  // down
    assign player_b_raw[2] = ~GPIO_0[5];  // right
    assign player_b_raw[3] = ~GPIO_0[7];  // left

    // Connect LEDs
    assign LEDR[9:6] = player_a_led;     // Player A LEDs
    assign LEDR[3:0] = player_b_led;     // Player B LEDs

    // Instantiate the input processing module
    input_processing input_proc (
        .clock(CLOCK_50),           // 50MHz clock
        .reset(~KEY[1]),             // Reset using SW[9]
        .a_in(player_a_raw),       // Player A raw inputs
        .b_in(player_b_raw),       // Player B raw inputs
        .a_out(player_a_clean),    // Player A cleaned outputs REPLACE ALL player_a_debounced with this
        .b_out(player_b_clean),    // Player B cleaned outputs
        .a_led(player_a_led),      // Player A LED indicators
        .b_led(player_b_led)       // Player B LED indicators
    );

    //////////////////////////////////////////////////////////////////////////////////////
    // FOR CONTROLLER (MAIN FSM) MODULE
    //////////////////////////////////////////////////////////////////////////////////////
    
    // Controller signals
    wire [5:0] current_state;
    wire enable_title_screen;
    wire enable_title_audio;
    wire enable_countdown_screen;
    wire enable_countdown_audio;
    wire enable_song;
    wire game_active;
    wire show_pause_screen;
    wire show_game_over;
    wire [63:0] precise_timer;
    wire [63:0] state_start_time;

    // Instantiate the game controller
    controller game_controller (
        .clock(CLOCK_50),
        .reset(~KEY[1]),            // Same reset as input processing
        .start(KEY[3]),             // Start game with KEY[3]
        .pause(KEY[2]),             // Pause game with KEY[2]
        
        // State output
        .current_state(current_state),
        
        // Game control outputs
        .enable_title_screen(enable_title_screen),
        .enable_title_audio(enable_title_audio),
        .enable_countdown_screen(enable_countdown_screen),
        .enable_countdown_audio(enable_countdown_audio),
        .enable_song(enable_song),
        .game_active(game_active),
        .show_pause_screen(show_pause_screen),
        .show_game_over(show_game_over),
        
        // Timing outputs
        .precise_timer(precise_timer),
        .state_start_time(state_start_time)
    );
    //////////////////////////////////////////////////////////////////////////////////////
    // ALL GAMEPLAY LOGIC
    //////////////////////////////////////////////////////////////////////////////////////

    // SCORING
    wire perfect_hit_a;
	wire perfect_hit_b;

    // Instantiate score tracking module
	score_tracker tracker_inst (
		 .CLOCK_50(CLOCK_50),           // System clock
        .reset(~KEY[1]),                 // Reset signal
		 .player_a_keys(player_a_clean),    // Player A's debounced inputs
         .player_b_keys(player_b_clean),    // Player B's debounced inputs
		 .perfect_hit_a(perfect_hit_a),         // Perfect hit signal for Player A
		 .perfect_hit_b(perfect_hit_b),         // Perfect hit signal for Player B
		 .HEX0(HEX2),                   // Player A's score - ones digit
		 .HEX1(HEX3),                   // Player A's score - tens digit
		 .HEX2(HEX0),                   // Player B's score - ones digit
		 .HEX3(HEX1)                    // Player B's score - tens digit
	);
    

    // PATTERN GENERATOR INPUTS
    wire [7:0] pattern_out;
    wire pattern_valid;

    //Instantiate pattern generator with simplified timing
	arrow_pattern_generator pattern_gen (
        .clock(CLOCK_50),
        .reset(~KEY[1]),
        .game_active(1'b1),
        .pattern_out(pattern_out),
        .pattern_valid(pattern_valid)
    );

    //Instantiate arrow module
	 arrow_game game_inst(
		 .CLOCK_50(CLOCK_50),           // System clock
         .reset(~KEY[1]),                 // Reset signal
		 .player_a_keys(player_a_clean),    // Player A's debounced inputs
         .player_b_keys(player_b_clean),    // Player B's debounced inputs
		 .VGA_R(VGA_R),                 // VGA color signals
		 .VGA_G(VGA_G),
		 .VGA_B(VGA_B),
		 .VGA_HS(VGA_HS),               // VGA sync signals
		 .VGA_VS(VGA_VS),
		 .VGA_BLANK_N(VGA_BLANK_N),
		 .VGA_SYNC_N(VGA_SYNC_N),
		 .VGA_CLK(VGA_CLK),
		 .perfect_hit_a(perfect_hit_a),         // Perfect hit output for Player A
		 .perfect_hit_b(perfect_hit_b),         // Perfect hit output for Player B
		 .pattern_valid(pattern_valid),         // Input from pattern generator
		 .pattern_out(pattern_out)              // Pattern data from generator
	 );
    
    //////////////////////////////////////////////////////////////////////////////////////
    // FOR VGA BACKGROUNDS
    //////////////////////////////////////////////////////////////////////////////////////

    // VGA wires for each background
    wire [7:0] title_vga_r, title_vga_g, title_vga_b;
    wire title_vga_hs, title_vga_vs, title_vga_blank_n, title_vga_sync_n, title_vga_clk;
    
    wire [7:0] countdown_vga_r, countdown_vga_g, countdown_vga_b;
    wire countdown_vga_hs, countdown_vga_vs, countdown_vga_blank_n, countdown_vga_sync_n, countdown_vga_clk;
    
    // wire [7:0] gameplay_vga_r, gameplay_vga_g, gameplay_vga_b;
    // wire gameplay_vga_hs, gameplay_vga_vs, gameplay_vga_blank_n, gameplay_vga_sync_n, gameplay_vga_clk;
    
    wire [7:0] pause_vga_r, pause_vga_g, pause_vga_b;
    wire pause_vga_hs, pause_vga_vs, pause_vga_blank_n, pause_vga_sync_n, pause_vga_clk;
    
    wire [7:0] win_a_vga_r, win_a_vga_g, win_a_vga_b;
    wire win_a_vga_hs, win_a_vga_vs, win_a_vga_blank_n, win_a_vga_sync_n, win_a_vga_clk;
    
    wire [7:0] win_b_vga_r, win_b_vga_g, win_b_vga_b;
    wire win_b_vga_hs, win_b_vga_vs, win_b_vga_blank_n, win_b_vga_sync_n, win_b_vga_clk;

    // Instantiate all background modules
    title_screen title_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(enable_title_screen),
        .VGA_R(title_vga_r),
        .VGA_G(title_vga_g),
        .VGA_B(title_vga_b),
        .VGA_HS(title_vga_hs),
        .VGA_VS(title_vga_vs),
        .VGA_BLANK_N(title_vga_blank_n),
        .VGA_SYNC_N(title_vga_sync_n),
        .VGA_CLK(title_vga_clk)
    );

    // Idle screen instantiation
    idle_screen idle_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(enable_idle_screen),
        .VGA_R(idle_vga_r),
        .VGA_G(idle_vga_g),
        .VGA_B(idle_vga_b),
        .VGA_HS(idle_vga_hs),
        .VGA_VS(idle_vga_vs),
        .VGA_BLANK_N(idle_vga_blank_n),
        .VGA_SYNC_N(idle_vga_sync_n),
        .VGA_CLK(idle_vga_clk)
    );

    // Pause screen instantiation
    pause_screen pause_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(show_pause_screen),
        .VGA_R(pause_vga_r),
        .VGA_G(pause_vga_g),
        .VGA_B(pause_vga_b),
        .VGA_HS(pause_vga_hs),
        .VGA_VS(pause_vga_vs),
        .VGA_BLANK_N(pause_vga_blank_n),
        .VGA_SYNC_N(pause_vga_sync_n),
        .VGA_CLK(pause_vga_clk)
    );

    // Countdown screen instantiation
    countdown_screen countdown_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(enable_countdown_screen),
        .VGA_R(countdown_vga_r),
        .VGA_G(countdown_vga_g),
        .VGA_B(countdown_vga_b),
        .VGA_HS(countdown_vga_hs),
        .VGA_VS(countdown_vga_vs),
        .VGA_BLANK_N(countdown_vga_blank_n),
        .VGA_SYNC_N(countdown_vga_sync_n),
        .VGA_CLK(countdown_vga_clk)
    );

    // Player A win screen instantiation
    A_win_screen A_win_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(enable_A_won),
        .VGA_R(win_a_vga_r),
        .VGA_G(win_a_vga_g),
        .VGA_B(win_a_vga_b),
        .VGA_HS(win_a_vga_hs),
        .VGA_VS(win_a_vga_vs),
        .VGA_BLANK_N(win_a_vga_blank_n),
        .VGA_SYNC_N(win_a_vga_sync_n),
        .VGA_CLK(win_a_vga_clk)
    );

    // Player B win screen instantiation
    B_win_screen B_win_display (
        .CLOCK_50(CLOCK_50),
        .resetn(~KEY[1]),
        .enable(enable_B_won),
        .VGA_R(win_b_vga_r),
        .VGA_G(win_b_vga_g),
        .VGA_B(win_b_vga_b),
        .VGA_HS(win_b_vga_hs),
        .VGA_VS(win_b_vga_vs),
        .VGA_BLANK_N(win_b_vga_blank_n),
        .VGA_SYNC_N(win_b_vga_sync_n),
        .VGA_CLK(win_b_vga_clk)
    );

    // VGA multiplexer - selects which screen to display
    always @(*) begin
        // Default to black screen
        VGA_R = 8'b0;
        VGA_G = 8'b0;
        VGA_B = 8'b0;
        VGA_HS = 1'b0;
        VGA_VS = 1'b0;
        VGA_BLANK_N = 1'b0;
        VGA_SYNC_N = 1'b0;
        VGA_CLK = 1'b0;

        // Priority-based multiplexing
        if (enable_title_screen) begin
            // Show title screen
            VGA_R = title_vga_r;
            VGA_G = title_vga_g;
            VGA_B = title_vga_b;
            VGA_HS = title_vga_hs;
            VGA_VS = title_vga_vs;
            VGA_BLANK_N = title_vga_blank_n;
            VGA_SYNC_N = title_vga_sync_n;
            VGA_CLK = title_vga_clk;
        end
        else if (enable_countdown_screen) begin
            // Show countdown screen
            VGA_R = countdown_vga_r;
            VGA_G = countdown_vga_g;
            VGA_B = countdown_vga_b;
            VGA_HS = countdown_vga_hs;
            VGA_VS = countdown_vga_vs;
            VGA_BLANK_N = countdown_vga_blank_n;
            VGA_SYNC_N = countdown_vga_sync_n;
            VGA_CLK = countdown_vga_clk;
        end
        else if (show_pause_screen) begin
            // Show pause screen
            VGA_R = pause_vga_r;
            VGA_G = pause_vga_g;
            VGA_B = pause_vga_b;
            VGA_HS = pause_vga_hs;
            VGA_VS = pause_vga_vs;
            VGA_BLANK_N = pause_vga_blank_n;
            VGA_SYNC_N = pause_vga_sync_n;
            VGA_CLK = pause_vga_clk;
        end
        else if (game_active) begin
		 // CONNECT THIS TO GAME_LOGIC_MODULES.V
            // Show main gameplay screen
            // VGA_R = gameplay_vga_r;
            // VGA_G = gameplay_vga_g;
            // VGA_B = gameplay_vga_b;
            // VGA_HS = gameplay_vga_hs;
            // VGA_VS = gameplay_vga_vs;
            // VGA_BLANK_N = gameplay_vga_blank_n;
            // VGA_SYNC_N = gameplay_vga_sync_n;
            // VGA_CLK = gameplay_vga_clk;
        end
        else if (player_a_won) begin
            // Show player A win screen
            VGA_R = win_a_vga_r;
            VGA_G = win_a_vga_g;
            VGA_B = win_a_vga_b;
            VGA_HS = win_a_vga_hs;
            VGA_VS = win_a_vga_vs;
            VGA_BLANK_N = win_a_vga_blank_n;
            VGA_SYNC_N = win_a_vga_sync_n;
            VGA_CLK = win_a_vga_clk;
        end
        else if (player_b_won) begin
            // Show player B win screen
            VGA_R = win_b_vga_r;
            VGA_G = win_b_vga_g;
            VGA_B = win_b_vga_b;
            VGA_HS = win_b_vga_hs;
            VGA_VS = win_b_vga_vs;
            VGA_BLANK_N = win_b_vga_blank_n;
            VGA_SYNC_N = win_b_vga_sync_n;
            VGA_CLK = win_b_vga_clk;
        end
    end

    //////////////////////////////////////////////////////////////////////////////////////
    // FOR AUDIOS
    //////////////////////////////////////////////////////////////////////////////////////
    
    // Title screen audio module
    title_audio title_sound (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .AUD_ADCDAT(AUD_ADCDAT),
        .enable_title_audio(enable_title_audio),
        .start(start),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
        .SW(SW),
        .LEDR(LEDR)
    );
    
    // Countdown audio module
    countdown_audio countdown_sound (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .AUD_ADCDAT(AUD_ADCDAT),
        .enable_countdown_audio(enable_countdown_audio),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
        .SW(SW),
        .LEDR(LEDR)
    );
    
    // Game music module
    game_music game_sound (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .AUD_ADCDAT(AUD_ADCDAT),
        .enable_song(enable_song),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
        .SW(SW),
        .LEDR(LEDR)
    );

endmodule
