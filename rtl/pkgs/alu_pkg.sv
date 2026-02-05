//-----------------------------------------------------------------------------
// Alu Package
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

package alu_pkg;

    // ALU operation codes
    typedef enum logic [3:0] {
        ALU_ADD = 4'b0000,
        ALU_SUB = 4'b0001,
        ALU_AND = 4'b0010, //bitwise
        ALU_ORR = 4'b0011, //bitwise
        ALU_EOR = 4'b0100, //bitwise
        ALU_LSL = 4'b0101, //logical
        ALU_LSR = 4'b0110, //logical
        ALU_ASR = 4'b0111  //logical
    } alu_op_t;

    // Condition flags
    typedef struct packed {
        logic n;  // Negative
        logic z;  // Zero
        logic c;  // Carry
        logic v;  // Overflow
    } alu_flags_t;

endpackage
