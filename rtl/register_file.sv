`timescale 1ns/1ps
//ANSI Style port definitions
module register_file #()
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  read_addr1,
    input  logic [3:0]  read_addr2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,
    input  logic [3:0]  write_addr,
    input  logic [31:0] write_data,
    input  logic        write_en
);


//Register array
logic [31:0] registers [16]; // General Purpose R0-R12, R13 = SP, R14 = LR, R15 = PC

//Intermediate signals and variables
integer  i;

    always_ff @( posedge clk ) begin : register_file_rst
        if (!rst_n) begin
            //clear all  General Purpose registers to default values
            for ( i =  0;  i < 12; i++ ) begin
                registers[i] <= 32'b0;
            end
        end
        if(write_en) begin
            registers[write_addr] <= write_data;
        end
    end

    //Read from register
    always_comb begin : read_registers
        read_data1 = registers[read_addr1];
        read_data2 = registers[read_addr2];
    end

endmodule
