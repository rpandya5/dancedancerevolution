module controller (
    input clock,          // clock (50MHz)
    input reset,          // Global reset (SW9)
    input start,          // key0 for start (active low)
    input pause,          // key1 for pause (active low)
    
    // State outputs
    output reg [5:0] current_state,
    
    // Game control outputs
    output reg enable_title_screen,    // Show title image
    output reg enable_idle_screen,    // Show title image
    output reg enable_title_audio,     // Play title music
    output reg enable_countdown_screen, // Show countdown animation
    output reg enable_countdown_audio,  // Play countdown beeps
    output reg enable_song,            // Play main game song
    output reg game_active,            // Enable game logic
    output reg show_pause_screen,      // Show pause overlay
    output reg show_game_over,         // Show game over screen
    
    // Timing outputs for synchronization
    output reg [63:0] precise_timer,    // Using 64 bits for accurate timing
    output reg [63:0] state_start_time  // Time when current state started
);

    // State definitions
    parameter STARTUP    = 6'b000000;  // Title screen + music
    parameter IDLE      = 6'b000011;  // Waiting for start
    parameter COUNTDOWN = 6'b000101;  // 3-2-1-GO sequence
    parameter PAUSE     = 6'b001001;  // Paused state
    parameter PLAYING   = 6'b010001;  // Main gameplay
    parameter GAMEOVER  = 6'b100001;  // Show results

    // Clock frequency and timing constants (for 50MHz clock)
    parameter CLOCK_50MHZ = 64'd50_000_000;  // 50 million ticks per second
    
    // Duration constants (in clock cycles)
    parameter TITLE_LENGTH    = CLOCK_50MHZ * 64'd32;  // 32 seconds for title
    parameter COUNTDOWN_TIME  = CLOCK_50MHZ * 64'd5;   // 5 seconds
    parameter SONG_LENGTH    = CLOCK_50MHZ * 64'd64;   // 64 seconds for gameplay
    
    // Internal registers
    reg [5:0] next_state;
    reg [5:0] stored_state;     // For pause state return
    reg [63:0] stored_timer;    // Store timer value during pause
    reg [63:0] pause_start_time; // When pause began
    reg [7:0] stored_outputs;   // Store enable signals during pause

    // State register with reset
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;  // Reset goes to IDLE
            precise_timer <= 64'd0;
            state_start_time <= 64'd0;
        end
        else if (next_state != current_state) begin
            // Update state_start_time when state changes
            state_start_time <= precise_timer;
            current_state <= next_state;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Global timer counter
    always @(posedge clock or posedge reset) begin
        if (reset)
            precise_timer <= 64'd0;
        else if (current_state == PAUSE)
            precise_timer <= stored_timer;  // Maintain time during pause
        else
            precise_timer <= precise_timer + 64'd1;
    end

    // Store state and timing info before entering pause
    always @(posedge clock) begin
        if (!pause && current_state != PAUSE) begin  // About to enter pause
            stored_state <= current_state;
            stored_timer <= precise_timer;
            pause_start_time <= precise_timer;
            stored_outputs <= {enable_title_screen, enable_idle_screen, enable_title_audio, 
                             enable_countdown_screen, enable_countdown_audio,
                             enable_song, game_active, show_pause_screen, 
                             show_game_over};
        end
    end

    // State duration calculation
    wire [63:0] time_in_current_state = precise_timer - state_start_time;

    // Next state logic 
    always @(*) begin
        next_state = current_state;  // Default: stay in current state
        
        case (current_state)
            STARTUP: begin
                if (time_in_current_state >= TITLE_LENGTH)
                    next_state = IDLE;
                else if (!pause)  // Can pause during startup
                    next_state = PAUSE;
            end

            IDLE: begin
                if (!start)  // Active low - start when pressed
                    next_state = COUNTDOWN;
                else if (!pause)
                    next_state = PAUSE;
            end

            COUNTDOWN: begin
                if (time_in_current_state >= COUNTDOWN_TIME)
                    next_state = PLAYING;
                else if (!pause)  // Active low pause
                    next_state = PAUSE;
            end

            PLAYING: begin
                if (time_in_current_state >= SONG_LENGTH)
                    next_state = GAMEOVER;
                else if (!pause)  // Active low pause
                    next_state = PAUSE;
            end

            PAUSE: begin
                if (!pause) begin  // Active low - Another pause press returns to stored state
                    next_state = stored_state;
                end
            end

            GAMEOVER: begin
                if (!start)  // Active low - restart game when pressed
                    next_state = IDLE;  // Return to IDLE
                else if (!pause)
                    next_state = PAUSE;
            end

            default: next_state = IDLE;  // Default to IDLE
        endcase

        // Global reset override
        if (reset)
            next_state = IDLE;  // Reset goes to IDLE
    end

    // Output logic
    always @(*) begin
        // Default all outputs to 0
        enable_title_screen = 0;
        enable_idle_screen =0;
        enable_title_audio = 0;
        enable_countdown_screen = 0;
        enable_countdown_audio = 0;
        enable_song = 0;
        game_active = 0;
        show_pause_screen = 0;
        show_game_over = 0;
        
        if (current_state == PAUSE) begin
            // During pause, show pause screen and maintain stored outputs
            show_pause_screen = 1;
            {enable_title_screen, enable_title_audio, enable_idle_screen,
             enable_countdown_screen, enable_countdown_audio,
             enable_song, game_active, 
             show_game_over} = stored_outputs[7:1];  // Drop pause bit from stored outputs and restore other signals
        end
        else begin
            // State-specific outputs
            case (current_state)
                STARTUP: begin
                    enable_title_screen = 1;
                    enable_title_audio = 1;
                end

                IDLE: begin
                    enable_idle_screen = 1;
                    enable_title_audio = 1;
                end

                COUNTDOWN: begin
                    enable_countdown_screen = 1;
                    enable_countdown_audio = 1;
                end

                PLAYING: begin
                    enable_song = 1;
                    game_active = 1;
                end

                GAMEOVER: begin
                    show_game_over = 1;
                end

                default: begin
                    enable_title_screen = 1;
                end
            endcase
        end
    end

endmodule
