//updated nov 25 at 4:44 pm -- COMPILED VERSION

module title_audio (
    // Inputs
    CLOCK_50,
    KEY,
    AUD_ADCDAT,
    enable_title_audio,    // Audio plays when this is high
    start,                // KEY[3] - stops audio when pressed (active low)
    
    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,
    
    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK,
    title_audio_done      // New output to signal when audio is complete
);

// Port declarations
input               CLOCK_50;
input       [3:0]   KEY;
input               AUD_ADCDAT;
input               enable_title_audio;
input               start;             // KEY[3] for start button
output reg          title_audio_done;
inout               AUD_BCLK;
inout               AUD_ADCLRCK;
inout               AUD_DACLRCK;
inout               FPGA_I2C_SDAT;
output              AUD_XCK;
output              AUD_DACDAT;
output              FPGA_I2C_SCLK;

// Internal Wires
wire                audio_in_available;
wire                audio_out_allowed;
wire        [31:0]  left_channel_audio_in;
wire        [31:0]  right_channel_audio_in;
wire        [31:0]  left_channel_audio_out;
wire        [31:0]  right_channel_audio_out;
wire                read_audio_in;
wire                write_audio_out;

// Internal Registers
reg         [18:0]  delay_cnt;          // For tone frequency
reg         [31:0]  pattern_timer;      // For pattern timing
reg         [31:0]  note_timer;         // For individual note timing
reg         [4:0]   pattern_step;       // Pattern sequence counter
reg         [4:0]   loop_count;         // Count 30 loops (0 to 29) - Changed from [1:0] to [4:0]
reg                 snd;                // Sound wave toggle
reg         [18:0]  current_delay;      // Current note frequency
reg                 note_active;        // Whether note is playing or in gap
reg                 audio_playing;      // Tracks if we're currently playing

// Parameters for timing (at 50MHz clock)
parameter PATTERN_LENGTH = 32'd12500000;   // 0.25 seconds per pattern 
parameter NOTE_GAP = 32'd1000000;         // 0.02 seconds gap between notes

// Note frequencies (higher octave for more energy)
parameter NOTE_C = 19'd23889;    // ~1046 Hz (C6)
parameter NOTE_E = 19'd18968;    // ~1318 Hz (E6)
parameter NOTE_G = 19'd15944;    // ~1568 Hz (G6)
parameter NOTE_A = 19'd14205;    // ~1760 Hz (A6)
parameter NOTE_C_HIGH = 19'd11945; // ~2093 Hz (C7)

// Sequential Logic
always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin  // Reset
        delay_cnt <= 0;
        pattern_timer <= 0;
        note_timer <= 0;
        pattern_step <= 0;
        snd <= 0;
        note_active <= 0;
        current_delay <= NOTE_C;
        audio_playing <= 0;
        title_audio_done <= 0;
        loop_count <= 0;  // Initialize loop counter
    end
    else begin
        if (enable_title_audio && !title_audio_done) begin  // Only play when enabled and not done
            audio_playing <= 1;
            
            // Frequency generation for active notes
            if (note_active) begin
                if (delay_cnt >= current_delay) begin
                    delay_cnt <= 0;
                    snd <= !snd;
                end 
                else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
            else begin
                snd <= 0;
                delay_cnt <= 0;
            end
            
            // Note timing (short note followed by gap)
            if (note_timer >= NOTE_GAP) begin
                note_timer <= 0;
                note_active <= !note_active;  // Toggle between note and gap
            end
            else begin
                note_timer <= note_timer + 1;
            end
            
            // Pattern timing and progression
            if (pattern_timer >= PATTERN_LENGTH || pattern_timer == 0) begin
                pattern_timer <= 1;  // Reset timer
                note_timer <= 0;     // Reset note timing
                note_active <= 1;    // Start with note active
                
                // Update pattern step and loop count
                if (pattern_step >= 16) begin  // End of pattern
                    pattern_step <= 0;         // Reset pattern
                    if (loop_count >= 29) begin // After 30 loops (0 to 29) - Changed from 2 to 29
                        title_audio_done <= 1;     // Signal completion
                        audio_playing <= 0;
                    end else begin
                        loop_count <= loop_count + 1;
                    end
                end else begin
                    pattern_step <= pattern_step + 1;
                end
                    
                // Pattern sequence
                case (pattern_step)
                    0,8: current_delay <= NOTE_C;
                    1,9: current_delay <= NOTE_E;
                    2,10: current_delay <= NOTE_G;
                    3,11: current_delay <= NOTE_C_HIGH;
                    4,12: current_delay <= NOTE_A;
                    5,13: current_delay <= NOTE_G;
                    6,14: current_delay <= NOTE_E;
                    7,15: current_delay <= NOTE_C_HIGH;
                    default: current_delay <= NOTE_C;
                endcase
            end
            else begin
                pattern_timer <= pattern_timer + 1;
            end
        end
        else begin  // Not enabled or already done
            audio_playing <= 0;
            snd <= 0;
            if (!enable_title_audio) begin  // Reset done flag when disabled
                title_audio_done <= 0;
            end
        end
    end
