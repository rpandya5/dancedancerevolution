//FINAL TOP MODULE - edited: 9:34 AM

//Player A
//GPIO[1] left
//GPIO[3] up
//GPIO[5] right
//GPIO[7] down

//Player B
//GPIO[0] left
//GPIO[2] up
//GPIO[4] right
//GPIO[6] down

module ddr_top(
    CLOCK_50, 
    SW, 
    KEY, 
    GPIO_0, 
    AUD_ADCDAT,
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,
    VGA_R, 
    VGA_G, 
    VGA_B, 
    VGA_HS, 
    VGA_VS, 
    VGA_BLANK_N, 
    VGA_SYNC_N, 
    VGA_CLK,
	 HEX5,
	 HEX4,
    HEX3, 
    HEX2, 
    HEX1, 
    HEX0,  
    LEDR,
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);

    input CLOCK_50;    
	 input [9:0] SW; //reset switch
    input [3:0] KEY;
    input [7:0] GPIO_0;
    input AUD_ADCDAT;
    
    inout AUD_BCLK;     
    inout AUD_ADCLRCK;  
    inout AUD_DACLRCK;  
    inout FPGA_I2C_SDAT;
    
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
    output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0; //display for timer and scores
	 output [9:0] LEDR; //outputs debounced output
    output AUD_XCK;      
    output AUD_DACDAT;   
    output FPGA_I2C_SCLK;
    
    wire [3:0] player_a_debounced;
    wire [3:0] player_b_debounced;
    wire perfect_hit_a;
    wire perfect_hit_b;
    
    wire [7:0] pattern_out;
    wire pattern_valid;
    
    wire [3:0] player_a_raw;
    wire [3:0] player_b_raw;
	
    assign player_a_raw[0] = ~GPIO_0[0];
    assign player_a_raw[1] = ~GPIO_0[2];
    assign player_a_raw[2] = ~GPIO_0[4];
    assign player_a_raw[3] = ~GPIO_0[6];
    
    assign player_b_raw[0] = ~GPIO_0[1];
    assign player_b_raw[1] = ~GPIO_0[3];
    assign player_b_raw[2] = ~GPIO_0[5];
    assign player_b_raw[3] = ~GPIO_0[7];
    
    assign LEDR[3:0] = player_a_debounced; //debounced player A outputs
    assign LEDR[7:4] = player_b_debounced; //debounced player B outputs
    assign LEDR[8] = |player_a_raw; //lights up if any player A button is pressed
    assign LEDR[9] = |player_b_raw; //lights up if any player B button is pressed
	 
	 wire game_over;
	 
	 game_timer timer (
		 .CLOCK_50(CLOCK_50),
		 .reset(SW[9]),
		 .HEX5(HEX5),
		 .HEX4(HEX4),
		 .game_over(game_over)
	 );
	
	
	arrow_pattern_generator pattern_gen (
        .clock(CLOCK_50),
        .reset(SW[9]),
        .game_active(1'b1),
        .pattern_out(pattern_out),
        .pattern_valid(pattern_valid)
    );
	
   input_processing input_proc (
        .clock(CLOCK_50),
        .reset(SW[9]),
        .a_in(player_a_raw),
        .b_in(player_b_raw),
        .a_out(player_a_debounced),
        .b_out(player_b_debounced)
    );
	
	score_tracker tracker_inst (
		 .CLOCK_50(CLOCK_50),
		 .reset(SW[9]),
		 .player_a_keys(player_a_debounced),
		 .player_b_keys(player_b_debounced),
		 .perfect_hit_a(perfect_hit_a),
		 .perfect_hit_b(perfect_hit_b),
		 .HEX0(HEX2), // Player A's score - ones digit
		 .HEX1(HEX3), // Player A's score - tens digit
		 .HEX2(HEX0), // Player B's score - ones digit
		 .HEX3(HEX1) // Player B's score - tens digit
	);
	 
	 arrow_game game_inst(
		 .CLOCK_50(CLOCK_50),
		 .reset(SW[9]),
		 .player_a_keys(player_a_debounced),
		 .player_b_keys(player_b_debounced),
		 .VGA_R(VGA_R),
		 .VGA_G(VGA_G),
		 .VGA_B(VGA_B),
		 .VGA_HS(VGA_HS),
		 .VGA_VS(VGA_VS),
		 .VGA_BLANK_N(VGA_BLANK_N),
		 .VGA_SYNC_N(VGA_SYNC_N),
		 .VGA_CLK(VGA_CLK),
		 .perfect_hit_a(perfect_hit_a),
		 .perfect_hit_b(perfect_hit_b),
		 .pattern_valid(pattern_valid),
		 .pattern_out(pattern_out),
		 .game_over(game_over)
	 );
	

    game_music music_gen (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW[0]),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
		  .game_over(game_over)
    );

endmodule
