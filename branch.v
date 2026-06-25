//=====================================================================
// branch_comparator.v
// Single-Cycle CPU — Branch Decision Logic
//
// Purpose:
//   Decides taken/not-taken for all 6 RV32I branch instructions.
//   Kept separate from the main ALU because BLT/BGE need *signed*
//   comparison and BLTU/BGEU need *unsigned* comparison -- both are
//   awkward to derive cleanly from a subtraction result alone.
//=====================================================================

module branch
(
  input  wire [2:0]  i_funct3,
  input  wire [31:0] i_rs1,
  input  wire [31:0] i_rs2,
  output reg         o_taken
);

  // Branch funct3 encodings (RV32I)
  localparam F3_BEQ  = 3'b000;
  localparam F3_BNE  = 3'b001;
  localparam F3_BLT  = 3'b100;
  localparam F3_BGE  = 3'b101;
  localparam F3_BLTU = 3'b110;
  localparam F3_BGEU = 3'b111;

  always @(*)
  begin
    case (i_funct3)
      F3_BEQ : o_taken = (i_rs1 == i_rs2);
      F3_BNE : o_taken = (i_rs1 != i_rs2);
      F3_BLT : o_taken = ($signed(i_rs1) <  $signed(i_rs2));
      F3_BGE : o_taken = ($signed(i_rs1) >= $signed(i_rs2));
      F3_BLTU: o_taken = (i_rs1 <  i_rs2);   // unsigned by default
      F3_BGEU: o_taken = (i_rs1 >= i_rs2);   // unsigned by default
      default: o_taken = 1'b0;
    endcase
  end

endmodule