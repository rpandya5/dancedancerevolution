// UPDATED AS OF NOV 24 4:35PM

/* THIS IS THE TOP MODULE ONLY FOR THE INPUT PROCESSING MODULE */

module ddr_top (
    input CLOCK_50,            // 50MHz clock
    input [3:0] KEY,          // Keys (active low) - for start/pause/reset
    input [9:0] GPIO_0,       // GPIO inputs for buttons
    output [9:0] LEDR         // LED outputs
);

    // Internal wires for button signals
    wire [3:0] player_a_raw;  // Raw inputs for player A
    wire [3:0] player_b_raw;  // Raw inputs for player B
    wire [3:0] player_a_clean; // Debounced outputs for player A
    wire [3:0] player_b_clean; // Debounced outputs for player B
    wire [3:0] player_a_led;   // LED outputs for player A
    wire [3:0] player_b_led;   // LED outputs for player B

    // Assign GPIO pins to player inputs
    // Player A (using odd GPIO pins)
    assign player_a_raw[0] = GPIO_0[1];  // Up
    assign player_a_raw[1] = GPIO_0[3];  // Down
    assign player_a_raw[2] = GPIO_0[5];  // Left
    assign player_a_raw[3] = GPIO_0[7];  // Right

    // Player B (using even GPIO pins)
    assign player_b_raw[0] = GPIO_0[0];  // Up
    assign player_b_raw[1] = GPIO_0[2];  // Down
    assign player_b_raw[2] = GPIO_0[4];  // Left
    assign player_b_raw[3] = GPIO_0[6];  // Right

    // Connect LEDs
    assign LEDR[9:6] = player_a_led;     // Player A LEDs
    assign LEDR[3:0] = player_b_led;     // Player B LEDs

    // Instantiate the input processing module
    button_processing input_proc (
        .clock(CLOCK_50),           // 50MHz clock
        .reset(~KEY[1]),             // Reset using SW[9]
        .a_in(player_a_raw),       // Player A raw inputs
        .b_in(player_b_raw),       // Player B raw inputs
        .a_out(player_a_clean),    // Player A cleaned outputs
        .b_out(player_b_clean),    // Player B cleaned outputs
        .a_led(player_a_led),      // Player A LED indicators
        .b_led(player_b_led)       // Player B LED indicators
    );

//    // ADD REMAINING INSTANTIATIONS HERE
  
endmodule
