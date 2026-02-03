//-----------------------------------------------------------------------------
// Alu Unit Testbench
// Directed tests for basic functionality verification
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
import alu_pkg::*;

module Alu_tb;

    //Alu port signals
    alu_op_t  alu_opcode   ; //arbitrarily supports 16 operations as this is a minimal implementation
    logic [31:0] data_in1  ;
    logic [31:0] data_in2  ;
    logic [31:0] data_out  ;
    alu_flags_t flags_out  ;


//Internal TB signal and variables
    logic clk              ; //For simulation only not a port to alu
    integer pass_count     ;
    integer fail_count     ;
    integer test_count     ;

    Alu  dut(
        .alu_opcode(alu_opcode),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_out(data_out),
        .flags_out(flags_out)
    );

    //Setup TB Clk
    always #5 clk = ~clk;  // 10ns period = 100MHz

    //Setup VCD Trace dump
    initial begin
        $dumpfile("Alu_tb.vcd");
        $dumpvars(0, Alu_tb);
    end


    // Reference model - computes expected result for any operation
    function automatic [31:0] alu_ref(input alu_op_t op, input [31:0] a, b);
        case (op)
            ALU_ADD: return a + b;
            ALU_SUB: return a - b;
            ALU_AND: return a & b;
            ALU_ORR: return a | b;
            ALU_EOR: return a ^ b;
            default: return 32'hFFFFFFFF;
        endcase
    endfunction

    // Reference model - computes expected flags for any operation
    function automatic alu_flags_t flags_ref(input alu_op_t op, input [31:0] a, b);
        logic [32:0] sum;
        logic [31:0] result;
        alu_flags_t f;

        result = alu_ref(op, a, b);

        // N and Z are the same for all operations
        f.n = result[31];
        f.z = (result == 32'h0);

        // C and V depend on operation
        case (op)
            ALU_ADD: begin
                sum = {1'b0, a} + {1'b0, b};
                f.c = sum[32];
                f.v = (a[31] == b[31]) && (result[31] != a[31]);
            end
            ALU_SUB: begin
                sum = {1'b0, a} - {1'b0, b};
                f.c = ~sum[32];  // ARM: C=1 means no borrow
                f.v = (a[31] != b[31]) && (result[31] != a[31]);
            end
            default: begin  // AND, ORR, EOR
                f.c = 1'b0;  // bitwise ops don't affect C (or use shifter carry)
                f.v = 1'b0;  // bitwise ops don't affect V
            end
        endcase
        return f;
    endfunction

    // Single generic test task for any operation
    task test_alu(alu_op_t op, input [31:0] a, b);
        // Generate expected values
        logic [31:0] expected;
        alu_flags_t expected_flags;
        expected = alu_ref(op, a, b);
        expected_flags = flags_ref(op, a, b);

        // Initialize alu signals and wait a clk cycle
        alu_opcode = op;
        data_in1 = a;
        data_in2 = b;
        @(posedge clk);

        // Test data and flags from alu match expected
        test_count++;
        if (data_out === expected && flags_out === expected_flags)
            pass_count++;
        else begin
            fail_count++;
            $display("FAIL: op=%b a=%h b=%h", op, a, b);
            $display("      result: got=%h exp=%h", data_out, expected);
            $display("      flags:  got=%b exp=%b (NZCV)", flags_out, expected_flags);
        end
    endtask

    initial begin
        //initialize signals
        $display("Initilizing all internal signals and booting in reset state due to active low");

        //signals bound to dut ports
        clk        = 0;
        rst_n      = 0;
        alu_opcode = 4'b0;
        data_in1 = 32'b0;
        data_in2 = 32'b0;

        //TB signals
        pass_count = 0;
        fail_count = 0;
        test_count = 0;

        // Wait 2 clock cycles
        @(posedge clk);
        @(posedge clk);

        // ===== ADD Tests =====
        // Identity: A + 0 = A
        test_alu(ALU_ADD, 32'h5, 32'h0);                // identity
        test_alu(ALU_ADD, 32'h0, 32'h5);                // identity (reversed)
        test_alu(ALU_ADD, 32'hFFFFFFFF, 32'h0);         // identity with max value

        // Commutativity: A + B = B + A
        test_alu(ALU_ADD, 32'h1234, 32'h5678);          // commutativity check 1
        test_alu(ALU_ADD, 32'h5678, 32'h1234);          // commutativity check 2 (should match)

        // Zero result (Z flag)
        test_alu(ALU_ADD, 32'h0, 32'h0);                // zero + zero = zero (Z=1)
        test_alu(ALU_ADD, 32'hFFFFFFFF, 32'h1);         // wraps to zero (C=1, Z=1)

        // Carry (C flag) - unsigned overflow
        test_alu(ALU_ADD, 32'h80000000, 32'h80000000);  // C=1, V=1 (also signed overflow)
        test_alu(ALU_ADD, 32'hFFFFFFFF, 32'hFFFFFFFF);  // C=1 (result = 0xFFFFFFFE)

        // Overflow (V flag) - signed overflow
        test_alu(ALU_ADD, 32'h7FFFFFFF, 32'h1);         // pos + pos = neg (V=1, N=1)
        test_alu(ALU_ADD, 32'h7FFFFFFF, 32'h7FFFFFFF);  // pos + pos = neg (V=1, N=1, C=0)

        // Negative result (N flag)
        test_alu(ALU_ADD, 32'h80000000, 32'h0);         // N=1 (MSB set)
        test_alu(ALU_ADD, 32'h1, 32'hFFFFFFFE);         // N=1 (result is 0xFFFFFFFF)

        // ===== SUB Tests =====
        // Basic subtraction
        test_alu(ALU_SUB, 32'h10, 32'h5);               // 16 - 5 = 11
        test_alu(ALU_SUB, 32'h5, 32'h5);                // 5 - 5 = 0 (Z=1)
        test_alu(ALU_SUB, 32'h0, 32'h1);                // 0 - 1 = -1 (N=1, borrow)
        test_alu(ALU_SUB, 32'h80000000, 32'h1);         // min negative - 1 (V=1, underflow)
        test_alu(ALU_SUB, 32'h7FFFFFFF, 32'hFFFFFFFF);  // max pos - (-1) (V=1, overflow)

        // ===== AND Tests =====
        test_alu(ALU_AND, 32'hFFFFFFFF, 32'h0);         // AND with 0 = 0 (Z=1)
        test_alu(ALU_AND, 32'hFFFFFFFF, 32'hFFFFFFFF);  // AND with all 1s = all 1s (N=1)
        test_alu(ALU_AND, 32'hAAAAAAAA, 32'h55555555);  // alternating bits = 0 (Z=1)
        test_alu(ALU_AND, 32'h12345678, 32'hFF00FF00);  // mask operation

        // ===== ORR Tests =====
        test_alu(ALU_ORR, 32'h0, 32'h0);                // OR 0s = 0 (Z=1)
        test_alu(ALU_ORR, 32'hAAAAAAAA, 32'h55555555);  // alternating bits = all 1s (N=1)
        test_alu(ALU_ORR, 32'h12340000, 32'h00005678);  // combine halves

        // ===== EOR Tests =====
        test_alu(ALU_EOR, 32'hFFFFFFFF, 32'hFFFFFFFF);  // XOR same = 0 (Z=1)
        test_alu(ALU_EOR, 32'hAAAAAAAA, 32'h55555555);  // XOR alternating = all 1s (N=1)
        test_alu(ALU_EOR, 32'h0, 32'h12345678);         // XOR with 0 = identity

        // ===== Bulk Random Tests =====
        repeat(1000) begin
            test_alu(alu_op_t'($urandom_range(0,4)), $urandom, $urandom);
        end


        // Summary
        $display("\n==============================================");
        $display("  Test Summary");
        $display("==============================================");
        $display("  Total:  %0d", test_count);
        $display("  Passed: %0d", pass_count);
        $display("  Failed: %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0) begin
            $display("  ALL TESTS PASSED");
        end else begin
            $display("  SOME TESTS FAILED");
        end

        $finish(fail_count);
    end

endmodule
