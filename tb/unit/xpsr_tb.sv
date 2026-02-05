//-----------------------------------------------------------------------------
// xPSR Unit Testbench
// Directed tests for basic functionality verification
//-----------------------------------------------------------------------------
// TODO: Add IPSR and EPSR tests when those registers are integrated
//   - Test write_addr selects correct register (APSR=0, IPSR=1, EPSR=2)
//   - Test IPSR stores exception number on exception entry
//   - Test EPSR stores T-bit and IT/ICI state
//   - Test MRS/MSR read/write via software access port
//   - Test combined xPSR read returns all three registers merged
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
import alu_pkg::*;

module xpsr_tb;

    //DUT port signals
    logic              clk;
    alu_flags_t    flags_in;
    logic          write_en;
    logic [1:0]   read_addr;
    logic [31:0]  read_data;

    //Internal TB signals and variables
    integer pass_count;
    integer fail_count;
    integer test_count;

    xPSR dut(
        .clk(clk),
        .flags_in(flags_in),
        .write_en(write_en),
        .read_addr(read_addr),
        .read_data(read_data)
    );

    //Setup TB Clk
    always #5 clk = ~clk;  // 10ns period = 100MHz

    //Setup VCD Trace dump
    initial begin
        $dumpfile("xpsr_tb.vcd");
        $dumpvars(0, xpsr_tb);
    end

    // Helper task - write flags then verify APSR bits [31:28]
    task test_flag_write(
        input alu_flags_t flags,
        input string test_name
    );
        logic [31:0] expected;
        expected = {flags, 28'b0};

        flags_in = flags;
        write_en = 1;
        @(posedge clk);
        #1; // Allow flip-flop output to settle after clock edge
        write_en = 0;

        // Read APSR (addr 0)
        read_addr = 2'd0;
        #1;

        test_count++;
        if (read_data === expected) begin
            $display("[PASS] %s: got 0x%08h", test_name, read_data);
            pass_count++;
        end else begin
            $display("[FAIL] %s: got 0x%08h, expected 0x%08h", test_name, read_data, expected);
            fail_count++;
        end
    endtask

    // Helper task - read from address and check expected value
    task test_read(
        input logic [1:0] addr,
        input logic [31:0] expected,
        input string test_name
    );
        read_addr = addr;
        #1;

        test_count++;
        if (read_data === expected) begin
            $display("[PASS] %s: addr=%0d got 0x%08h", test_name, addr, read_data);
            pass_count++;
        end else begin
            $display("[FAIL] %s: addr=%0d got 0x%08h, expected 0x%08h", test_name, addr, read_data, expected);
            fail_count++;
        end
    endtask

    initial begin
        //initialize signals
        $display("Initializing all internal signals");

        clk       = 0;
        flags_in  = '{n: 1'b0, z: 1'b0, c: 1'b0, v: 1'b0};
        write_en  = 0;
        read_addr = 2'd0;

        pass_count = 0;
        fail_count = 0;
        test_count = 0;

        // Wait 2 clock cycles
        @(posedge clk);
        @(posedge clk);

        //---------------------------------------------------------------------
        // Test: Individual flag bits map to correct APSR positions
        // APSR[31]=N, APSR[30]=Z, APSR[29]=C, APSR[28]=V
        //---------------------------------------------------------------------
        $display("\nTest: Individual flag bit mapping");

        test_flag_write('{n: 1'b1, z: 1'b0, c: 1'b0, v: 1'b0}, "N flag only");
        test_flag_write('{n: 1'b0, z: 1'b1, c: 1'b0, v: 1'b0}, "Z flag only");
        test_flag_write('{n: 1'b0, z: 1'b0, c: 1'b1, v: 1'b0}, "C flag only");
        test_flag_write('{n: 1'b0, z: 1'b0, c: 1'b0, v: 1'b1}, "V flag only");

        //---------------------------------------------------------------------
        // Test: All flags set and all flags cleared
        //---------------------------------------------------------------------
        $display("\nTest: All flags set/cleared");

        test_flag_write('{n: 1'b1, z: 1'b1, c: 1'b1, v: 1'b1}, "All flags set");
        test_flag_write('{n: 1'b0, z: 1'b0, c: 1'b0, v: 1'b0}, "All flags cleared");

        //---------------------------------------------------------------------
        // Test: Common flag combinations from real instructions
        //---------------------------------------------------------------------
        $display("\nTest: Common instruction flag patterns");

        // Result is zero: Z=1, N=0
        test_flag_write('{n: 1'b0, z: 1'b1, c: 1'b0, v: 1'b0}, "Zero result (Z=1)");

        // Negative result: N=1, Z=0
        test_flag_write('{n: 1'b1, z: 1'b0, c: 1'b0, v: 1'b0}, "Negative result (N=1)");

        // Unsigned overflow: C=1
        test_flag_write('{n: 1'b0, z: 1'b0, c: 1'b1, v: 1'b0}, "Unsigned overflow (C=1)");

        // Signed overflow: V=1, N=1 (positive + positive = negative)
        test_flag_write('{n: 1'b1, z: 1'b0, c: 1'b0, v: 1'b1}, "Signed overflow (N=1,V=1)");

        // SUB with borrow and negative: N=1, C=0
        test_flag_write('{n: 1'b1, z: 1'b0, c: 1'b0, v: 1'b0}, "SUB borrow negative (N=1,C=0)");

        //---------------------------------------------------------------------
        // Test: Write enable disabled should not modify APSR
        //---------------------------------------------------------------------
        $display("\nTest: Write enable disabled");

        // First write known flags
        test_flag_write('{n: 1'b1, z: 1'b0, c: 1'b1, v: 1'b0}, "Setup: N=1,C=1");

        // Attempt write with write_en=0
        flags_in = '{n: 1'b0, z: 1'b1, c: 1'b0, v: 1'b1};
        write_en = 0;
        @(posedge clk);

        read_addr = 2'd0;
        #1;

        test_count++;
        if (read_data === {1'b1, 1'b0, 1'b1, 1'b0, 28'b0}) begin
            $display("[PASS] Write enable disabled: flags unchanged, got 0x%08h", read_data);
            pass_count++;
        end else begin
            $display("[FAIL] Write enable disabled: flags changed! got 0x%08h, expected 0xA0000000", read_data);
            fail_count++;
        end

        //---------------------------------------------------------------------
        // Test: Only bits [31:28] are modified, lower bits stay zero
        //---------------------------------------------------------------------
        $display("\nTest: Only NZCV bits [31:28] are modified");

        test_flag_write('{n: 1'b1, z: 1'b1, c: 1'b1, v: 1'b1}, "All flags set");

        read_addr = 2'd0;
        #1;

        test_count++;
        if (read_data[27:0] === 28'b0) begin
            $display("[PASS] Lower bits [27:0] are zero: 0x%07h", read_data[27:0]);
            pass_count++;
        end else begin
            $display("[FAIL] Lower bits [27:0] non-zero: 0x%07h, expected 0x0000000", read_data[27:0]);
            fail_count++;
        end

        //---------------------------------------------------------------------
        // Test: Read from invalid address returns zero
        //---------------------------------------------------------------------
        $display("\nTest: Invalid address guard");

        test_read(2'd3, 32'b0, "Invalid addr 3 returns zero");

        //---------------------------------------------------------------------
        // Test: Read from IPSR (addr 1) and EPSR (addr 2)
        // These are not yet written to, so should read as uninitialized
        // TODO: Update these tests when IPSR/EPSR write logic is implemented
        //---------------------------------------------------------------------
        $display("\nTest: IPSR and EPSR read (no write logic yet)");
        $display("  [INFO] IPSR/EPSR reads skipped - registers have no write path yet");

        // Summary
        $display("\n==============================================");
        $display("  xPSR Test Summary");
        $display("==============================================");
        $display("  Total:  %0d", test_count);
        $display("  Passed: %0d", pass_count);
        $display("  Failed: %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0) begin
            $display("  ALL TESTS PASSED");
            $finish;
        end
        else begin
            $fatal(1, "  SOME TESTS FAILED");
        end
    end

endmodule
