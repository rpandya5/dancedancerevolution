//FINAL CODE - edited: 10:05 AM

module input_processing(
    input clock,
    input reset,
    input [3:0] a_in,
    input [3:0] b_in,
    output reg [3:0] a_out,
    output reg [3:0] b_out
);
    
    parameter DB = 500_000;
    
    reg [3:0] a_sync1, a_sync2;
    reg [3:0] b_sync1, b_sync2;
    
    reg [19:0] a_count [3:0];
    reg [19:0] b_count [3:0];
    
    reg [3:0] a_state;
    reg [3:0] b_state;
    
    always @(posedge clock) begin
        a_sync1 <= a_in;
        a_sync2 <= a_sync1;
        
        b_sync1 <= b_in;
        b_sync2 <= b_sync1;
    end
    
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            a_out <= 4'b0;
            a_state <= 4'b0;
            
            b_out <= 4'b0;
            b_state <= 4'b0;
            
            for (i = 0; i < 4; i = i + 1) begin
                a_count[i] <= 20'd0;
                b_count[i] <= 20'd0;
            end
        end
        else begin
            for (i = 0; i < 4; i = i + 1) begin
                if (a_sync2[i] != a_state[i]) begin
                    if (a_count[i] < DB)
                        a_count[i] <= a_count[i] + 1'b1;
                    else begin
                        a_state[i] <= a_sync2[i];
                        a_out[i] <= a_sync2[i];
                        a_count[i] <= 20'd0;
                    end
                end
                else
                    a_count[i] <= 20'd0;
            end
            
            for (i = 0; i < 4; i = i + 1) begin
                if (b_sync2[i] != b_state[i]) begin
                    if (b_count[i] < DB)
                        b_count[i] <= b_count[i] + 1'b1;
                    else begin
                        b_state[i] <= b_sync2[i];
                        b_out[i] <= b_sync2[i];
                        b_count[i] <= 20'd0;
                    end
                end
                else
                    b_count[i] <= 20'd0;
            end
        end
    end
endmodule
