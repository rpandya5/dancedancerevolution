//FINAL CODE - edited: 10:06 AM

module game_timer(
    input CLOCK_50,
    input reset,
    output reg [6:0] HEX5,
    output reg [6:0] HEX4,
    output reg game_over
);

    reg [6:0] seg7 [0:9];
    reg [31:0] clock_counter;
    reg [5:0] seconds_left;
    
    initial begin
        seg7[0] = 7'b1000000;
        seg7[1] = 7'b1111001;
        seg7[2] = 7'b0100100;
        seg7[3] = 7'b0110000;
        seg7[4] = 7'b0011001;
        seg7[5] = 7'b0010010;
        seg7[6] = 7'b0000010;
        seg7[7] = 7'b1111000;
        seg7[8] = 7'b0000000;
        seg7[9] = 7'b0010000;
        
        clock_counter = 0;
        seconds_left = 60;
        game_over = 0;
    end

    //count clock cycles till 1 second passes, when 1 sec passes, decrease time until 0 (game over)
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            clock_counter <= 0;
            seconds_left <= 60;
            game_over <= 0;
        end
        else begin
            if (!game_over) begin
                if (clock_counter >= 50000000) begin //1 second passed
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

    //updating the display
    always @(posedge CLOCK_50) begin
        HEX5 <= seg7[seconds_left / 10];
        HEX4 <= seg7[seconds_left % 10];
    end

endmodule
