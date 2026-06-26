//=====================================================================
// single_cycle_cpu.v
// Top-level Single-Cycle RISC-V (RV32I) Processor
//
// Wires together: program_counter, instruction_memory,
// instruction_decoder, imm_gen, control_unit, reg_file, ALU,
// data_memory, plus glue logic (operand muxes, write-back mux,
// branch/jump target adder, branch_comparator) that doesn't live
// in any single module.
//
// One instruction completes, start to finish, every clock cycle --
// that's what "single-cycle" means. No stalls, no pipeline
// registers, no forwarding: i_pc_write is wired permanently high.
//=====================================================================

module single_cycle
(
  input wire i_clk,
  input wire i_rst_n
);

  //=================================================================
  // Opcode / ALU-code constants needed only for top-level muxing
  // (everything else lives inside control_unit.v / imm_gen.v)
  //=================================================================
  localparam OP_LUI    = 7'b0110111;  // to check in EX stage whether a =0, reg rs1 or pc
  localparam OP_AUIPC  = 7'b0010111;
  localparam OP_JALR   = 7'b1100111;

  localparam ALU_ADD   = 4'd0;
  localparam ALU_LUI   = 4'd10;
  localparam ALU_AUIPC = 4'd11;

  //=================================================================
  // IF: Program Counter + Instruction Memory
  //=================================================================
  wire [31:0] w_pc, pc_4, w_instr,b_target;
  wire        w_im_misalign;     // unused here, available for debug
  wire        b_sel;

  pc u_pc
  (
    .clk            (i_clk),
    .reset_n        (i_rst_n),
    .wr_en          (1'b1),         // single-cycle never stalls, so w_e always high
    .b_sel          (b_sel),
    .b_target       (b_target),
    .pc             (w_pc),
    .pc_4           (pc_4 )
  );

  instruction_memory u_imem
  (
    .i_pc       (w_pc),
    .o_instr    (w_instr),
    .o_misalign (w_im_misalign)
  );

  //=================================================================
  // ID: Decode + Immediate + Control
  //=================================================================
  wire [6:0]  w_opcode;
  wire [2:0]  w_funct3;
  wire [6:0]  w_funct7;
  wire [4:0]  w_rs1, w_rs2, w_rd;
  wire [31:0] w_instr_full;

  instruction_decoder u_idec
  (
    .i_instr  (w_instr),
    .o_opcode (w_opcode),
    .o_funct3 (w_funct3),
    .o_funct7 (w_funct7),
    .o_rs1    (w_rs1),
    .o_rs2    (w_rs2),
    .o_rd     (w_rd),
    .o_instr  (w_instr_full)
  );

  wire [31:0] w_imm;

  immediate_gen u_immgen
  (
    .i_instr (w_instr_full),
    .o_imm   (w_imm)
  );

  wire [3:0] w_alu_ctrl;
  wire       w_alu_src, w_reg_write, w_mem_read, w_mem_write, w_mem_to_reg, w_branch, w_jump, w_invalid;

  ctrl_unit u_cu
  (
    .i_opcode     (w_opcode),
    .i_funct3     (w_funct3),
    .i_funct7     (w_funct7),
    .o_alu_ctrl   (w_alu_ctrl), //4 bits
    .o_alu_src    (w_alu_src),
    .o_reg_write  (w_reg_write),
    .o_mem_read   (w_mem_read),
    .o_mem_write  (w_mem_write),
    .o_mem_to_reg (w_mem_to_reg),
    .o_branch     (w_branch),
    .o_jump       (w_jump),
    .o_invalid    (w_invalid)
  );

  //=================================================================
  // Register File (read happens same cycle as decode; write
  // happens at the end of this same cycle, via rd_dat below)
  wire [31:0] w_rs1_dat, w_rs2_dat;
  wire [31:0] w_wb_data;

  reg_file u_rf // rs and rd adress available from decoder but where they get the value in it, it will stored used ld sw instruction initialy
  (
    .clk     (i_clk),
    .we      (w_reg_write),
    .rs1_ad  (w_rs1),
    .rs2_ad  (w_rs2),
    .rd_ad   (w_rd),
    .rd_dat  (w_wb_data),
    .rs1_dat (w_rs1_dat),
    .rs2_dat (w_rs2_dat)
  );

  //=================================================================
  // EX: ALU operand muxes + ALU
  wire [31:0] w_alu_in_a;
  wire [31:0] w_alu_in_b;
  wire [3:0]  w_alu_ctrl_final;
  wire [31:0] w_alu_result;

  // Operand A: rs1 normally; AUIPC needs PC; LUI needs a hard 0 so that 0 + imm = imm falls straight out of the adder.
  assign w_alu_in_a = (w_opcode == OP_AUIPC) ? w_pc  :(w_opcode == OP_LUI)   ? 32'd0  :   w_rs1_dat;

  // Operand B: register or immediate, mux using control unit's alu_src
  assign w_alu_in_b = w_alu_src ? w_imm : w_rs2_dat;

  //  alu has no dedicated LUI/AUIPC opcode. Both just need a plain ADD once operand A has already been forced to 0 / PC above
  assign w_alu_ctrl_final = (w_alu_ctrl == ALU_LUI || w_alu_ctrl == ALU_AUIPC)  ? ALU_ADD : w_alu_ctrl;

  ALU u_alu
  (
    .a        (w_alu_in_a),
    .b        (w_alu_in_b),
    .ctrl_sig (w_alu_ctrl_final),
    .result   (w_alu_result)
  );

  //=================================================================
  // MEM: Data memory
  wire [31:0] w_mem_rd_data;

  datamemory u_dmem
  (
    .i_clk       (i_clk),
    .i_mem_read  (w_mem_read),
    .i_mem_write (w_mem_write),
    .i_funct3    (w_funct3),
    .i_addr      (w_alu_result),
    .i_wr_data   (w_rs2_dat),    // always stored in rs2
    .o_rd_data   (w_mem_rd_data)
  );

  //=================================================================
  // WB: Write-back source mux
  //   Priority: JAL/JALR write PC+4 (return address) eg jal x1, target ; Loads write memory data ; Everything else from ALU result
  assign w_wb_data = w_jump ? pc_4    :  w_mem_to_reg ? w_mem_rd_data : w_alu_result;

  //=================================================================
  // Branch / Jump target adder + comparator
  //   A dedicated adder, separate from the main ALU (which is busy
  //   doing the branch comparison, or unused for jumps).
  //=================================================================
  assign b_target = (w_opcode == OP_JALR) ? (w_rs1_dat + w_imm)  : (w_pc  + w_imm);

  wire w_branch_taken;

  branch u_bcmp
  (
    .i_funct3 (w_funct3),
    .i_rs1    (w_rs1_dat),
    .i_rs2    (w_rs2_dat),
    .o_taken  (w_branch_taken)
  );

  // PC redirects on any unconditional jump, or a taken branch
  assign b_sel = w_jump | (w_branch & w_branch_taken);

endmodule