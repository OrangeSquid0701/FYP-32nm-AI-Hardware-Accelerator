`timescale 1ns / 1ps
module input_skew_buffer (
    input clk,
    input rst_n,
    input enable,         // The COMMIT pulse from your CPU

    // Flat inputs coming from the AHB Wrapper
    input [31:0] in_row_0,
    input [31:0] in_row_1,
    input [31:0] in_row_2,
    input [31:0] in_row_3,

    // Skewed (staircase) outputs going to the Systolic Array
    output [31:0] out_row_0,
    output [31:0] out_row_1,
    output [31:0] out_row_2,
    output [31:0] out_row_3
);

    // Row 0: 0 Clock Delay (Passes straight through to PE0)
    assign out_row_0 = in_row_0;

    // Row 1: 1 Clock Delay (1 Flip-Flop)
    reg [31:0] r1_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) r1_d1 <= 0;
        else if (enable) r1_d1 <= in_row_1;
    end
    assign out_row_1 = r1_d1;

    // Row 2: 2 Clock Delays (2 Flip-Flops cascaded)
    reg [31:0] r2_d1, r2_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r2_d1 <= 0; r2_d2 <= 0;
        end else if (enable) begin
            r2_d1 <= in_row_2;
            r2_d2 <= r2_d1;     // Shift data down the chain
        end
    end
    assign out_row_2 = r2_d2;

    // Row 3: 3 Clock Delays (3 Flip-Flops cascaded)
    reg [31:0] r3_d1, r3_d2, r3_d3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r3_d1 <= 0; r3_d2 <= 0; r3_d3 <= 0;
        end else if (enable) begin
            r3_d1 <= in_row_3;
            r3_d2 <= r3_d1;
            r3_d3 <= r3_d2;     // Shift data down the chain
        end
    end
    assign out_row_3 = r3_d3;

endmodule