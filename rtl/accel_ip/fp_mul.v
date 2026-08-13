module fp_mul (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] out
);

    // Extract sign, exponent, mantissa
    wire sign_a = a[31];
    wire sign_b = b[31];

    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];

    wire [22:0] frac_a = a[22:0];
    wire [22:0] frac_b = b[22:0];

    // Add hidden 1
    wire [23:0] mant_a = {1'b1, frac_a};
    wire [23:0] mant_b = {1'b1, frac_b};

    wire sign_res = sign_a ^ sign_b;

    // Exponent add then subtract bias (127)
    wire [8:0] exp_sum = exp_a + exp_b - 8'd127; // 9 bits to avoid overflow

    // Mantissa multiply
    wire [47:0] mant_mul = mant_a * mant_b;

    // Normalize mantissa
    wire norm_shift = mant_mul[47];    // 1 if needs shifting

    wire [22:0] mant_res = norm_shift ?
                           mant_mul[46:24] :   // shift right 1
                           mant_mul[45:23];    // already normalized

    // Exponent increment if normalization shifted
    wire [7:0] exp_res = norm_shift ?
                         exp_sum + 1'b1 :
                         exp_sum;

    wire is_zero_a = (a == 32'h00000000);
    wire is_zero_b = (b == 32'h00000000);
    
    assign out = (is_zero_a || is_zero_b) ? 32'h00000000 : {sign_res, exp_res, mant_res};
    

endmodule