end

// Sound generation - higher amplitude for more punch
wire [31:0] sound = (audio_playing && note_active) ? (snd ? 32'd60000000 : -32'd60000000) : 32'd0;

// Audio routing
assign read_audio_in = audio_in_available & audio_out_allowed;
assign left_channel_audio_out = left_channel_audio_in + sound;
assign right_channel_audio_out = right_channel_audio_in + sound;
assign write_audio_out = audio_in_available & audio_out_allowed;

// Audio Controller instantiation
Audio_Controller Audio_Controller (
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0]),
    .clear_audio_in_memory(),
    .read_audio_in(read_audio_in),
    .clear_audio_out_memory(),
    .left_channel_audio_out(left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out(write_audio_out),
    .AUD_ADCDAT(AUD_ADCDAT),
    .AUD_BCLK(AUD_BCLK),
    .AUD_ADCLRCK(AUD_ADCLRCK),
    .AUD_DACLRCK(AUD_DACLRCK),
    .audio_in_available(audio_in_available),
    .left_channel_audio_in(left_channel_audio_in),
    .right_channel_audio_in(right_channel_audio_in),
    .audio_out_allowed(audio_out_allowed),
    .AUD_XCK(AUD_XCK),
    .AUD_DACDAT(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0])
);

endmodule

module countdown_audio (
    // Inputs
    CLOCK_50,
    KEY,
    AUD_ADCDAT,
    enable_countdown_audio,  // Added enable input

    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,

    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);

// Port declarations
input               CLOCK_50;
input       [3:0]   KEY;
input               AUD_ADCDAT;
input               enable_countdown_audio;  // New enable input
inout               AUD_BCLK;
inout               AUD_ADCLRCK;
inout               AUD_DACLRCK;
inout               FPGA_I2C_SDAT;
output              AUD_XCK;
output              AUD_DACDAT;
output              FPGA_I2C_SCLK;

// Internal Wires
wire                audio_in_available;
wire                audio_out_allowed;
wire        [31:0]  left_channel_audio_in;
wire        [31:0]  right_channel_audio_in;
wire        [31:0]  left_channel_audio_out;
wire        [31:0]  right_channel_audio_out;
wire                read_audio_in;
wire                write_audio_out;

// Internal Registers
reg         [18:0]  delay_cnt;      
reg         [31:0]  beep_timer;     
reg         [2:0]   beep_count;     
reg                 snd;            
reg                 beep_active;    
reg                 audio_playing;  // Added to track audio state

// Parameters for timing (at 50MHz clock)
parameter BEEP_LENGTH = 32'd25000000;    // 0.5 second beep
parameter GAP_LENGTH  = 32'd15000000;    // 0.3 second gap
parameter LAST_BEEP_LENGTH = 32'd35000000; // 0.7 second for "GO"

// Sound frequency control
wire [18:0] delay = 19'd40000;  // Fixed frequency for all beeps

