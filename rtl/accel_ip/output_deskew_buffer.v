`timescale 1ns / 1ps
module output_deskew_buffer (
    input clk,
    input rst_n,
    input enable,         // Controlled by the exact same COMMIT pulse!

    // Raw staggered outputs coming FROM the Systolic Array
    input [31:0] in_col_0,
    input [31:0] in_col_1,
    input [31:0] in_col_2,
    input [31:0] in_col_3,

    // Perfectly aligned flat outputs going TO the AHB Wrapper
    output [31:0] out_col_0,
    output [31:0] out_col_1,
    output [31:0] out_col_2,
    output [31:0] out_col_3
);

    // Column 3: The slowest column. 0 Clock Delay (Passes straight through)
    assign out_col_3 = in_col_3;

    // Column 2: 1 Clock Delay (1 Flip-Flop)
    reg [31:0] c2_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) c2_d1 <= 0;
        else if (enable) c2_d1 <= in_col_2;
    end
    assign out_col_2 = c2_d1;

    // Column 1: 2 Clock Delays (2 Flip-Flops cascaded)
    reg [31:0] c1_d1, c1_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c1_d1 <= 0; c1_d2 <= 0;
        end else if (enable) begin
            c1_d1 <= in_col_1;
            c1_d2 <= c1_d1;     
        end
    end
    assign out_col_1 = c1_d2;

    // Column 0: The fastest column. 3 Clock Delays (3 Flip-Flops cascaded)
    reg [31:0] c0_d1, c0_d2, c0_d3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c0_d1 <= 0; c0_d2 <= 0; c0_d3 <= 0;
        end else if (enable) begin
            c0_d1 <= in_col_0;
            c0_d2 <= c0_d1;
            c0_d3 <= c0_d2;     
        end
    end
    assign out_col_0 = c0_d3;

endmodule