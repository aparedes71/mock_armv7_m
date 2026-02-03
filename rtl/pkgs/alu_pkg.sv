package alu_pkg;

    // ALU operation codes
    typedef enum logic [3:0] {
        ALU_ADD = 4'b0000,
        ALU_SUB = 4'b0001,
        ALU_AND = 4'b0010,
        ALU_ORR = 4'b0011,
        ALU_EOR = 4'b0100
    } alu_op_t;

    // Condition flags
    typedef struct packed {
        logic n;  // Negative
        logic z;  // Zero
        logic c;  // Carry
        logic v;  // Overflow
    } alu_flags_t;

endpackage
