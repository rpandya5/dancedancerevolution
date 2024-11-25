module countdown_audio (
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
    LEDR    // Added LED output
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
output      [9:0]   LEDR;   // Added LED declaration

// Internal Wires (matching working demo exactly)
wire                audio_in_available;
wire                audio_out_allowed;
wire        [31:0]  left_channel_audio_in;
wire        [31:0]  right_channel_audio_in;
wire        [31:0]  left_channel_audio_out;
wire        [31:0]  right_channel_audio_out;
wire                read_audio_in;
wire                write_audio_out;

// Internal Registers
reg         [18:0]  delay_cnt;      // For tone frequency
reg         [31:0]  beep_timer;     // For beep duration
reg         [2:0]   beep_count;     // Counts 0 to 5 (6 beeps)
reg                 snd;            // Sound wave toggle
reg                 beep_active;    // Whether we're in a beep or gap

// Parameters for timing (at 50MHz clock)
parameter BEEP_LENGTH = 32'd25000000;    // 0.5 second beep
parameter GAP_LENGTH  = 32'd15000000;    // 0.3 second gap
parameter LAST_BEEP_LENGTH = 32'd35000000; // 0.7 second for "GO"

// Sound frequency control (from working example)
wire [18:0] delay = 19'd40000;  // Fixed frequency for all beeps

// LED Control - LEDR[0] follows beep_active
assign LEDR[0] = (SW[0] && beep_active);  // LED on during beeps
assign LEDR[9:1] = 9'b0;  // Other LEDs off

// Sequential Logic
always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin  // Reset
        delay_cnt <= 0;
        beep_timer <= 0;
        beep_count <= 0;
        snd <= 0;
        beep_active <= 0;
    end
    else if (SW[0]) begin  // Melody playing
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
    else begin  // SW[0] off - reset melody
        delay_cnt <= 0;
        beep_timer <= 0;
        beep_count <= 0;
        snd <= 0;
        beep_active <= 0;
    end
end

// Sound generation (from working example, but gated by beep_active)
wire [31:0] sound = (SW[0] && beep_active) ? (snd ? 32'd50000000 : -32'd50000000) : 32'd0;

// Audio routing (exactly as in working demo)
assign read_audio_in = audio_in_available & audio_out_allowed;
assign left_channel_audio_out = left_channel_audio_in + sound;
assign right_channel_audio_out = right_channel_audio_in + sound;
assign write_audio_out = audio_in_available & audio_out_allowed;

// Audio Controller instantiation (unchanged from demo)
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
