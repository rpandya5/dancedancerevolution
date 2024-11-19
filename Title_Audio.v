module Title_Audio (
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
reg         [2:0]   loop_count;         // Track number of pattern loops
reg                 snd;                // Sound wave toggle
reg         [18:0]  current_delay;      // Current note frequency
reg                 note_active;        // Whether note is playing or in gap

// Parameters for timing (at 50MHz clock)
parameter PATTERN_LENGTH = 32'd12500000;   // 0.25 seconds per pattern (much faster!)
parameter NOTE_GAP = 32'd1000000;    // 0.02 seconds gap between notes
parameter TOTAL_TIME = 32'd500000000;      // 10 seconds total

// Note frequencies (higher octave for more energy)
parameter NOTE_C = 19'd23889;    // ~1046 Hz (C6)
parameter NOTE_E = 19'd18968;    // ~1318 Hz (E6)
parameter NOTE_G = 19'd15944;    // ~1568 Hz (G6)
parameter NOTE_A = 19'd14205;    // ~1760 Hz (A6)
parameter NOTE_C_HIGH = 19'd11945; // ~2093 Hz (C7)

// LED Control
assign LEDR[0] = SW[0];  // Simple LED indicator when music is playing
assign LEDR[9:1] = {pattern_step[4:0], loop_count[2:0], 1'b0};

// Sequential Logic
always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin  // Reset
        delay_cnt <= 0;
        pattern_timer <= 0;
        note_timer <= 0;
        pattern_step <= 0;
        loop_count <= 0;
        snd <= 0;
        note_active <= 0;
        current_delay <= NOTE_C;
    end
    else if (SW[0]) begin  // Music playing
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
                pattern_step <= 0;
                if (loop_count < 7)  // Allow for 8 loops total
                    loop_count <= loop_count + 1;
            end
            else
                pattern_step <= pattern_step + 1;
                
            // More dynamic pattern with octave jumps
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
    else begin  // SW[0] off - reset music
        delay_cnt <= 0;
        pattern_timer <= 0;
        note_timer <= 0;
        pattern_step <= 0;
        loop_count <= 0;
        snd <= 0;
        note_active <= 0;
        current_delay <= NOTE_C;
    end
end

// Sound generation - higher amplitude for more punch
wire [31:0] sound = (SW[0] && note_active) ? (snd ? 32'd60000000 : -32'd60000000) : 32'd0;

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
