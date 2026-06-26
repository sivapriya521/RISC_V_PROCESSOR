// https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html reference
//   Takes the opcode/funct3/funct7 fields (from instruction_decoder)
//   and produces every control signal the rest of the pipeline needs:
//     - alu_ctrl   : which operation the ALU performs
//     - alu_src    : ALU's second operand source (register vs imm)
//     - reg_write  : does this instruction write back to a register?
//     - mem_read   : data memory read enable      (Load)
//     - mem_write  : data memory write enable     (Store)
//     - mem_to_reg : write-back source select     (ALU result vs mem data)
//     - branch     : conditional branch instruction
//     - jump       : unconditional jump (JAL/JALR)
//     - invalid    : unrecognized opcode (debug aid)

// This module has NO knowledge of register addresses or immediate values — it only looks at opcode/funct3/funct7 and decides *how* the instruction should be executed, not *what data* it uses.
 
module ctrl_unit
(
  input  wire [6:0] i_opcode, // from insstr decoder
  input  wire [2:0] i_funct3, // from insstr decoder
  input  wire [6:0] i_funct7, // from insstr decoder
 
  output reg  [3:0] o_alu_ctrl,
  output reg        o_alu_src,
  output reg        o_reg_write,
  output reg        o_mem_read,
  output reg        o_mem_write,
  output reg        o_mem_to_reg,
  output reg        o_branch,
  output reg        o_jump,
  output reg        o_invalid
);
 
  // Opcode constants (RV32I); specified isa
  // [1:0] are always 11 - to identify 32 bit instruction. there is compressed 16 bits instruction 
  localparam OP_R      = 7'b0110011;
  localparam OP_I_ALU  = 7'b0010011;
  localparam OP_LOAD   = 7'b0000011;
  localparam OP_STORE  = 7'b0100011;
  localparam OP_BRANCH = 7'b1100011;
  localparam OP_JAL    = 7'b1101111;
  localparam OP_JALR   = 7'b1100111;
  localparam OP_LUI    = 7'b0110111;
  localparam OP_AUIPC  = 7'b0010111;
 
  // funct3 constants — only meaningful for R-type / I-type ALU ops
  // specifies in isa
  localparam F3_ADD_SUB = 3'b000;
  localparam F3_SLL     = 3'b001; // shift left logical
  localparam F3_SLT     = 3'b010; // set less than
  localparam F3_SLTU    = 3'b011; // set less than unsigned
  localparam F3_XOR     = 3'b100;
  localparam F3_SR      = 3'b101; // SRL or SRA depending on funct7[5]
  localparam F3_OR      = 3'b110;
  localparam F3_AND     = 3'b111;
 
  // ALU control codes (4-bit flat encoding) — ALU module switches
  // ALU operated on these values outputted by ctrl unit
  //is an internal design choice. i can specify the value
  localparam ALU_ADD   = 4'd0;
  localparam ALU_SUB   = 4'd1;
  localparam ALU_AND   = 4'd2;
  localparam ALU_OR    = 4'd3;
  localparam ALU_XOR   = 4'd4;
  localparam ALU_SLL   = 4'd5;
  localparam ALU_SRL   = 4'd6;
  localparam ALU_SRA   = 4'd7;
  localparam ALU_SLT   = 4'd8;
  localparam ALU_SLTU  = 4'd9;
  localparam ALU_LUI   = 4'd10;
  localparam ALU_AUIPC = 4'd11;
 
  
  // Main decoding part — purely combinational
  always @(*)
  begin
    // Safe defaults —  NOP if opcode is unrecognized
    o_alu_ctrl   = ALU_ADD; // to execute nop we use add; add x0,x0,0;
    o_alu_src    = 1'b0;    // all these parameterss are written 0 so no changes occur
    o_reg_write  = 1'b0;
    o_mem_read   = 1'b0;
    o_mem_write  = 1'b0;
    o_mem_to_reg = 1'b0;
    o_branch     = 1'b0;
    o_jump       = 1'b0;
    o_invalid    = 1'b0;    // why zero?
 
    case (i_opcode)
 
      
      // R-TYPE: ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
      //   Both ALU operands come from registers.
      OP_R: begin
        o_reg_write = 1'b1;
        o_alu_src   = 1'b0;  // alu_src = 0  -> ALU B = rs2  ;alu_src = 1  -> ALU B = immediate // internally designed.
 
        case (i_funct3)
          F3_ADD_SUB: o_alu_ctrl = (i_funct7[5]) ? ALU_SUB : ALU_ADD; //  funct 7 : 0000000- add and 0100000 - sub
          F3_SLL    : o_alu_ctrl = ALU_SLL;
          F3_SLT    : o_alu_ctrl = ALU_SLT;
          F3_SLTU   : o_alu_ctrl = ALU_SLTU;
          F3_XOR    : o_alu_ctrl = ALU_XOR;
          F3_SR     : o_alu_ctrl = (i_funct7[5]) ? ALU_SRA : ALU_SRL; //funct7 is inputed as wire
          F3_OR     : o_alu_ctrl = ALU_OR;
          F3_AND    : o_alu_ctrl = ALU_AND;
          default   : o_invalid  = 1'b1;
        endcase
      end
 
      
      // I-TYPE ALU: ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
      // Second ALU operand is the sign-extended immediate.
      OP_I_ALU: begin
        o_reg_write = 1'b1;
        o_alu_src   = 1'b1;  // B input = immediate
 
        case (i_funct3)
          F3_ADD_SUB: o_alu_ctrl = ALU_ADD;   // ADDI (no sub-immediate)
          F3_SLL    : o_alu_ctrl = ALU_SLL;   // SLLI
          F3_SLT    : o_alu_ctrl = ALU_SLT;   // SLTI
          F3_SLTU   : o_alu_ctrl = ALU_SLTU;  // SLTIU
          F3_XOR    : o_alu_ctrl = ALU_XOR;   // XORI
          F3_SR     : o_alu_ctrl = (i_funct7[5]) ? ALU_SRA : ALU_SRL; // SRLI vs SRAI distinguished by imm[10]==funct7[5]
          //imm[4:0]  = shift amount (shamt) ; imm[11:5] = special encoding
          F3_OR     : o_alu_ctrl = ALU_OR;    // ORI
          F3_AND    : o_alu_ctrl = ALU_AND;   // ANDI
          default   : o_invalid  = 1'b1;
        endcase
      end
 
      // LOAD: LB LH LW LBU LHU
      //   ALU computes rs1 + imm → memory address.
      //   funct3 is directly extracted from the instruction and used by the memory logic in the same cycle to determine load/store width. means it is not decode in cntrl unit
      //   to the MEM stage so it can pick byte/half/word width.
      OP_LOAD:
      begin
        o_reg_write  = 1'b1;
        o_alu_src    = 1'b1;  // in alu, uses immediate value.
        o_mem_read   = 1'b1;
        o_mem_to_reg = 1'b1;   // write-back source = memory data
        o_alu_ctrl   = ALU_ADD;
      end
 
      // STORE: SB SH SW
      //   ALU computes rs1 + imm → memory address.
      //   No register write-back.
      OP_STORE:
      begin
        o_alu_src   = 1'b1;
        o_mem_write = 1'b1;
        o_alu_ctrl  = ALU_ADD;
      end
 
      // BRANCH: BEQ BNE BLT BGE BLTU BGEU
      //   ALU subtracts rs1-rs2; branch unit checks the result/flags.
      //   funct3 passed downstream to select which comparison to use.
      OP_BRANCH:
      begin
        o_branch   = 1'b1;
        o_alu_src  = 1'b0;     // compare result of  rs1 -rs2 
        o_alu_ctrl = ALU_SUB;
      end
 
      
      // JAL — PC_next = PC + imm_j ; rd = PC + 4 (return address)
      OP_JAL:
      begin
        o_jump      = 1'b1;
        o_reg_write = 1'b1;
        o_alu_src   = 1'b1;
        o_alu_ctrl  = ALU_ADD; // EX stage: PC + imm_j
      end
 
      // JALR — PC_next = rs1 + imm_i ; rd = PC + 4
      OP_JALR:
      begin
        o_jump      = 1'b1;
        o_reg_write = 1'b1;
        o_alu_src   = 1'b1;
        o_alu_ctrl  = ALU_ADD; // EX stage: rs1 + imm_i
      end
       
      // LUI — rd = imm_u  (ALU just passes the immediate through)     
      OP_LUI:
      begin
        o_reg_write = 1'b1;
        o_alu_src   = 1'b1;
        o_alu_ctrl  = ALU_LUI;
      end
 
      //-------------------------------------------------------------
      // AUIPC — rd = PC + imm_u
      //-------------------------------------------------------------
      OP_AUIPC:
      begin
        o_reg_write = 1'b1;
        o_alu_src   = 1'b1;
        o_alu_ctrl  = ALU_AUIPC;
      end
 
      // Unknown / unimplemented opcode
      default: begin 
       o_invalid = 1'b1;
      end
 
    endcase
  end
 
endmodule