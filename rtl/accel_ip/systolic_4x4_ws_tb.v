`timescale 1ns/1ps

module systolic_4x4_ws_tb;

    // -------------------------------------------------------------------------
    // 1. Signals & Variables
    // -------------------------------------------------------------------------
    reg clk = 0; 
    reg rst_n;
    reg load_weights;

    // Inputs
    reg [31:0] in_left [0:3]; // Matrix A
    reg [31:0] in_top  [0:3]; // Matrix B (Weights only)
    reg [31:0] bias_in [0:3]; // <--- NEW: Dedicated Bias Inputs
    
    // Outputs
    wire [31:0] out_col [0:3];

    // Test Data Containers
    reg [31:0] mat_A [0:3][0:3];
    reg [31:0] mat_B [0:3][0:3];
    reg [31:0] mat_C_res [0:3][0:3]; 

    integer i, j, t, row_idx;

    // -------------------------------------------------------------------------
    // 2. DUT Instantiation (Updated with Bias Ports)
    // -------------------------------------------------------------------------
    systolic_4x4_ws uut (
        .clk(clk),
        .rst_n(rst_n),
        .load_weights(load_weights),
        
        // Matrix A Inputs
        .in_left_0(in_left[0]), .in_left_1(in_left[1]), .in_left_2(in_left[2]), .in_left_3(in_left[3]),
        
        // Matrix B Inputs (Weights)
        .in_top_0(in_top[0]),   .in_top_1(in_top[1]),   .in_top_2(in_top[2]),   .in_top_3(in_top[3]),
        
        // Bias Inputs (Dedicated Ports)
        .bias_0(bias_in[0]),    .bias_1(bias_in[1]),    .bias_2(bias_in[2]),    .bias_3(bias_in[3]),
        
        // Outputs
        .out_col_0(out_col[0]), .out_col_1(out_col[1]), .out_col_2(out_col[2]), .out_col_3(out_col[3])
    );

    // -------------------------------------------------------------------------
    // 3. Clock Generation
    // -------------------------------------------------------------------------
    always #5 clk = ~clk; 

    // -------------------------------------------------------------------------
    // 4. Main Test Process
    // -------------------------------------------------------------------------
    initial begin
        // --- INITIALIZATION ---
        rst_n = 0; 
        load_weights = 0;
        
        // Zero out inputs
        for(i=0; i<4; i=i+1) begin 
            in_left[i] = 0; 
            in_top[i]  = 0; 
            bias_in[i] = 0;
        end

        // Initialize Result Buffer
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_C_res[i][j] = 32'hFFFFFFFF;
            end
        end

        // Define Matrices
        // A = 6.0 (0x40c00000), B = 3.0 (0x40400000)
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h40c00000; 
                mat_B[i][j] = 32'h40400000; 
            end
            // Initialize Bias to 1.0 (IEEE 754: 3F800000)
            bias_in[i] = 32'h3F800000; 
        end

        // Release Reset
        #20 rst_n = 1; 

        // =====================================================================
        // PHASE 1: LOAD WEIGHTS
        // =====================================================================
        $display("\n--- PHASE 1: Loading Weights ---");
        // While load_weights is HIGH, the DUT routes 'in_top' to the PEs
        load_weights = 1;

        for (t = 3; t >= 0; t = t - 1) begin
            @(negedge clk); 
            in_top[0] = mat_B[t][0];
            in_top[1] = mat_B[t][1];
            in_top[2] = mat_B[t][2];
            in_top[3] = mat_B[t][3];
            $display("Loading Weight Row %0d", t);
        end
        
        @(negedge clk);
        load_weights = 0; 
        
        // Clear weight inputs (optional, good for cleanliness)
        in_top[0]=0; in_top[1]=0; in_top[2]=0; in_top[3]=0;
        
        // NOTE: We don't need to manually inject bias here.
        // The 'bias_in' signals are already holding the 1.0 value.
        // Since 'load_weights' is now 0, the DUT MUX automatically
        // selects 'bias_in' as the vertical input.

        // =====================================================================
        // PHASE 2: COMPUTE
        // =====================================================================
        $display("\n--- PHASE 2: Computing ---");
        
        for (t = 0; t < 20; t = t + 1) begin
            
            // 1. Capture Outputs
            for (j = 0; j < 4; j = j + 1) begin
               row_idx = t - 5 - j; 
               
               if (row_idx >= 0 && row_idx < 4) begin
                   mat_C_res[row_idx][j] = out_col[j];
                   $display("Captured Cell [%0d][%0d] = %h", row_idx, j, out_col[j]);
               end
            end

            // 2. Update Inputs
            @(negedge clk);
            
            for (i = 0; i < 4; i = i + 1) begin
                if (t >= i && t < (i + 4)) begin
                    in_left[i] = mat_A[t - i][i]; 
                end else begin
                    in_left[i] = 0;
                end
            end
        end

        // =====================================================================
        // FINAL REPORT
        // =====================================================================
        #20;
        $display("\n--- Final Result Matrix C ---");
        $display("Expected: (A*B) + Bias = 72.0 + 1.0 = 73.0 (Hex: 42920000)");
        for(i=0; i<4; i=i+1) begin
            $display("| %h %h %h %h |", mat_C_res[i][0], mat_C_res[i][1], mat_C_res[i][2], mat_C_res[i][3]);
        end

        $finish;
    end

endmodule