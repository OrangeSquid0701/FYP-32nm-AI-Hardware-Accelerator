`timescale 1ns/1ps


module ann_systolic_4x4_ws_tb;

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
    
    // temporary storage element
    reg [31:0] temp_mem [0:64];
    reg [31:0] layer_mem [0:31];
    reg [31:0] acc_mem [0:31];
    reg [31:0] partial_sum_mem [0:31];
    reg [31:0] final_result [0:31];
    
    reg  [31:0] help_a, help_b;
    wire [31:0] help_sum;
    fp_add helper_adder (
        .a(help_a),
        .b(help_b),
        .out(help_sum)
    );

    integer i, j, k, t, row_idx;

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
        initialization();
        
        // Release Reset
        #20 rst_n = 1; 
        
        //-------------------------------
        //           STAGE 1
        //-------------------------------
        mat_A[0][0] = 32'h40C00000; // 6
        mat_A[0][1] = 32'h3F99999A; // 1.2
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_1_weights.mem",
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_1_bias.mem",
            2,
            4,
            0,
            0
        );

        load_weight_and_compute();
        
        for (j = 0; j < 4; j = j + 1) begin
            final_result[j] = mat_C_res[0][j];     // Save to SAFE array indices 0-3
            final_result[j + 8] = mat_C_res[1][j]; // Save to SAFE array indices 8-11
        end
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_1_weights.mem",
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_1_bias.mem",
            2,
            4,
            4,
            4
        );

        load_weight_and_compute();

        
        for (j = 0; j < 4; j = j + 1) begin
            final_result[j + 4] = mat_C_res[0][j];      // Save to SAFE array indices 4-7
            final_result[j + 8 + 4] = mat_C_res[1][j];  // Save to SAFE array indices 12-15
        end

        #20;
        for(i=0; i<8; i=i+1) begin
            if (final_result[i][31] == 1'b1)
                final_result[i] = 32'h00000000;
        end
        
        $display("\n--- STAGE 1 RESULT ---");
        for(i=0; i<8; i=i+1) begin
            $display("Index %0d: %h", i, final_result[i]);
            layer_mem[i] = final_result[i];
        end
        
        
        //-------------------------------------
        //             STAGE 2
        //-------------------------------------
        // -------------
        // Partial Sum 1
        //--------------
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000; 
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_bias.mem", // bias file
            4, // number of rows
            4, //number of column
            0, // shifting
            0
        );

        load_weight_and_compute();

        for (j = 0; j < 4; j = j + 1) begin
            final_result[j] = mat_C_res[0][j];      // Save to SAFE array indices 0-3
            $display("%h", final_result[j]);
            acc_mem[j] = final_result[j];
        end
        
        
        // -------------
        // Partial Sum 2
        //--------------
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000; 
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i+4];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_bias.mem", // bias file
            4, // number of rows
            4, 
            32,
            0
        );

        load_weight_and_compute();

        for (j = 0; j < 4; j = j + 1) begin
            final_result[j + 4] = mat_C_res[0][j];      // Save to SAFE array indices 4-7
            acc_mem[j + 4] = final_result[j + 4];
        end
        
        
        // acc_mem[0] = final_result[0] + final_result[4] - bias_in[0];
        // acc_mem[1] = final_result[1] + final_result[5] - bias_in[1];
        // acc_mem[2] = final_result[2] + final_result[6] - bias_in[2];
        // acc_mem[3] = final_result[3] + final_result[7] - bias_in[3];
        calculate_sum(acc_mem[0], acc_mem[4], partial_sum_mem[0]);
        calculate_sum(partial_sum_mem[0], { ~bias_in[0][31], bias_in[0][30:0] }, partial_sum_mem[0]);
        
        calculate_sum(acc_mem[1], acc_mem[5], partial_sum_mem[1]);
        calculate_sum(partial_sum_mem[1], { ~bias_in[1][31], bias_in[1][30:0] }, partial_sum_mem[1]);
        
        calculate_sum(acc_mem[2], acc_mem[6], partial_sum_mem[2]);
        calculate_sum(partial_sum_mem[2], { ~bias_in[2][31], bias_in[2][30:0] }, partial_sum_mem[2]);
        
        calculate_sum(acc_mem[3], acc_mem[7], partial_sum_mem[3]);
        calculate_sum(partial_sum_mem[3], { ~bias_in[3][31], bias_in[3][30:0] }, partial_sum_mem[3]);
        
        #20;
        for(i=0; i<8; i=i+1) begin
            if (partial_sum_mem[i][31] == 1'b1)
                partial_sum_mem[i] = 32'h00000000;
        end
        
        $display("\n--- RESULT LEFT ---");
        for(i=0; i<4; i=i+1) begin
            $display("Index %0d: %h", i, partial_sum_mem[i]);
        end
        
        
        
         // -------------
        // Partial Sum 3
        //--------------
        
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000; 
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        for (i=0; i<32; i=i+1) acc_mem[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_bias.mem", // bias file
            4, // number of rows
            4, //number of column
            4, // weight_shifting
            4 // bias_shifting
        );

        load_weight_and_compute();

        for (j = 0; j < 4; j = j + 1) begin
            final_result[j] = mat_C_res[0][j];      // Save to SAFE array indices 0-3
            $display("%h", final_result[j]);
            acc_mem[j] = final_result[j];
        end
        
        
        // -------------
        // Partial Sum 4
        //--------------
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000; 
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i+4];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_2_bias.mem", // bias file
            4, // number of rows
            4, 
            36,
            4
        );

        load_weight_and_compute();

        for (j = 0; j < 4; j = j + 1) begin
            final_result[j + 4] = mat_C_res[0][j];      // Save to SAFE array indices 4-7
            acc_mem[j + 4] = final_result[j + 4];
        end
        
        
        // acc_mem[0] = final_result[0] + final_result[4] - bias_in[0];
        // acc_mem[1] = final_result[1] + final_result[5] - bias_in[1];
        // acc_mem[2] = final_result[2] + final_result[6] - bias_in[2];
        // acc_mem[3] = final_result[3] + final_result[7] - bias_in[3];
        calculate_sum(acc_mem[0], acc_mem[4], partial_sum_mem[4]);
        calculate_sum(partial_sum_mem[4], { ~bias_in[0][31], bias_in[0][30:0] }, partial_sum_mem[4]);
        
        calculate_sum(acc_mem[1], acc_mem[5], partial_sum_mem[5]);
        calculate_sum(partial_sum_mem[5], { ~bias_in[1][31], bias_in[1][30:0] }, partial_sum_mem[5]);
        
        calculate_sum(acc_mem[2], acc_mem[6], partial_sum_mem[6]);
        calculate_sum(partial_sum_mem[6], { ~bias_in[2][31], bias_in[2][30:0] }, partial_sum_mem[6]);
        
        calculate_sum(acc_mem[3], acc_mem[7], partial_sum_mem[7]);
        calculate_sum(partial_sum_mem[7], { ~bias_in[3][31], bias_in[3][30:0] }, partial_sum_mem[7]);
        
        #20;
        for(i=0; i<8; i=i+1) begin
            if (partial_sum_mem[i][31] == 1'b1)
                partial_sum_mem[i] = 32'h00000000;
        end
        
        $display("\n--- STAGE 2 RESULT ---");
        for(i=0; i<8; i=i+1) begin
            $display("Index %0d: %h", i, partial_sum_mem[i]);
            layer_mem[i] = partial_sum_mem[i];
        end
        
        
        //---------------------------------
        //           STAGE 3
        //---------------------------------
        // -------------
        // Partial Sum 1
        //--------------
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000;
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        for (i=0; i<32; i=i+1) acc_mem[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_3_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_3_bias.mem", // bias file
            4, // number of rows
            3, //number of column
            0, // shifting
            0
        );

        load_weight_and_compute();

        for (j = 0; j < 3; j = j + 1) begin
            final_result[j] = mat_C_res[0][j];      // Save to SAFE array indices 0-3
            $display("%h", final_result[j]);
            acc_mem[j] = final_result[j];
        end
        
        
        // -------------
        // Partial Sum 2
        //--------------
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            bias_in[i] = 32'h00000000; 
        end
        
        for(i=0; i<4; i=i+1)
            mat_A[0][i] = layer_mem[i+4];
        
        $display("\n--- STAGE 2 INPUT FEATURE ---");
        for(i=0; i<4; i=i+1)
            $display("Index %0d: %h", i, mat_A[0][i]);
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        
        load_weight_bias(
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_3_weights.mem", // weight file
            "C:/Users/jiens/OneDrive/Desktop/FYP/Stage_3_bias.mem", // bias file
            4, // number of rows
            3, 
            12,
            0
        );

        load_weight_and_compute();

        for (j = 0; j < 3; j = j + 1) begin
            final_result[j + 3] = mat_C_res[0][j];      // Save to SAFE array indices 3-5
            acc_mem[j + 3] = final_result[j + 3];
        end
        
        
        // acc_mem[0] = final_result[0] + final_result[4] - bias_in[0];
        // acc_mem[1] = final_result[1] + final_result[5] - bias_in[1];
        // acc_mem[2] = final_result[2] + final_result[6] - bias_in[2];
        // acc_mem[3] = final_result[3] + final_result[7] - bias_in[3];
        calculate_sum(acc_mem[0], acc_mem[3], partial_sum_mem[0]);
        calculate_sum(partial_sum_mem[0], { ~bias_in[0][31], bias_in[0][30:0] }, partial_sum_mem[0]);
        
        calculate_sum(acc_mem[1], acc_mem[4], partial_sum_mem[1]);
        calculate_sum(partial_sum_mem[1], { ~bias_in[1][31], bias_in[1][30:0] }, partial_sum_mem[1]);
        
        calculate_sum(acc_mem[2], acc_mem[5], partial_sum_mem[2]);
        calculate_sum(partial_sum_mem[2], { ~bias_in[2][31], bias_in[2][30:0] }, partial_sum_mem[2]);
        
        #20;
        for(i=0; i<8; i=i+1) begin
            if (partial_sum_mem[i][31] == 1'b1)
                partial_sum_mem[i] = 32'h00000000;
        end
        
        $display("\n---FINAL RESULT ---");
        for(i=0; i<3; i=i+1) begin
            $display("Index %0d: %h", i, partial_sum_mem[i]);
        end

        $finish;
    end
    
    task initialization; begin
        rst_n = 0; 
        load_weights = 0;
        
        help_a = 0;
        help_b = 0;
        
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
        // Initialization
        for(i=0; i<4; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                mat_A[i][j] = 32'h00000000; 
                mat_B[i][j] = 32'h00000000; 
            end
            // Initialize Bias to 1.0 (IEEE 754: 3F800000)
            bias_in[i] = 32'h00000000; 
        end
        
        for (i=0; i<64; i=i+1) begin
            temp_mem[i] = 32'h00000000;
        end
        
        for (i=0; i<32; i=i+1) final_result[i] = 32'h00000000;
        for (i=0; i<32; i=i+1) layer_mem[i] = 32'h00000000;
        for (i=0; i<32; i=i+1) acc_mem[i] = 32'h00000000;
        for (i=0; i<32; i=i+1) partial_sum_mem[i] = 32'h00000000;
        
        end
    endtask
    
    task load_weight_bias;
        input [8*256:1] w_file_path; // 256 characters max
        input [8*256:1] b_file_path;
        input [2:0] row;
        input [2:0] col;
        input [7:0] weight_shift;
        input [3:0] bias_shift;
        
        begin
        $readmemh(w_file_path, temp_mem);
        $display("%d", row);
        $display("%d", weight_shift);
        $display("%d", bias_shift);
        if (row == 2) begin
            for (j = 0; j < col; j = j + 1) begin
                mat_B[0][j] = temp_mem[j + weight_shift]; // Reads temp_mem[0], [1], [2], [3]
            end
    
            for (j = 0; j < col; j = j + 1) begin
                mat_B[1][j] = temp_mem[j + 8 + weight_shift]; // Reads temp_mem[8], [9], [10], [11]
            end
        end
        else if (row == 4 && col == 4) begin
            for (j = 0; j < col; j = j + 1) begin
                mat_B[0][j] = temp_mem[j + weight_shift]; // Reads temp_mem[0], [1], [2], [3]
            end
    
            for (j = 0; j < col; j = j + 1) begin
                mat_B[1][j] = temp_mem[j + 8 + weight_shift]; // Reads temp_mem[8], [9], [10], [11]
            end
            
            for (j = 0; j < col; j = j + 1) begin
                mat_B[2][j] = temp_mem[j + 16 + weight_shift]; // Reads temp_mem[16], [17], [18], [19]
            end
            
            for (j = 0; j < col; j = j + 1) begin
                mat_B[3][j] = temp_mem[j + 24 + weight_shift]; // Reads temp_mem[24], [25], [26], [27]
            end
        end
        else if (row == 4 && col == 3) begin
            for (j = 0; j < col; j = j + 1) begin
                mat_B[0][j] = temp_mem[j + weight_shift]; // Reads temp_mem[0], [1], [2]
            end
    
            for (j = 0; j < col; j = j + 1) begin
                mat_B[1][j] = temp_mem[j + 3 + weight_shift]; // Reads temp_mem[3], [4], [5]
            end
            
            for (j = 0; j < col; j = j + 1) begin
                mat_B[2][j] = temp_mem[j + 6 + weight_shift]; // Reads temp_mem[6], [7], [8]
            end
            
            for (j = 0; j < col; j = j + 1) begin
                mat_B[3][j] = temp_mem[j + 9 + weight_shift]; // Reads temp_mem[9], [10], [11]
            end
        end
        
        $display("\n--- WEIGHT ---");
        for(i=0; i<col; i=i+1)
            $display("Index %0d: %h", i, mat_B[0][i]);
        for(i=0; i<col; i=i+1)
            $display("Index %0d: %h", i, mat_B[1][i]);
        for(i=0; i<col; i=i+1)
            $display("Index %0d: %h", i, mat_B[2][i]);
        for(i=0; i<col; i=i+1)
            $display("Index %0d: %h", i, mat_B[3][i]);
        
        $readmemh(b_file_path, temp_mem);
        k = 0;
        for (i = 0; i < 4; i = i + 1) begin
                bias_in[i] = temp_mem[k + bias_shift];
                k = k + 1; 
        end
        
        $display("\n--- BIAS ---");
        for(i=0; i<col; i=i+1)
            $display("Index %0d: %h", i, bias_in[i]);
            
        end
    endtask
    
    task load_weight_and_compute; begin
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
    end
    endtask
    
    task calculate_sum;
        input  [31:0] in1;
        input  [31:0] in2;
        output [31:0] out_res;
        begin
            // A. Drive inputs to the helper module
            help_a = in1;
            help_b = in2;
            
            #5;
            // C. Grab the result
            out_res = help_sum;
        end
    endtask
endmodule