// Sequential Logic
always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin  // Reset
        delay_cnt <= 0;
        beep_timer <= 0;
        beep_count <= 0;
        snd <= 0;
        beep_active <= 0;
        audio_playing <= 0;
    end
    else begin
        if (enable_countdown_audio) begin
            audio_playing <= 1;
            
            // Frequency generation (tone)
            if (delay_cnt >= delay) begin
                delay_cnt <= 0;
                snd <= !snd;
            end 
            else begin
                delay_cnt <= delay_cnt + 1;
            end
            
            // Beep timing logic
            if (beep_timer > 0) begin
                beep_timer <= beep_timer - 1;
            end
            else begin
                // When timer expires
                if (beep_active) begin  // End of beep
                    beep_active <= 0;
                    if (beep_count < 5) begin  // Regular gap
                        beep_timer <= GAP_LENGTH;
                    end
                end
                else begin  // End of gap
                    if (beep_count < 6) begin  // Start next beep
                        beep_active <= 1;
                        beep_count <= beep_count + 1;
                        beep_timer <= (beep_count == 5) ? LAST_BEEP_LENGTH : BEEP_LENGTH;
                    end
                end
            end
        end
        else begin  // Not enabled
            audio_playing <= 0;
            snd <= 0;
            beep_count <= 0;
            beep_timer <= 0;
            beep_active <= 0;
        end
    end
end

// Sound generation
wire [31:0] sound = (audio_playing && beep_active) ? (snd ? 32'd50000000 : -32'd50000000) : 32'd0;

// Audio routing
assign read_audio_in = audio_in_available & audio_out_allowed;
assign left_channel_audio_out = left_channel_audio_in + sound;
assign right_channel_audio_out = right_channel_audio_in + sound;
assign write_audio_out = audio_in_available & audio_out_allowed;

// Audio Controller instantiation
Audio_Controller Audio_Controller (
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0]),
    .clear_audio_in_memory(),
    .read_audio_in(read_audio_in),
    .clear_audio_out_memory(),
    .left_channel_audio_out(left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out(write_audio_out),
    .AUD_ADCDAT(AUD_ADCDAT),
    .AUD_BCLK(AUD_BCLK),
    .AUD_ADCLRCK(AUD_ADCLRCK),
    .AUD_DACLRCK(AUD_DACLRCK),
    .audio_in_available(audio_in_available),
    .left_channel_audio_in(left_channel_audio_in),
    .right_channel_audio_in(right_channel_audio_in),
    .audio_out_allowed(audio_out_allowed),
    .AUD_XCK(AUD_XCK),
    .AUD_DACDAT(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0])
);

endmodule

module game_music (
    // Inputs
    CLOCK_50,
    KEY,
    AUD_ADCDAT,
    enable_song,    // Added enable input
    
    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,
    
    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK,
);

// Port declarations
input               CLOCK_50;
input       [3:0]   KEY;
input               AUD_ADCDAT;
input               enable_song;    // New enable input
inout               AUD_BCLK;
inout               AUD_ADCLRCK;
inout               AUD_DACLRCK;
inout               FPGA_I2C_SDAT;
output              AUD_XCK;
output              AUD_DACDAT;
output              FPGA_I2C_SCLK;

// Audio interface signals
wire                audio_in_available;
wire                audio_out_allowed;
wire        [31:0]  left_channel_audio_in;
wire        [31:0]  right_channel_audio_in;
wire        [31:0]  left_channel_audio_out;
wire        [31:0]  right_channel_audio_out;
wire                read_audio_in;
wire                write_audio_out;

// Music Generation Registers
reg         [18:0]  melody_cnt;       // Melody frequency counter
reg         [31:0]  pattern_timer;    // Pattern timing
reg         [5:0]   pattern_step;     // Now 0-63 for 4-measure patterns
reg         [2:0]   measure_count;    // Track which 4-measure section
reg                 melody_snd;       // Melody wave
reg         [18:0]  current_note;     // Current note frequency
reg                 note_active;      // Note gate
reg         [1:0]   difficulty_level; // Changes density of notes based on measure_count
reg                 audio_playing;    // Added to track audio state

