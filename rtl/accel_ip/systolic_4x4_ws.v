`timescale 1ns/1ps

module systolic_4x4_ws (
    input clk,
    input rst_n,
    input enable,
    input load_weights,
    
    // Inputs on the Left (Matrix A columns, fed temporally)
    input [31:0] in_left_0, input [31:0] in_left_1, input [31:0] in_left_2, input [31:0] in_left_3,
    
    // Inputs on the Top (Matrix B Weights)
    input [31:0] in_top_0, input [31:0] in_top_1, input [31:0] in_top_2, input [31:0] in_top_3,
    
    //Bias flow in as the "initial sum" when load_weights is LOW
    input [31:0] bias_0, input [31:0] bias_1, input [31:0] bias_2, input [31:0] bias_3,
    
    // Outputs on the Bottom (Final Result C)
    output [31:0] out_col_0, output [31:0] out_col_1, output [31:0] out_col_2, output [31:0] out_col_3
);

    wire [31:0] h_wire [0:4][0:4]; 
    wire [31:0] v_wire [0:4][0:4];

    // Assign Left Inputs
    assign h_wire[0][0] = in_left_0;
    assign h_wire[1][0] = in_left_1;
    assign h_wire[2][0] = in_left_2;
    assign h_wire[3][0] = in_left_3;

    // --- NEW: MUX Logic for Top Inputs ---
    // If loading weights: Feed in_top (Weights)
    // If computing:       Feed bias   (Initial Partial Sum)
    assign v_wire[0][0] = (load_weights) ? in_top_0 : bias_0;
    assign v_wire[0][1] = (load_weights) ? in_top_1 : bias_1;
    assign v_wire[0][2] = (load_weights) ? in_top_2 : bias_2;
    assign v_wire[0][3] = (load_weights) ? in_top_3 : bias_3;

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ROW
            for (j = 0; j < 4; j = j + 1) begin : COL
                pe_ws pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(enable),
                    .load_weight(load_weights),
                    .a_in(h_wire[i][j]),       
                    .sum_in(v_wire[i][j]),     
                    .a_out(h_wire[i][j+1]),     
                    .sum_out(v_wire[i+1][j])    
                );
            end
        end
    endgenerate

    // Output assignments with ReLU effect
    // assign out_col_0 = (v_wire[4][0][31] == 1'b1) ? 32'h00000000 : v_wire[4][0];
    // assign out_col_1 = (v_wire[4][1][31] == 1'b1) ? 32'h00000000 : v_wire[4][1];
    // assign out_col_2 = (v_wire[4][2][31] == 1'b1) ? 32'h00000000 : v_wire[4][2];
    // assign out_col_3 = (v_wire[4][3][31] == 1'b1) ? 32'h00000000 : v_wire[4][3];
    assign out_col_0 = v_wire[4][0];
    assign out_col_1 = v_wire[4][1];
    assign out_col_2 = v_wire[4][2];
    assign out_col_3 = v_wire[4][3];
    

endmodule