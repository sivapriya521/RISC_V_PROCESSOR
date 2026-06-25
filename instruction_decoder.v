module instruction_decoder
(
  input  wire [31:0] i_instr,     // 32-bit instruction from IF/ID register

  //To Control Unit
  output wire [ 6:0] o_opcode,    // bits [6:0]   
  output wire [ 2:0] o_funct3,    // bits [14:12] 
  output wire [ 6:0] o_funct7,    // bits [31:25] 

  //  To Register File (contains adress)
  output wire [ 4:0] o_rs1,       // bits [19:15] 
  output wire [ 4:0] o_rs2,       // bits [24:20]

  output wire [ 4:0] o_rd,        // bits [11:7]  — destination register address

  //To Immediate Generator
  output wire [31:0] o_instr      // full instruction passed 
);

  assign o_opcode = i_instr[ 6: 0];   // always bits  6:0
  assign o_rd     = i_instr[11: 7];   // always bits 11:7
  assign o_funct3 = i_instr[14:12];   // always bits 14:12
  assign o_rs1    = i_instr[19:15];   // always bits 19:15
  assign o_rs2    = i_instr[24:20];   // always bits 24:20
  assign o_funct7 = i_instr[31:25];   // always bits 31:25

  assign o_instr  = i_instr;          // full word → Immediate Generator

endmodule