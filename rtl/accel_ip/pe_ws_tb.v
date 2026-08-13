`timescale 1ns/1ps

module pe_ws_tb;

    reg clk;
    reg rst_n;
    reg load_weight;
    reg [31:0] a_in;
    reg [31:0] sum_in;

    wire [31:0] a_out;
    wire [31:0] sum_out;

    pe_ws uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .load_weight(load_weight), 
        .a_in(a_in), 
        .sum_in(sum_in), 
        .a_out(a_out), 
        .sum_out(sum_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        load_weight = 0;
        a_in = 0;
        sum_in = 0;

        $monitor("Time: %0t | Mode: %s | A_in: %h Sum_in: %h | W_Reg: %h | A_out: %h Sum_out: %h", 
                $time, (load_weight ? "LOAD " : "CALC "), a_in, sum_in, uut.weight_reg, a_out, sum_out);

        #20 rst_n = 1; // release reset

        $display("\n--- Step 1: Load Weight ---");
        @(negedge clk);
        load_weight = 1;
        sum_in = 32'h41200000;    // weight = 10 
        a_in = 99;      // should be ignored
        
        @(negedge clk);
        // Check results
        if (uut.weight_reg == 32'h41200000 && sum_out == 32'h41200000) 
            $display("PASS: Weight 10 loaded successfully and passed to sum_out.");
        else 
            $display("FAIL: Weight incorrect. Reg: %d, Out: %h", uut.weight_reg, sum_out);


        $display("\n--- Step 2: Computation ---");
        // Formula: sum_out = sum_in + (a_in * weight)
        // weight = 10
        // Testing: 50 + (5 * 10) = 100
        
        load_weight = 0; // Compute Mode
        a_in = 32'h40a00000; // 5
        sum_in = 32'h42480000; // 50 
        
        @(negedge clk); 
        
        // Wait small delay for combinational logic + register update
        #1; 
        
        if (sum_out == 32'h42c80000)
            $display("PASS: Calc Correct. 50 + (5 * 10) = %h", sum_out);
        else
            $display("FAIL: Expected 100, got %d", sum_out);

        if (a_out == 32'h40a00000)
            $display("PASS: a_in (5) was passed to a_out.\n");
        else
            $display("FAIL: a_out expected 5, got %h \n", a_out);

        // Test Second Computation (Persistence)
        // Weight should still be 10.
        // Testing: 0 + (3 * 10) = 30
        @(negedge clk);
        a_in = 32'h40400000; // 3
        sum_in = 0;
        
        @(negedge clk);
        #1;
        if (sum_out == 32'h41f00000) 
            $display("PASS: Second Calc Correct (Weight persisted).\n");
        else 
            $display("FAIL: Second Calc Failed. Got %h \n", sum_out);

        $finish;
    end

endmodule