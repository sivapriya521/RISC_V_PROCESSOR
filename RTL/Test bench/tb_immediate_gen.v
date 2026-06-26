`timescale 1ns/1ps

// Verifies immediate reconstruction for I/S/B/U/J formats,
// including both positive and negative (sign-extended) cases.
module immediate_gen_tb;

  reg  [31:0] r_instr;
  wire [31:0] w_imm;

  immediate_gen dut
  (
    .i_instr (r_instr),
    .o_imm   (w_imm)
  );

  integer pass_count, fail_count;

  task check;
    input [127:0] name;
    input [31:0]  exp_imm;
    begin
      #1;
      $display("--------------------------------------");
      $display("TEST: %s", name);
      $display("  instr = 0x%h", r_instr);
      $display("  imm   = 0x%h (%0d)  (expect 0x%h)", w_imm, $signed(w_imm), exp_imm);

      if (w_imm === exp_imm)
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

    // I-TYPE: ADDI x2, x1, 5   -> imm = +5
    r_instr = 32'b000000000101_00001_000_00010_0010011;
    check("I-type ADDI imm=+5", 32'd5);

    // I-TYPE: ADDI x2, x1, -1  -> imm[11:0] = 0xFFF, sign-extends to -1
    r_instr = 32'b111111111111_00001_000_00010_0010011;
    check("I-type ADDI imm=-1", 32'hFFFFFFFF);

    //--------------------------------------------------------------
    // LOAD: LW x6, 8(x1)   -> imm = +8 (same I-format encoding)
    //--------------------------------------------------------------
    r_instr = 32'b000000001000_00001_010_00110_0000011;
    check("LOAD LW imm=+8", 32'd8);

    //--------------------------------------------------------------
    // JALR x1, x5, 4   -> imm = +4 (I-format)
    //--------------------------------------------------------------
    r_instr = 32'b000000000100_00101_000_00001_1100111;
    check("JALR imm=+4", 32'd4);

    //--------------------------------------------------------------
    // S-TYPE: SW x2, 12(x1)
    //   imm[11:5]=0000000  imm[4:0]=01100  -> imm = 12
    //--------------------------------------------------------------
    r_instr = 32'b0000000_00010_00001_010_01100_0100011;
    check("S-type SW imm=+12", 32'd12);

    //--------------------------------------------------------------
    // S-TYPE: SW x2, -4(x1)
    //   -4 = 12'hFFC -> imm[11:5]=1111111 imm[4:0]=11100
    //--------------------------------------------------------------
    r_instr = 32'b1111111_00010_00001_010_11100_0100011;
    check("S-type SW imm=-4", 32'hFFFFFFFC);

    //--------------------------------------------------------------
    // B-TYPE: BEQ x1, x2, +16
    //   16 = bit4 set, all other imm bits 0
    //   imm[12]=0 imm[11]=0 imm[10:5]=000000 imm[4:1]=1000 imm[0]=0
    //--------------------------------------------------------------
    r_instr = 32'b0_000000_00010_00001_000_1000_0_1100011;
    check("B-type BEQ imm=+16", 32'd16);

    //--------------------------------------------------------------
    // B-TYPE: BNE x1, x2, -8
    //   -8 = 13'h1FF8 (13-bit signed) -> imm[12]=1 imm[11]=1
    //   imm[10:5]=111111 imm[4:1]=1100 imm[0]=0
    //   instr[31]=1(imm12) instr[7]=1(imm11) instr[30:25]=111111(imm10:5)
    //   instr[11:8]=1100(imm4:1)
    //--------------------------------------------------------------
    r_instr = 32'b1_111111_00010_00001_001_1100_1_1100011;
    check("B-type BNE imm=-8", 32'hFFFFFFF8);

    //--------------------------------------------------------------
    // U-TYPE: LUI x7, 0xABCDE
    //--------------------------------------------------------------
    r_instr = 32'b10101011110011011110_00111_0110111;
    check("U-type LUI imm=0xABCDE000", 32'hABCDE000);

    //--------------------------------------------------------------
    // U-TYPE: AUIPC x8, 1   -> imm = 1<<12 = 0x1000
    //--------------------------------------------------------------
    r_instr = 32'b00000000000000000001_01000_0010111;
    check("U-type AUIPC imm=0x1000", 32'h00001000);

    //--------------------------------------------------------------
    // J-TYPE: JAL x1, +256
    //   256 = bit8 set, all other imm bits 0
    //   imm[20]=0 imm[19:12]=00000000 imm[11]=0 imm[10:1]=0010000000
    //   instr[31]=imm[20]=0   instr[30:21]=imm[10:1]=0010000000
    //   instr[20]=imm[11]=0   instr[19:12]=imm[19:12]=00000000
    //--------------------------------------------------------------
    r_instr = 32'b0_0010000000_0_00000000_00001_1101111;
    check("J-type JAL imm=+256", 32'd256);

    //--------------------------------------------------------------
    // J-TYPE: JAL x1, -256
    //   -256 (32-bit) = 0xFFFFFF00. Low 21 bits give:
    //   imm[20]=1 imm[19:12]=11111111 imm[11]=1 imm[10:1]=1110000000
    //   instr[31]=imm[20]=1   instr[30:21]=imm[10:1]=1110000000
    //   instr[20]=imm[11]=1   instr[19:12]=imm[19:12]=11111111
    //--------------------------------------------------------------
    r_instr = 32'b1_1110000000_1_11111111_00001_1101111;
    check("J-type JAL imm=-256", 32'hFFFFFF00);

    //--------------------------------------------------------------
    // R-TYPE: ADD (no immediate field) -> imm should default to 0
    //---------------------------------
    r_instr = 32'b0000000_00010_00001_000_00011_0110011;
    check("R-type ADD imm=0 (default)", 32'd0);

    $display("--------------------------------");
    $display("Results: %0d PASSED  /  %0d FAILED", pass_count, fail_count);
    $display("--------------------------------");
    $finish;
  end

endmodule