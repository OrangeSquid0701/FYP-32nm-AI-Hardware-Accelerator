`timescale 1ns/1ps

module fp_add(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] out
);

    // Extract sign, exponent, fraction
    wire sign_a = a[31];
    wire sign_b = b[31];
    
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    
    wire [23:0] mant_a = {1'b1, a[22:0]};
    wire [23:0] mant_b = {1'b1, b[22:0]};

    // Align exponents
    wire [7:0] exp_diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
    wire [23:0] mant_b_shifted = (exp_a > exp_b) ? (mant_b >> exp_diff) : mant_b;
    wire [23:0] mant_a_shifted = (exp_b > exp_a) ? (mant_a >> exp_diff) : mant_a;
    
    wire [7:0] result_exp_initial = (exp_a > exp_b) ? exp_a : exp_b;

    // Add or subtract mantissas based on sign
    wire [24:0] mant_sum; // 25 bits to hold carry
    wire result_sign;
    
    assign mant_sum = (sign_a == sign_b) ? 
                      (mant_a_shifted + mant_b_shifted) : 
                      (mant_a_shifted > mant_b_shifted ? mant_a_shifted - mant_b_shifted : mant_b_shifted - mant_a_shifted);

    assign result_sign = (mant_a_shifted >= mant_b_shifted) ? sign_a : sign_b;

    // Normalize the result
    reg [7:0] result_exp;
    reg [23:0] norm_mant;

    reg [23:0] temp_mant;
    reg [4:0] shift_count; // max shift is 24, so 5 bits
    
    integer i;
    always @(*) begin
        result_exp = result_exp_initial;
        temp_mant = mant_sum[23:0];
    
        // Check for carry out (overflow)
        if (mant_sum[24]) begin
            norm_mant = mant_sum[24:1]; // shift right
            result_exp = result_exp + 1;
        end
        else begin
            
            shift_count = 24; // Default case (all zeros)
            
            // Iterate from LSB (0) to MSB (23)
            // The last '1' found will overwrite previous results, 
            // effectively finding the MSB '1'.
            for (i = 0; i < 24; i = i + 1) begin
                if (temp_mant[i]) begin
                    shift_count = 23 - i;
                end
            end
            
    
            // Shift left by shift_count
            norm_mant = temp_mant << shift_count;
            result_exp = result_exp - shift_count;
        end
    end
    

    // Remove implicit leading 1 in final fraction
    wire [22:0] result_frac = norm_mant[22:0];
    // If both inputs are zero, output zero
    wire both_zero = (a == 32'h00000000) && (b == 32'h00000000);
    assign out = both_zero ? 32'h00000000 : {result_sign, result_exp, norm_mant[22:0]};

endmodule



