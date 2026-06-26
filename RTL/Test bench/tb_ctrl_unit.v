`timescale 1ns/1ps

module tb_ctrl_unit;
 
  reg  [6:0] r_opcode;
  reg  [2:0] r_funct3;
  reg  [6:0] r_funct7;
 
  wire [3:0] w_alu_ctrl;
  wire       w_alu_src, w_reg_write, w_mem_read, w_mem_write;
  wire       w_mem_to_reg, w_branch, w_jump, w_invalid;
 
  ctrl_unit dut
  (
    .i_opcode     (r_opcode),
    .i_funct3     (r_funct3),
    .i_funct7     (r_funct7),
    .o_alu_ctrl   (w_alu_ctrl),
    .o_alu_src    (w_alu_src),
    .o_reg_write  (w_reg_write),
    .o_mem_read   (w_mem_read),
    .o_mem_write  (w_mem_write),
    .o_mem_to_reg (w_mem_to_reg),
    .o_branch     (w_branch),
    .o_jump       (w_jump),
    .o_invalid    (w_invalid)
  );
 
  // ALU code 
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
 
  // Opcodes
  localparam OP_R      = 7'b0110011;
  localparam OP_I_ALU  = 7'b0010011;
  localparam OP_LOAD   = 7'b0000011;
  localparam OP_STORE  = 7'b0100011;
  localparam OP_BRANCH = 7'b1100011;
  localparam OP_JAL    = 7'b1101111;
  localparam OP_JALR   = 7'b1100111;
  localparam OP_LUI    = 7'b0110111;
  localparam OP_AUIPC  = 7'b0010111;
 
  integer pass_count, fail_count;
 
  task check;
    input [127:0] name;
    input [3:0]   exp_alu_ctrl;
    input         exp_alu_src, exp_reg_write, exp_mem_read;
    input         exp_mem_write, exp_mem_to_reg, exp_branch, exp_jump;
    begin
      #1;
    $display("----------------------------------------------");
      $display("TEST: %s  (opcode=%b funct3=%b funct7=%b)", name, r_opcode, r_funct3, r_funct7);
      $display("  alu_ctrl=%0d src=%b reg_write=%b mem_read=%b mem_write=%b mem_to_reg=%b branch=%b jump=%b invalid=%b", w_alu_ctrl, w_alu_src, w_reg_write, w_mem_read, w_mem_write, w_mem_to_reg, w_branch, w_jump, w_invalid);
 
      if (w_alu_ctrl   === exp_alu_ctrl   &&
          w_alu_src    === exp_alu_src    &&
          w_reg_write  === exp_reg_write  &&
          w_mem_read   === exp_mem_read   &&
          w_mem_write  === exp_mem_write  &&
          w_mem_to_reg === exp_mem_to_reg &&
          w_branch     === exp_branch     &&
          w_jump       === exp_jump)
      begin
        $display("  >>> PASS <<<");
        pass_count = pass_count + 1;
      end
      else
      begin
        $display("  *** FAIL ***");
        fail_count = fail_count + 1;
      end
    end
  endtask
 
  initial
  begin
    pass_count = 0;
    fail_count = 0;
 
    // 1. ADD (R-type, funct3=000, funct7[5]=0)
    r_opcode=OP_R; r_funct3=3'b000; r_funct7=7'b0000000;
    check("ADD", ALU_ADD, 1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 2. SUB (R-type, funct3=000, funct7[5]=1)
    r_opcode=OP_R; r_funct3=3'b000; r_funct7=7'b0100000;
    check("SUB", ALU_SUB, 1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 3. AND (R-type, funct3=111)
    r_opcode=OP_R; r_funct3=3'b111; r_funct7=7'b0000000;
    check("AND", ALU_AND, 1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 4. SRL (R-type, funct3=101, funct7[5]=0)
    r_opcode=OP_R; r_funct3=3'b101; r_funct7=7'b0000000;
    check("SRL", ALU_SRL, 1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 5. SRA (R-type, funct3=101, funct7[5]=1)
    r_opcode=OP_R; r_funct3=3'b101; r_funct7=7'b0100000;
    check("SRA", ALU_SRA, 1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 6. ADDI (I-type ALU, funct3=000)
    r_opcode=OP_I_ALU; r_funct3=3'b000; r_funct7=7'bx;
    check("ADDI", ALU_ADD, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 7. SRLI (I-type ALU, funct3=101, funct7[5]=0)
    r_opcode=OP_I_ALU; r_funct3=3'b101; r_funct7=7'b0000000;
    check("SRLI", ALU_SRL, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 8. SRAI (I-type ALU, funct3=101, funct7[5]=1)
    r_opcode=OP_I_ALU; r_funct3=3'b101; r_funct7=7'b0100000;
    check("SRAI", ALU_SRA, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 9. LW (Load) funct7 doesnt matter thus x
    r_opcode=OP_LOAD; r_funct3=3'b010; r_funct7=7'bx;
    check("LW", ALU_ADD, 1'b1,1'b1,1'b1,1'b0,1'b1,1'b0,1'b0);
 
    // 10. SW (Store)
    r_opcode=OP_STORE; r_funct3=3'b010; r_funct7=7'bx;
    check("SW", ALU_ADD, 1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0);
 
    // 11. BEQ (Branch)
    r_opcode=OP_BRANCH; r_funct3=3'b000; r_funct7=7'bx;
    check("BEQ", ALU_SUB, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0);
 
    // 12. JAL
    r_opcode=OP_JAL; r_funct3=3'bx; r_funct7=7'bx;
    check("JAL", ALU_ADD, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1);
 
    // 13. JALR
    r_opcode=OP_JALR; r_funct3=3'b000; r_funct7=7'bx;
    check("JALR", ALU_ADD, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1);
 
    // 14. LUI
    r_opcode=OP_LUI; r_funct3=3'bx; r_funct7=7'bx;
    check("LUI", ALU_LUI, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 15. AUIPC
    r_opcode=OP_AUIPC; r_funct3=3'bx; r_funct7=7'bx;
    check("AUIPC", ALU_AUIPC, 1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
 
    // 16. Invalid opcode
    r_opcode=7'b1111111; r_funct3=3'bx; r_funct7=7'bx;
    #1;
   
    if (w_invalid === 1'b1)
    begin
      $display("  >>> PASS <<<"); pass_count = pass_count + 1;
    end
    else
    begin
      $display("  *** FAIL ***"); fail_count = fail_count + 1;
    end
 
    $display("----------------------------------------------");
    $display("Results: %0d PASSED  /  %0d FAILED", pass_count, fail_count);
    $display("----------------------------------------------");
    $finish;
  end
 
endmodule