`timescale 1ns / 1ps

module systolic_with_ahb (
    input  wire HCLK, HRESETn, HSEL, HWRITE,
    input  wire [31:0] HADDR, HWDATA,
    input  wire [1:0]  HTRANS,
    input  wire [2:0]  HSIZE, HBURST,
    input  wire [3:0]  HPROT,
    output wire [31:0] HRDATA,
    output wire        HREADYOUT, HRESP
);

    // Wires to connect AHB Wrapper -> AI Core
    wire [31:0] w_load, w_t0, w_t1, w_t2, w_t3, w_b0, w_b1, w_b2, w_b3;
    // Wires to connect AI Core -> AHB Wrapper
    wire [31:0] w_raw_out0, w_raw_out1, w_raw_out2, w_raw_out3;
    wire [31:0] w_out0, w_out1, w_out2, w_out3;
    
    wire w_commit_top;
    wire w_commit_left;

    wire w_array_enable = w_commit_top | w_commit_left;
    

    wire [31:0] w_ahb_left_0, w_ahb_left_1, w_ahb_left_2, w_ahb_left_3;
    wire [31:0] w_skewed_left_0, w_skewed_left_1, w_skewed_left_2, w_skewed_left_3;

    input_skew_buffer u_skew_buffer (
        .clk(HCLK),
        .rst_n(HRESETn),
        .enable(w_array_enable), // Same OR gate enable we made earlier!
        
        // Connect flat inputs from AHB
        .in_row_0(w_ahb_left_0),
        .in_row_1(w_ahb_left_1),
        .in_row_2(w_ahb_left_2),
        .in_row_3(w_ahb_left_3),
        
        // Connect skewed outputs to the Array
        .out_row_0(w_skewed_left_0),
        .out_row_1(w_skewed_left_1),
        .out_row_2(w_skewed_left_2),
        .out_row_3(w_skewed_left_3)
    );
    
    output_deskew_buffer u_deskew_buffer (
        .clk(HCLK),
        .rst_n(HRESETn),
        .enable(w_array_enable), 
        
        // Connect staggered inputs FROM the AI Core
        .in_col_0(w_raw_out0),
        .in_col_1(w_raw_out1),
        .in_col_2(w_raw_out2),
        .in_col_3(w_raw_out3),
        
        // Connect flat outputs TO the AHB Wrapper (using your existing wires)
        .out_col_0(w_out0),
        .out_col_1(w_out1),
        .out_col_2(w_out2),
        .out_col_3(w_out3)
    );

    ahb_wrapper u_bus (
        .HCLK(HCLK), .HRESETn(HRESETn), .HSEL(HSEL), .HADDR(HADDR), 
        .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE), .HBURST(HBURST), 
        .HPROT(HPROT), .HWDATA(HWDATA), .HRDATA(HRDATA), 
        .HREADYOUT(HREADYOUT), .HRESP(HRESP),
        
        // Connect Outputs to Wires
        .reg_load_weights(w_load),
        .reg_in_left_0(w_ahb_left_0), .reg_in_left_1(w_ahb_left_1), .reg_in_left_2(w_ahb_left_2), .reg_in_left_3(w_ahb_left_3),
        .reg_in_top_0 (w_t0), .reg_in_top_1 (w_t1), .reg_in_top_2 (w_t2), .reg_in_top_3 (w_t3),
        .reg_in_bias_0(w_b0), .reg_in_bias_1(w_b1), .reg_in_bias_2(w_b2), .reg_in_bias_3(w_b3),
        
        .commit_top_out(w_commit_top), .commit_left_out(w_commit_left),
        
        // Connect Inputs from Wires
        .w_out_col_0(w_out0), .w_out_col_1(w_out1), .w_out_col_2(w_out2), .w_out_col_3(w_out3)
    );

    // 2. Instantiate AI Core
    systolic_4x4_ws u_core (
        .clk(HCLK), .rst_n(HRESETn), .enable(w_array_enable), .load_weights(w_load[0]),
        .in_left_0(w_skewed_left_0), .in_left_1(w_skewed_left_1), .in_left_2(w_skewed_left_2), .in_left_3(w_skewed_left_3),
        .in_top_0 (w_t0), .in_top_1 (w_t1), .in_top_2 (w_t2), .in_top_3 (w_t3),
        .bias_0   (w_b0), .bias_1   (w_b1), .bias_2   (w_b2), .bias_3   (w_b3),
        .out_col_0(w_raw_out0), .out_col_1(w_raw_out1), .out_col_2(w_raw_out2), .out_col_3(w_raw_out3)
    );

endmodule
