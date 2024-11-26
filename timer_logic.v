module game_timer(
    input CLOCK_50,
    input reset,
    output reg [6:0] HEX5,    // Tens digit
    output reg [6:0] HEX4,    // Ones digit
    output reg game_over      // High when timer reaches 0
);

    // 7-segment display patterns (active low)
    reg [6:0] seg7 [0:9];
    
    // Counter for tracking 50MHz clock cycles
    reg [31:0] clock_counter;
    // Counter for seconds
    reg [5:0] seconds_left;
    
    initial begin
        // Initialize 7-segment patterns
        seg7[0] = 7'b1000000;  // 0
        seg7[1] = 7'b1111001;  // 1
        seg7[2] = 7'b0100100;  // 2
        seg7[3] = 7'b0110000;  // 3
        seg7[4] = 7'b0011001;  // 4
        seg7[5] = 7'b0010010;  // 5
        seg7[6] = 7'b0000010;  // 6
        seg7[7] = 7'b1111000;  // 7
        seg7[8] = 7'b0000000;  // 8
        seg7[9] = 7'b0010000;  // 9
        
        // Initialize counters
        clock_counter = 0;
        seconds_left = 60;
        game_over = 0;
    end

    // 50MHz counter to track seconds
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            clock_counter <= 0;
            seconds_left <= 60;
            game_over <= 0;
        end
        else begin
            if (!game_over) begin
                if (clock_counter >= 50000000) begin  // 1 second has passed
                    clock_counter <= 0;
                    if (seconds_left > 0)
                        seconds_left <= seconds_left - 1;
                    else
                        game_over <= 1;
                end
                else begin
                    clock_counter <= clock_counter + 1;
                end
            end
        end
    end

    // Update HEX displays
    always @(posedge CLOCK_50) begin
        HEX5 <= seg7[seconds_left / 10];     // Tens digit
        HEX4 <= seg7[seconds_left % 10];     // Ones digit
    end

endmodule
