`timescale 1ns / 1ps
module pe_ws (
    input clk,
    input rst_n,
    input enable,         // <--- NEW: Clock Enable / Data Valid signal
    input load_weight,  
    
    input [31:0] a_in,
    input [31:0] sum_in,
    
    output reg [31:0] a_out,
    output reg [31:0] sum_out
);

    reg [31:0] weight_reg;
    
    wire [31:0] mul_res;
    wire [31:0] add_res;

    // The combinational math happens continuously...
    fp_mul u_mul (.a(a_in), .b(weight_reg), .out(mul_res));
    fp_add u_add (.a(sum_in), .b(mul_res), .out(add_res));
    
    // ...but the registers ONLY capture the results when 'enable' is HIGH.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 0;
            a_out <= 0;
            sum_out <= 0;
        end else if (enable) begin  // <--- NEW: The array only ticks when told to!
            if (load_weight) begin // Load Weight Mode
                weight_reg <= sum_in; // load weight
                sum_out <= sum_in; // pass weight to the next MAC unit
            end else begin // Compute Mode
                a_out <= a_in; // input vector
                sum_out <= add_res;  // final result
            end   
        end
        // NOTE: If enable == 0, the flip-flops implicitly hold their current values.
        // This perfectly freezes the systolic pipeline.
    end
endmodule