// Drum Generation
reg         [15:0]  lfsr_reg = 16'hACE1;  // Noise generator
reg         [15:0]  kick_env, snare_env, hihat_env;
reg                 kick_snd, snare_snd, hihat_snd;
reg         [3:0]   drum_pattern_step;

// Note frequencies for A minor pentatonic (good for dance music)
parameter A4  = 19'd45455;  // A4  (~440.00 Hz)
parameter C5  = 19'd38223;  // C5  (~523.25 Hz)
parameter D5  = 19'd34053;  // D5  (~587.33 Hz)
parameter E5  = 19'd30337;  // E5  (~659.26 Hz)
parameter G5  = 19'd25510;  // G5  (~783.99 Hz)
parameter A5  = 19'd22727;  // A5  (~880.00 Hz)

// Drum parameters
parameter KICK_ATTACK = 16'd100;
parameter KICK_DECAY = 16'd6000;
parameter SNARE_ATTACK = 16'd50;
parameter SNARE_DECAY = 16'd3000;
parameter HIHAT_ATTACK = 16'd20;
parameter HIHAT_DECAY = 16'd1000;

// Volume levels
parameter MELODY_VOL = 32'd30000000;
parameter KICK_VOL = 32'd45000000;
parameter SNARE_VOL = 32'd35000000;
parameter HIHAT_VOL = 32'd20000000;

// Modified timing parameters for 90 BPM (more playable)
parameter FULL_NOTE = 32'd33333333;    // ~90 BPM
parameter HALF_NOTE = FULL_NOTE >> 1;   // Half note
parameter QUARTER_NOTE = FULL_NOTE >> 2; // Quarter note
parameter EIGHTH_NOTE = FULL_NOTE >> 3;  // Eighth note

// LFSR for noise generation
always @(posedge CLOCK_50) begin
    lfsr_reg <= {lfsr_reg[14:0], lfsr_reg[15] ^ lfsr_reg[14] ^ lfsr_reg[12] ^ lfsr_reg[3]};
end
wire noise_bit = lfsr_reg[0];

