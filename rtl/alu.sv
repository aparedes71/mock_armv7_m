//-----------------------------------------------------------------------------
// Arithmetic Logic Unit (Alu)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
import alu_pkg::*;

//ANSI Style port definitions
module Alu #()
(
    input  alu_op_t     alu_opcode ,
    input  logic [31:0] data_in1   ,
    input  logic [31:0] data_in2   ,
    output logic[31:0]  data_out   ,
    output alu_flags_t flags_out
);

    //Internal signals
    logic [32:0] result;

    //ALu_op decoding and execution combinational logic
    always_comb begin : ALU_Execution

        case (alu_opcode)
            ALU_ADD: begin
                result = {1'b0, data_in1} + {1'b0, data_in2};  // packing on a zero for 33-bit + 33-bit = 32-bit result with carry at bit 33
            end
            ALU_SUB: begin
                result =  {1'b0, data_in1} - {1'b0, data_in2}; // packing on a zero for 33-bit + 33-bit = 32-bit result with carry at bit 33
            end
            ALU_AND: begin
                result = {1'b0, data_in1} & {1'b0, data_in2};
            end
            ALU_ORR: begin
                result = {1'b0, data_in1} | {1'b0, data_in2};
            end
            ALU_EOR: begin
                result = {1'b0, data_in1} ^ {1'b0, data_in2};
            end
            default: begin
                result = 33'b0;
            end
        endcase

    end

    //Logic for setting of N( Negative),Z (Zero),C(Carry),and V (Overflow) flags
    always_comb begin : ALU_Flag_Assignment
        // N and Z same for all ops
        flags_out.n = result[31]; // sign bit
        flags_out.z = (result[31:0] == 32'h0); //ignore top bit result[32] as it is just the carry value

        // C and V depend on operation
        case (alu_opcode)
            ALU_ADD: begin
                flags_out.c = result[32];  // sum is 33-bit
                flags_out.v = (data_in1[31] == data_in2[31]) && (result[31] != data_in1[31]);
            end
            ALU_SUB: begin
                flags_out.c = ~result[32];  // diff is 33-bit
                flags_out.v = (data_in1[31] != data_in2[31]) && (result[31] != data_in1[31]);
            end
            default: begin
                flags_out.c = 1'b0;
                flags_out.v = 1'b0;
            end
        endcase
    end

    //Combinatorial output assignments
    assign data_out = result[31:0]; //Dropping carry bit as that is accounted for in the flags

endmodule
