//-----------------------------------------------------------------------------
// Arithmetic Logic Unit (Alu)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
import alu_pkg::*;

//ANSI Style port definitions
module Alu #()
(
    input  alu_op_t     alu_ops  ,
    input  logic [31:0] data_in1 ,
    input  logic [31:0] data_in2 ,
    output logic[31:0]  data_out ,
    output alu_flags_t flags_out
);




endmodule