// Main sound generation
always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin  // Reset
        melody_cnt <= 0;
        pattern_timer <= 0;
        pattern_step <= 0;
        measure_count <= 0;
        melody_snd <= 0;
        note_active <= 0;
        kick_env <= 0;
        snare_env <= 0;
        hihat_env <= 0;
        drum_pattern_step <= 0;
        difficulty_level <= 0;
    end
    else if (enable_song) begin
        // Melody generation
        if (note_active) begin
            if (melody_cnt >= current_note) begin
                melody_cnt <= 0;
                melody_snd <= !melody_snd;
            end else
                melody_cnt <= melody_cnt + 1;
        end
        
        // Update pattern timing (eighth notes for basic unit)
        if (pattern_timer >= EIGHTH_NOTE) begin
            pattern_timer <= 0;
            pattern_step <= (pattern_step >= 63) ? 0 : pattern_step + 1;
            drum_pattern_step <= (drum_pattern_step >= 15) ? 0 : drum_pattern_step + 1;
            
            // Update measure counter every 16 steps
            if (pattern_step[3:0] == 4'b1111) begin
                measure_count <= measure_count + 1;
                // Every 4 measures, increase difficulty
                if (measure_count[1:0] == 2'b11 && difficulty_level < 2)
                    difficulty_level <= difficulty_level + 1;
            end

            // Melody pattern based on difficulty level
            case (difficulty_level)
                2'd0: begin // Beginning pattern - widely spaced notes
                    case (pattern_step[5:0])
                        6'd0:  begin current_note <= A4; note_active <= 1; end
                        6'd4:  begin current_note <= C5; note_active <= 1; end
                        6'd8:  begin current_note <= E5; note_active <= 1; end
                        6'd12: begin note_active <= 0; end
                        6'd16: begin current_note <= D5; note_active <= 1; end
                        6'd20: begin note_active <= 0; end
                        6'd24: begin current_note <= C5; note_active <= 1; end
                        6'd28: begin note_active <= 0; end
                        6'd32: begin current_note <= A4; note_active <= 1; end
                        6'd36: begin note_active <= 0; end
                        6'd40: begin current_note <= C5; note_active <= 1; end
                        6'd44: begin note_active <= 0; end
                        6'd48: begin current_note <= E5; note_active <= 1; end
                        6'd52: begin note_active <= 0; end
                        6'd56: begin current_note <= D5; note_active <= 1; end
                        6'd60: begin note_active <= 0; end
                        default: begin /* maintain current state */ end
                    endcase
                end
                
                2'd1: begin // Medium pattern - some eighth note pairs
                    case (pattern_step[5:0])
                        6'd0:  begin current_note <= A4; note_active <= 1; end
                        6'd4:  begin current_note <= C5; note_active <= 1; end
                        6'd6:  begin note_active <= 0; end
                        6'd8:  begin current_note <= E5; note_active <= 1; end
                        6'd12: begin current_note <= D5; note_active <= 1; end
                        6'd14: begin note_active <= 0; end
                        6'd16: begin current_note <= C5; note_active <= 1; end
                        6'd20: begin current_note <= A4; note_active <= 1; end
                        6'd22: begin note_active <= 0; end
                        6'd24: begin current_note <= G5; note_active <= 1; end
                        6'd28: begin note_active <= 0; end
                        6'd32: begin current_note <= A4; note_active <= 1; end
                        6'd36: begin current_note <= C5; note_active <= 1; end
                        6'd40: begin note_active <= 0; end
                        6'd44: begin current_note <= E5; note_active <= 1; end
                        6'd48: begin current_note <= D5; note_active <= 1; end
                        6'd52: begin note_active <= 0; end
                        6'd56: begin current_note <= C5; note_active <= 1; end
                        6'd60: begin note_active <= 0; end
                        default: begin /* maintain current state */ end
                    endcase
                end
                
                2'd2: begin // Advanced pattern - more rhythmic complexity
                    case (pattern_step[5:0])
                        6'd0:  begin current_note <= A4; note_active <= 1; end
                        6'd2:  begin note_active <= 0; end
                        6'd4:  begin current_note <= C5; note_active <= 1; end
                        6'd6:  begin note_active <= 0; end
                        6'd8:  begin current_note <= E5; note_active <= 1; end
                        6'd10: begin note_active <= 0; end
                        6'd12: begin current_note <= D5; note_active <= 1; end
                        6'd14: begin note_active <= 0; end
                        6'd16: begin current_note <= C5; note_active <= 1; end
                        6'd18: begin note_active <= 0; end
                        6'd20: begin current_note <= A4; note_active <= 1; end
                        6'd22: begin note_active <= 0; end
                        6'd24: begin current_note <= G5; note_active <= 1; end
                        6'd26: begin note_active <= 0; end
                        6'd28: begin current_note <= E5; note_active <= 1; end
                        6'd30: begin note_active <= 0; end
                        default: begin /* maintain current state */ end
                    endcase
                end
            endcase
            
            // Drum pattern - consistent but gradually more complex
            case (drum_pattern_step)
                4'd0: begin  // Main beat
                    kick_snd <= 1;
                    snare_snd <= 0;
                    hihat_snd <= 1;
                end
                4'd4: begin  // Backbeat
                    kick_snd <= 0;
                    snare_snd <= 1;
                    hihat_snd <= 1;
                end
                4'd8: begin  // Second main beat
                    kick_snd <= 1;
                    snare_snd <= (difficulty_level > 0) ? 1 : 0; // Add syncopation at higher levels
                    hihat_snd <= 1;
                end
                4'd12: begin // Second backbeat
                    kick_snd <= 0;
                    snare_snd <= 1;
                    hihat_snd <= 1;
                end
                4'd2, 4'd6, 4'd10, 4'd14: begin // Hi-hat pattern
                    kick_snd <= 0;
                    snare_snd <= 0;
                    hihat_snd <= (difficulty_level > 1) ? 1 : 0; // More hi-hats at higher levels
                end
                default: begin
                    kick_snd <= 0;
                    snare_snd <= 0;
                    hihat_snd <= 0;
                end
            endcase
        end else
            pattern_timer <= pattern_timer + 1;
            
        // Drum envelope processing
        if (kick_snd) begin
            if (kick_env < KICK_ATTACK)
                kick_env <= kick_env + 1;
            else if (kick_env < KICK_DECAY)
                kick_env <= kick_env + 1;
            else
                kick_snd <= 0;
        end else
            kick_env <= 0;
            
        if (snare_snd) begin
            if (snare_env < SNARE_ATTACK)
                snare_env <= snare_env + 1;
            else if (snare_env < SNARE_DECAY)
                snare_env <= snare_env + 1;
            else
                snare_snd <= 0;
        end else
            snare_env <= 0;
            
        if (hihat_snd) begin
            if (hihat_env < HIHAT_ATTACK)
                hihat_env <= hihat_env + 1;
            else if (hihat_env < HIHAT_DECAY)
                hihat_env <= hihat_env + 1;
            else
                hihat_snd <= 0;
        end else
            hihat_env <= 0;
    end
end

// Sound synthesis
wire [31:0] melody_sound = (enable_song && note_active) ? 
    (melody_snd ? MELODY_VOL : -MELODY_VOL) : 32'd0;

wire [31:0] kick_sound = kick_snd ? 
    ((kick_env < KICK_ATTACK) ? 
        ((kick_env * KICK_VOL) / KICK_ATTACK) :
        (KICK_VOL - ((kick_env - KICK_ATTACK) * KICK_VOL) / KICK_DECAY)) * 
    (pattern_timer[18] ? 1 : -1) : 32'd0;

wire [31:0] snare_sound = snare_snd ?
    ((snare_env < SNARE_ATTACK) ? 
        ((snare_env * SNARE_VOL) / SNARE_ATTACK) :
        (SNARE_VOL - ((snare_env - SNARE_ATTACK) * SNARE_VOL) / SNARE_DECAY)) *
    ((noise_bit ? 1 : -1) + (pattern_timer[16] ? 1 : -1)) / 2 : 32'd0;

wire [31:0] hihat_sound = hihat_snd ?
    ((hihat_env < HIHAT_ATTACK) ? 
        ((hihat_env * HIHAT_VOL) / HIHAT_ATTACK) :
        (HIHAT_VOL - ((hihat_env - HIHAT_ATTACK) * HIHAT_VOL) / HIHAT_DECAY)) *
    (noise_bit ? 1 : -1) : 32'd0;

// Final audio mixing
assign read_audio_in = audio_in_available & audio_out_allowed;
assign left_channel_audio_out = left_channel_audio_in + 
    melody_sound + kick_sound + snare_sound + hihat_sound;
assign right_channel_audio_out = right_channel_audio_in + 
    melody_sound + kick_sound + snare_sound + hihat_sound;
assign write_audio_out = audio_in_available & audio_out_allowed;

// Audio Controller
Audio_Controller Audio_Controller (
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0]),
    .clear_audio_in_memory(),
    .read_audio_in(read_audio_in),
    .clear_audio_out_memory(),
    .left_channel_audio_out(left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out(write_audio_out),
    .AUD_ADCDAT(AUD_ADCDAT),
    .AUD_BCLK(AUD_BCLK),
    .AUD_ADCLRCK(AUD_ADCLRCK),
    .AUD_DACLRCK(AUD_DACLRCK),
    .audio_in_available(audio_in_available),
    .left_channel_audio_in(left_channel_audio_in),
    .right_channel_audio_in(right_channel_audio_in),
    .audio_out_allowed(audio_out_allowed),
    .AUD_XCK(AUD_XCK),
    .AUD_DACDAT(AUD_DACDAT)
);

// Audio configuration
avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
    .CLOCK_50(CLOCK_50),
    .reset(~KEY[0])
);

endmodule
