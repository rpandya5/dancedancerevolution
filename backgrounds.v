// updated nov 25 AT 4:43 PM -- COMPILED VERSION

/* THIS DOCUMENT HAS ALL THE MODULES TO MAKE THE BACKGROUNDS FOR THE FOLLOWING THINGS SHOW UP:
DOES NOT HAVE STUFF FOR THE GAMEPLAY BACKGROUND

title_screen,
idle_screen,
pause_screen,
countdown_screen - ADD THE MIF FILE + IMG FOR THIS PLEASE
A_won,
B_won
all modules are the same with different mif file addresses
*/

///////////////////////////////////////////////////////////////////////////////
// Title Screen Module
///////////////////////////////////////////////////////////////////////////////
module title_screen(
    input CLOCK_50,
    input resetn,              // Active low reset
    input enable,             // Enable signal from controller
	 
    // Change from reg to wire for VGA outputs
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    // Internal signals
    wire [2:0] color;         // Changed from VGA_COLOR to avoid confusion
    wire [7:0] x;            // Changed from VGA_X
    wire [6:0] y;            // Changed from VGA_Y
    wire plot;
    
    assign plot = enable; // Only plot when enabled
    
    // Assign some default values to x, y, and color if needed
    assign x = 8'd0;  // You'll need to generate proper x coordinates
    assign y = 7'd0;  // You'll need to generate proper y coordinates
    assign color = 3'd0;  // You'll need to set proper color values
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(color),
        .x(x),
        .y(y),
        .plot(plot),
        // Connect directly to module outputs
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
    defparam VGA.BACKGROUND_IMAGE = "title_img.mif";
endmodule

///////////////////////////////////////////////////////////////////////////////
// Idle Screen Module
///////////////////////////////////////////////////////////////////////////////
module idle_screen(
    input CLOCK_50,
    input resetn,
    input enable,             // Enable signal from controller
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire plot;
    
    assign plot = enable;
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "../mif_imgs/idle_img.mif";
endmodule

///////////////////////////////////////////////////////////////////////////////
// Pause Screen Module
///////////////////////////////////////////////////////////////////////////////
module pause_screen(
    input CLOCK_50,
    input resetn,
    input enable,             // Enable signal from controller
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire plot;
    
    assign plot = enable;
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "../mif_imgs/paused_img.mif";
endmodule

///////////////////////////////////////////////////////////////////////////////
// Countdown Screen Module
///////////////////////////////////////////////////////////////////////////////
module countdown_screen(
    input CLOCK_50,
    input resetn,
    input enable,             // Enable signal from controller
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire plot;
    
    assign plot = enable;
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "../mif_imgs/5_img.mif";
endmodule

///////////////////////////////////////////////////////////////////////////////
// Player A Win Screen Module
///////////////////////////////////////////////////////////////////////////////
module A_win_screen(
    input CLOCK_50,
    input resetn,
    input enable,             // Enable signal from controller
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire plot;
    
    assign plot = enable;
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "../mif_imgs/A_won_img.mif";
endmodule

///////////////////////////////////////////////////////////////////////////////
// Player B Win Screen Module
///////////////////////////////////////////////////////////////////////////////
module B_win_screen(
    input CLOCK_50,
    input resetn,
    input enable,             // Enable signal from controller
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);
    wire [2:0] VGA_COLOR;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire plot;
    
    assign plot = enable;
    
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(VGA_COLOR),
        .x(VGA_X),
        .y(VGA_Y),
        .plot(plot),
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
    defparam VGA.BACKGROUND_IMAGE = "../mif_imgs/B_won_img.mif";
endmodule

// EXAMPLE OLD MODULE IN CASE ALL HELL BREAKS LOOSE
// module title_screen(CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK); // rename to title_screen later
	
// 	input CLOCK_50;	
// 	input [3:0] KEY; //directional inputs
// 	output [7:0] VGA_R;
// 	output [7:0] VGA_G;
// 	output [7:0] VGA_B;
// 	output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
	
	
// 	vga_adapter VGA(
// 		.resetn(KEY[0]),
// 		.clock(CLOCK_50),
// 		.colour(VGA_COLOR),
// 		.x(VGA_X),
// 		.y(VGA_Y),
// 		.plot(plot),
// 		.VGA_R(VGA_R),
// 		.VGA_G(VGA_G),
// 		.VGA_B(VGA_B),
// 		.VGA_HS(VGA_HS),
// 		.VGA_VS(VGA_VS),
// 		.VGA_BLANK_N(VGA_BLANK_N),
// 		.VGA_SYNC_N(VGA_SYNC_N),
// 		.VGA_CLK(VGA_CLK));
		
// 		defparam VGA.RESOLUTION = "160x120";
// 		defparam VGA.MONOCHROME = "FALSE";
// 		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
// 		defparam VGA.BACKGROUND_IMAGE = "title_img.mif";
// endmodule
