module game_music (
    // Inputs
    CLOCK_50,
    KEY,
    AUD_ADCDAT,
    
    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,
    
    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK,
    SW,
    LEDR
);

// Port declarations
input               CLOCK_50;
input       [3:0]   KEY;
input       [3:0]   SW;
input               AUD_ADCDAT;
inout               AUD_BCLK;
inout               AUD_ADCLRCK;
inout               AUD_DACLRCK;
inout               FPGA_I2C_SDAT;
output              AUD_XCK;
output              AUD_DACDAT;
output              FPGA_I2C_SCLK;
output      [9:0]   LEDR;

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
    else if (SW[0]) begin
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
wire [31:0] melody_sound = (SW[0] && note_active) ? 
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

// LED display - now includes difficulty level display
assign LEDR[0] = SW[0];                     // Music active
assign LEDR[3:1] = pattern_step[2:0];       // Show pattern position (lower bits)
assign LEDR[5:4] = difficulty_level;        // Show current difficulty level
assign LEDR[7:6] = measure_count[1:0];      // Show measure count (lower bits)
assign LEDR[8] = note_active;               // Note playing
assign LEDR[9] = melody_snd | kick_snd | snare_snd | hihat_snd;  // Sound activity

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
