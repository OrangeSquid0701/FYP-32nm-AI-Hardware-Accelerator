`timescale 1ns / 1ps

module fp_mul_tb;

    reg  [31:0] a, b;
    wire [31:0] out;

    fp_mul dut (.a(a), .b(b), .out(out));

initial begin
        a = 32'h00000000; // 0
        b = 32'h00000000; // 0
        #10;
        $display("Test Case 1: [Zero Check]");
        $display("0 * 0 = 0 (Expected: 00000000)");
        $display("Result: %h %s \n", out, (out == 32'h00000000) ? "PASS" : "FAIL");
        
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        #10;
        $display("Test Case 2: [Simple Multiplication]");
        $display("1.0 * 2.0 = 2.0 (Expected: 40000000)");
         $display("Result: %h %s \n", out, (out == 32'h40000000) ? "PASS" : "FAIL");

        a = 32'h40000000; // 2.0
        b = 32'hc0000000; // -2.0
        #10;
        $display("Test Case 3: [XOR Logic for Sign Bit]");
        $display("2.0 * -2.0 = -4.0 (Expected: c0800000)");
         $display("Result: %h %s \n", out, (out == 32'hc0800000) ? "PASS" : "FAIL");
        
        a = 32'h3F800000; // 1.0
        b = 32'h3FC00000; // 1.5
        #10;
        $display("Test Case 4: [Result No Shifting]");
        $display("1.0 * 1.5 = 1.5 (Expected: 3FC00000)"); // Although bdab9a92 is the exact answer, it is acceptable
        $display("Result: %h %s \n", out, (out == 32'h3FC00000) ? "PASS" : "FAIL");
        
        a = 32'h40000000; // 2.0
        b = 32'h40400000; // 3.0
        #10;
        $display("Test Case 5: [Result Shifting]");
        $display("2.0 * 3.0 = 6.0 (Expected: 40C00000)");
        $display("Result: %h %s \n", out, (out == 32'h40C00000) ? "PASS" : "FAIL");

        
        a = 32'h3E800000; // 0.25
        b = 32'h3c23d70a; // 0.01
        #10;
        $display("Test Case 6: [Exponent Check]");
        $display("0.25 * 0.01 = 0.0025 (Expected: 3b23d70a)"); // Although 3d4ccccd is the exact answer, it is acceptable
        $display("Result: %h %s \n", out, (out == 32'h3b23d70a) ? "PASS" : "FAIL");

        $finish;
    end

endmodule
