// updated nov 17

module controller (
    input clock,          // clock (50MHz)
    input a_reset,        // white reset button from player A
    input b_reset,        // white reset button from player B
    input start,          // key0 for start
    input pause,          // key1 for pause
    
    // state outputs
    output reg [5:0] current_state,
    
    // game control outputs
    output reg enable_title_screen,
    output reg enable_title_audio,
    output reg enable_countdown_screen,
    output reg enable_countdown_audio,
    output reg enable_song,
    output reg game_active,
    output reg show_pause_screen,
    output reg show_game_over,
    
    // timing outputs for synchronization
    output reg [63:0] precise_timer   // Using 64 bits to avoid overflow
);

    // Clock frequency and time constants
    parameter CLOCK_50MHZ = 64'd50_000_000;  // 50MHz clock using 64 bits
    
    // Duration constants (in clock cycles)
    parameter TITLE_TIME = CLOCK_50MHZ * 64'd3;     // 3 seconds
    parameter COUNTDOWN_TIME = CLOCK_50MHZ * 64'd15; // 15 seconds 
    parameter SONG_TIME = CLOCK_50MHZ * 64'd85;     // 85 seconds (plenty of room with 64 bits)
    
    // State definitions
    parameter STARTUP    = 6'b000000;
    parameter IDLE      = 6'b000011;
    parameter COUNTDOWN = 6'b000101;
    parameter PAUSE     = 6'b001001;
    parameter PLAYING   = 6'b010001;
    parameter GAMEOVER  = 6'b100001;

    // Internal signals
    wire reset;
    reg [5:0] next_state;
    reg [1:0] stored_state;      // Stores state during pause: 0=STARTUP, 1=COUNTDOWN, 2=PLAYING
    
    assign reset = (a_reset | b_reset);

    // Precise timer counter
    always @(posedge clock or posedge reset) begin
        if (reset)
            precise_timer <= 64'd0;
        else if (current_state == PAUSE)
            precise_timer <= precise_timer;  // Stop timer during pause
        else if (current_state == STARTUP || current_state == COUNTDOWN || 
                current_state == PLAYING)
            precise_timer <= precise_timer + 64'd1;
        else
            precise_timer <= 64'd0;
    end

    // State register
    always @(posedge clock or posedge reset) begin
        if (reset)
            current_state <= STARTUP;
        else
            current_state <= next_state;
    end

    // Next state logic 
    always @(*) begin
        next_state = current_state;  // Default: stay in current state
        
        case (current_state)
            STARTUP: begin
                if (precise_timer >= TITLE_TIME)
                    next_state = IDLE;
            end

            IDLE: begin
                if (!start)  // Active low button
                    next_state = COUNTDOWN;
            end

            COUNTDOWN: begin
                if (precise_timer >= COUNTDOWN_TIME)
                    next_state = PLAYING;
                else if (!pause)
                    next_state = PAUSE;
            end

            PLAYING: begin
                if (precise_timer >= SONG_TIME)
                    next_state = GAMEOVER;
                else if (!pause)
                    next_state = PAUSE;
            end

            PAUSE: begin
                if (!pause) begin  // Resume from pause
                    case (stored_state)
                        2'd0: next_state = STARTUP;
                        2'd1: next_state = COUNTDOWN;
                        2'd2: next_state = PLAYING;
                        default: next_state = PLAYING;
                    endcase
                end
            end

            GAMEOVER: begin
                if (!start)  // Restart game when start pressed
                    next_state = IDLE;
            end

            default: next_state = STARTUP;
        endcase

        // Reset override
        if (reset)
            next_state = STARTUP;
    end

    // Output logic
    always @(*) begin
        // Default all outputs to 0
        enable_title_screen = 0;
        enable_title_audio = 0;
        enable_countdown_screen = 0;
        enable_countdown_audio = 0;
        enable_song = 0;
        game_active = 0;
        show_pause_screen = 0;
        show_game_over = 0;
        
        // State-specific outputs and stored_state updates
        case (current_state)
            STARTUP: begin
                enable_title_screen = 1;
                enable_title_audio = 1;
                stored_state = 2'd0;
            end

            IDLE: begin
                enable_title_screen = 1;
                stored_state = 2'd0;
            end

            COUNTDOWN: begin
                enable_countdown_screen = 1;
                enable_countdown_audio = 1;
                stored_state = 2'd1;
            end

            PLAYING: begin
                enable_song = 1;
                game_active = 1;
                stored_state = 2'd2;
            end

            PAUSE: begin
                show_pause_screen = 1;
                // stored_state retains previous value
            end

            GAMEOVER: begin
                show_game_over = 1;
            end

            default: begin
                enable_title_screen = 1;
                stored_state = 2'd0;
            end
        endcase
    end

endmodule
