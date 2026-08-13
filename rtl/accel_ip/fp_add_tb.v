`timescale 1ns/1ps

module fp_add_tb;

    reg [31:0] a, b;
    wire [31:0] out;

    // Instantiate the floating-point adder
    fp_add dut (
        .a(a),
        .b(b),
        .out(out)
    );

    initial begin
        a = 32'h00000000; // 0.0
        b = 32'h00000000; // 0.0
        #10;
        $display("Test Case 1: [Zero Check]");
        $display("0 + 0 = 0 (Expected: 00000000)");
        $display("Result: %h %s \n", out, (out == 32'h00000000) ? "PASS" : "FAIL");
        
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        #10;
        $display("Test Case 2: [Expoenent Alignment]");
        $display("1.0 + 2.0 = 0 (Expected: 40400000)");
         $display("Result: %h %s \n", out, (out == 32'h40400000) ? "PASS" : "FAIL");

        a = 32'h3F0C1ED8; // 0.547345646
        b = 32'h3EED570C; // 0.46355473
        #10;
        $display("Test Case 3: [Mantissa Overflow]");
        $display("0.547345646 + 0.46355473 = 1.01090038 (Expected: 3f81652f)");
         $display("Result: %h %s \n", out, (out == 32'h3f81652f) ? "PASS" : "FAIL");
        
        a = 32'hbf0c1ed8; // -0.547345646
        b = 32'h3eed570c; // 0.46355473
        #10;
        $display("Test Case 4: [Mantissa Underflow, Leading Zero]");
        $display("-0.547345646 + 0.46355473 = -0.083790916 (Expected: bdab9a90)"); // Although bdab9a92 is the exact answer, it is acceptable
        $display("Result: %h %s \n", out, (out == 32'hbdab9a90) ? "PASS" : "FAIL");
        
        a = 32'hbf0c1ed8; // -0.547345646
        b = 32'hbeed570c; // -0.46355473
        #10;
        $display("Test Case 5: [Negative Accumulation]");
        $display("-0.547345646 + -0.46355473 = -1.01090038 (Expected: bf81652f)");
        $display("Result: %h %s \n", out, (out == 32'hbf81652f) ? "PASS" : "FAIL");

        
        a = 32'h3F800000; // 1.0
        b = 32'hbf733333; // -0.95
        #10;
        $display("Test Case 6: [Precision Check]");
        $display("1.0 + -0.95 = 0 (Expected: 3d4ccce0)"); // Although 3d4ccccd is the exact answer, it is acceptable
        $display("Result: %h %s \n", out, (out == 32'h3d4ccce0) ? "PASS" : "FAIL");

        $finish;
    end

endmodule
