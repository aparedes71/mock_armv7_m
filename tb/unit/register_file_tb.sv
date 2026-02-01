//-----------------------------------------------------------------------------
// Register File Unit Testbench
// Directed tests for basic functionality verification
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module register_file_tb;


    logic        clk       ;
    logic        rst_n     ;
    logic [3:0]  read_addr1;
    logic [3:0]  read_addr2;
    logic [31:0] read_data1;
    logic [31:0] read_data2;
    logic [3:0]  write_addr;
    logic [31:0] write_data;
    logic        write_en  ;

    logic [31:0]   mock_data;
    logic [3:0]   mock_address;
    integer i;
    integer pass_count;
    integer fail_count;
    integer test_count;

    register_file  dut(
        .clk(clk),
        .rst_n(rst_n),
        .read_addr1(read_addr1),
        .read_data1(read_data1),
        .read_addr2(read_addr2),
        .read_data2(read_data2),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_en(write_en)
    );

    always #5 clk = ~clk;  // 10ns period = 100MHz

    //Setup VCD Trace dump
    initial begin
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);
    end

    initial begin
        //initialize signals
        $display("Initilizing all internal signals and booting in reset state due to active low");

        //signals bound to dut ports
        clk        = 0;
        rst_n      = 0;
        read_addr1 = 4'b0;
        read_addr2 = 4'b0;
        read_data1 = 32'b0;
        read_data2 = 32'b0;
        write_addr = 4'b0;
        write_data = 32'b00;
        write_en   = 0;

        //TB signals
        pass_count = 0;
        fail_count = 0;
        test_count = 0;
        mock_data = 1;
        mock_address = 4'b0;

        // Wait 2 clock cycles
        @(posedge clk);
        @(posedge clk);

        $display("Leaving Reset State");
        rst_n = 1'b1;

        $display("Test : Testing write and read capability");
        $display("Writing all registers");

        for( i = 0; i < 16; i++) begin : write_loop
            write_en = 1;
            write_addr = i[3:0];
            write_data = i + 1;  // R0=1, R1=2, R2=3, etc.
            @(posedge clk);  // Write happens on this edge
        end
        write_en = 0;

        // Wait one cycle for last write to complete
        @(posedge clk);

        mock_address = 4'b0;
        mock_data = 1;

        $display("Reading(combinational) all registers using 2 read ports at a time");
        for( i = 0; i < 8; i++) begin: read_loop
            read_addr1 = mock_address;
            read_addr2 = mock_address + 1;
            #0;  // Allow combinational logic to propagate by one delta cycle

            test_count++;
            if(read_data1 === mock_data) begin
                $display("[PASS] Port1 Read R%0d: got 0x%08h, expected 0x%08h", mock_address, read_data1, mock_data);
                pass_count++;
            end else begin
                $warning("[FAIL] Port1 Read R%0d: got 0x%08h, expected 0x%08h", mock_address, read_data1, mock_data);
                fail_count++;
            end

            test_count++;
            if(read_data2 === (mock_data + 1)) begin
                $display("[PASS] Port2 Read R%0d: got 0x%08h, expected 0x%08h", mock_address + 1, read_data2, mock_data + 1);
                pass_count++;
            end else begin
                $warning("[FAIL] Port2 Read R%0d: got 0x%08h, expected 0x%08h", mock_address + 1, read_data2, mock_data + 1);
                fail_count++;
            end

            mock_address = mock_address + 2;
            mock_data = mock_data + 2;
            @(posedge clk);
        end

        //---------------------------------------------------------------------
        // Test: Write enable disabled should not modify register
        //---------------------------------------------------------------------
        $display("\nTest : Write enable disabled - attempting write to R5");
        write_en = 0;  // Disabled
        write_addr = 4'd5;
        write_data = 32'hFFFFFFFF;
        @(posedge clk);
        @(posedge clk);  // Extra cycle to ensure no write happens

        read_addr1 = 4'd5;
        #1;
        test_count++;
        if (read_data1 === 32'd6) begin  // R5 should still have value 6
            $display("[PASS] Write enable test: R5 unchanged, got 0x%08h", read_data1);
            pass_count++;
        end else begin
            $warning("[FAIL] Write enable test: R5 changed! got 0x%08h, expected 0x00000006", read_data1);
            fail_count++;
        end

        //---------------------------------------------------------------------
        // Test: Reset clears registers R0-R11
        //---------------------------------------------------------------------
        $display("\nTest : Reset state - verifying R0-R11 cleared to zero");
        rst_n = 0;  // Assert reset
        @(posedge clk);
        @(posedge clk);  // Hold reset for 2 cycles

        // Check R0-R11 are cleared (RTL only resets R0-R11)
        for ( i = 0; i < 12; i++) begin : reset_check_loop
            read_addr1 = i[3:0];
            #1;
            test_count++;
            if (read_data1 === 32'd0) begin
                $display("[PASS] Reset test: R%0d = 0x%08h", i, read_data1);
                pass_count++;
            end else begin
                $warning("[FAIL] Reset test: R%0d = 0x%08h, expected 0x00000000", i, read_data1);
                fail_count++;
            end
        end

        rst_n = 1;  // Deassert reset
        @(posedge clk);

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

