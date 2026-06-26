`timescale 1ns/1ps

module instruction_decoder2_tb;

reg  [31:0] r_instr;

wire [6:0]  w_opcode;
wire [2:0]  w_funct3;
wire [6:0]  w_funct7;
wire [4:0]  w_rs1;
wire [4:0]  w_rs2;
wire [4:0]  w_rd;
wire [31:0] w_instr;

instruction_decoder dut
(
.i_instr (r_instr),

.o_opcode (w_opcode),
.o_funct3 (w_funct3),
.o_funct7 (w_funct7),

.o_rs1 (w_rs1),
.o_rs2 (w_rs2),
.o_rd  (w_rd),

.o_instr (w_instr)

);

initial begin

// TEST 1 : R-TYPE ADD
r_instr = 32'b0000000_00010_00001_000_00011_0110011;
#10;

// TEST 2 : R-TYPE SUB
r_instr = 32'b0100000_00100_00011_000_00101_0110011;
#10;

// TEST 3 : I-TYPE ADDI

r_instr = 32'b000000000101_00001_000_00010_0010011;
#10;


// TEST 4 : LOAD (LW)

r_instr = 32'b000000001000_00001_010_00110_0000011;
#10;


// TEST 5 : STORE (SW)

r_instr = 32'b0000000_00010_00001_010_01100_0100011;
#10;


// TEST 6 : BRANCH (BEQ)

r_instr = 32'b0_000001_00010_00001_000_0000_0_1100011;
#10;


// TEST 7 : LUI

r_instr = 32'b10101011110011011110_00111_0110111;
#10;


// TEST 8 : JAL

r_instr = 32'b0_0000001000_0_00000000_00001_1101111;
#10;


// TEST 9 : ALL ZEROS

r_instr = 32'h00000000;
#10;


// TEST 10 : ALL ONES

r_instr = 32'hFFFFFFFF;
#10;

$stop;


end

endmodule

