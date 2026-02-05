//-----------------------------------------------------------------------------
// Special Purpose Program Status Registers
// Application Program Status Register, APSR
// Interrupt Program Status Register, IPSR
// Execution Program Status Register, EPSR
// TODO: Not including logic for IPSR, EPSR at this time they can be integrated in the future
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
import alu_pkg::*;

//ANSI Style port definitions
module xPSR #()
(
    input  logic              clk,
    input  alu_flags_t    flags_in,
    input  logic          write_en,
    //TODO: These are for IPSR and EPSR if I decide to integrate them
    // input  logic [1:0]  write_addr,
    // input logic [31:0] write_data, //single port read and writes for this case
    input  logic [1:0]   read_addr,
    output logic [31:0]  read_data
);

//Individual status registers (avoids Verilator sensitivity issues with unpacked array variable indexing)
logic [31:0] apsr; // APSR : addr 0
logic [31:0] ipsr; // IPSR : addr 1 - TODO: add write logic when integrated
logic [31:0] epsr; // EPSR : addr 2 - TODO: add write logic when integrated


    always_ff @( posedge clk ) begin : APSR_write
        if (write_en) begin
            apsr <= {flags_in, apsr[27:0]}; //TODO: Q flag bit 27 not yet implemented
        end
    end

    always_comb begin : read_port
        case (read_addr)
            2'd0:    read_data = apsr;
            2'd1:    read_data = ipsr;
            2'd2:    read_data = epsr;
            default: read_data = 32'b0;
        endcase
    end

`ifdef SIMULATION
    always @(posedge clk) begin
        if (read_addr >= 2'd3)
            $warning("xPSR: invalid read_addr %0d supplied from Control Logic", read_addr);
    end
`endif

endmodule
