//FINAL CODE - edited: 10:02 AM

module arrow_pattern_generator (
    input wire clock,                    
    input wire reset,                    
    input wire game_active,            
    output reg [7:0] pattern_out,
    output reg pattern_valid
);

    localparam PATTERN_UP    = 4'b1000;
    localparam PATTERN_DOWN  = 4'b0100;
    localparam PATTERN_LEFT  = 4'b0010;
    localparam PATTERN_RIGHT = 4'b0001;
    
    localparam PAIR_UP_DOWN   = 4'b1100;
    localparam PAIR_UP_LEFT   = 4'b1010;
    localparam PAIR_UP_RIGHT  = 4'b1001;
    localparam PAIR_DOWN_LEFT = 4'b0110;
    localparam PAIR_DOWN_RIGHT= 4'b0101;
    localparam PAIR_LEFT_RIGHT= 4'b0011;

    reg [15:0] lfsr;
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    reg [24:0] spawn_counter;
    localparam SPAWN_INTERVAL = 25000000;
    
    initial begin
        lfsr = 16'hACE1;
        pattern_valid = 0;
        pattern_out = 8'b0000;
        spawn_counter = 0;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            lfsr <= 16'hACE1;
            pattern_valid <= 0;
            pattern_out <= 8'b0000;
            spawn_counter <= 0;
        end 
        else if (game_active) begin
            if (spawn_counter >= SPAWN_INTERVAL) begin
                spawn_counter <= 0;
                
                lfsr <= {lfsr[14:0], feedback};
                
					 case (lfsr[3:0])
						  //single arrows (4/16 chance = 25%)
						  4'b0000: pattern_out <= {PATTERN_UP, PATTERN_UP};
						  4'b0001: pattern_out <= {PATTERN_DOWN, PATTERN_DOWN};
						  4'b0010: pattern_out <= {PATTERN_LEFT, PATTERN_LEFT};
						  4'b0011: pattern_out <= {PATTERN_RIGHT, PATTERN_RIGHT};
						  
						  //pairs (12/16 chance = 75%)
						  4'b0100, 4'b0101: pattern_out <= {PAIR_UP_DOWN, PAIR_UP_DOWN};
						  4'b0110, 4'b0111: pattern_out <= {PAIR_UP_LEFT, PAIR_UP_LEFT};
						  4'b1000, 4'b1001: pattern_out <= {PAIR_UP_RIGHT, PAIR_UP_RIGHT};
						  4'b1010, 4'b1011: pattern_out <= {PAIR_DOWN_LEFT, PAIR_DOWN_LEFT};
						  4'b1100, 4'b1101: pattern_out <= {PAIR_DOWN_RIGHT, PAIR_DOWN_RIGHT};
						  4'b1110, 4'b1111: pattern_out <= {PAIR_LEFT_RIGHT, PAIR_LEFT_RIGHT};
					 endcase
                
                pattern_valid <= 1;
            end
            else begin
                spawn_counter <= spawn_counter + 1;
                pattern_valid <= 0;
            end
        end
    end
endmodule

module score_tracker(
    input CLOCK_50,
    input reset,
	 input [3:0] player_a_keys,
    input [3:0] player_b_keys,
    input perfect_hit_a,
    input perfect_hit_b,
    output reg [6:0] HEX0,
    output reg [6:0] HEX1,
    output reg [6:0] HEX2,
    output reg [6:0] HEX3
);

    reg [7:0] score_a;
    reg [7:0] score_b;
    
    reg [6:0] seg7 [0:9];
    
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
        score_a = 8'd0;
        score_b = 8'd0;
    end
    
    reg prev_perfect_hit_a, prev_perfect_hit_b;
    
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            score_a <= 8'd0;
            score_b <= 8'd0;
            prev_perfect_hit_a <= 0;
            prev_perfect_hit_b <= 0;
        end 
        else begin
            prev_perfect_hit_a <= perfect_hit_a;
            if (perfect_hit_a && !prev_perfect_hit_a) begin
                if (score_a < 8'd99) begin
                    score_a <= score_a + 1'd1;
                end
            end
            
            prev_perfect_hit_b <= perfect_hit_b;
            if (perfect_hit_b && !prev_perfect_hit_b) begin
                if (score_b < 8'd99) begin
                    score_b <= score_b + 1'd1;
                end
            end
        end
    end
	 
    always @(posedge CLOCK_50) begin
        HEX0 <= seg7[score_a % 10]; //player A ones digit
        HEX1 <= seg7[score_a / 10]; //player A tens digit
        HEX2 <= seg7[score_b % 10]; //player B ones digit
        HEX3 <= seg7[score_b / 10]; //player B tens digit
    end

endmodule
