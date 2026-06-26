
// RV32I immediate encodings (bit positions in the instruction):
//
//   I-type : imm[11:0]  = instr[31:20]
//   S-type : imm[11:5]  = instr[31:25], imm[4:0] = instr[11:7]
//   B-type : imm[12]    = instr[31],    imm[10:5] = instr[30:25]
//            imm[4:1]   = instr[11:8],  imm[11]   = instr[7]
//            (imm[0] is always 0 — branch targets are 2-byte aligned
//             at minimum, but RV32I only uses even offsets)
//   U-type : imm[31:12] = instr[31:12], imm[11:0] = 0
//   J-type : imm[20]    = instr[31],    imm[10:1] = instr[30:21]
//            imm[11]    = instr[20],    imm[19:12]= instr[19:12]
//            (imm[0] is always 0)
//
// All formats sign-extend using the instruction's MSB (instr[31]),


module immediate_gen
(
  input  wire [31:0] i_instr,   
  output reg  [31:0] o_imm      // sign-extended version outputted
);

  wire [6:0] opcode = i_instr[6:0]; // to select the immediate format

  localparam OP_I_ALU  = 7'b0010011; // ADDI, ANDI, ORI, XORI, SLTI, ...
  localparam OP_LOAD   = 7'b0000011; // LB, LH, LW, LBU, LHU
  localparam OP_JALR   = 7'b1100111; // JALR (also I-type immediate)
  localparam OP_STORE  = 7'b0100011; // SB, SH, SW
  localparam OP_BRANCH = 7'b1100011; // BEQ, BNE, BLT, BGE, BLTU, BGEU
  localparam OP_LUI    = 7'b0110111; // LUI
  localparam OP_AUIPC  = 7'b0010111; // AUIPC
  localparam OP_JAL    = 7'b1101111; // JAL
  
// we construct back the immediate value as per risc v isa 
  always @(*)
  begin
    case (opcode)

      // I-TYPE  imm[11:0] = instr[31:20], sign-extended
      OP_I_ALU, OP_LOAD, OP_JALR: o_imm = {{20{i_instr[31]}}, i_instr[31:20]};


      //  S-TYPE imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
      OP_STORE:o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};

      // B-TYPE  imm[12]=instr[31], imm[11]=instr[7],
      //   imm[10:5]=instr[30:25], imm[4:1]=instr[11:8], imm[0]=0
      OP_BRANCH:o_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};


      //  U-TYPE imm[31:12] = instr[31:12], lower 12 bits = 0 (no sign extension needed — already fills the upper bits)
      OP_LUI, OP_AUIPC: o_imm = {i_instr[31:12], 12'b0};

      //  J-TYPE imm[20]=instr[31], imm[19:12]=instr[19:12],
      //   imm[11]=instr[20], imm[10:1]=instr[30:21], imm[0]=0
      OP_JAL:o_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

      // R-TYPE and other: no immediate field
      default:
        o_imm = 32'b0;

    endcase
  end

endmodule