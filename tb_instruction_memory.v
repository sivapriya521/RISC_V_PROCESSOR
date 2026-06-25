`timescale 1ns/1ps

module instruction_memory_tb;

  reg  [31:0] r_pc;
  wire [31:0] w_instr;
  wire        w_misalign;

  instruction_memory #(
    .DEPTH    (256),
    .HEX_FILE ("C:/Users/kmsiv/OneDrive/Documents/preps/risc v 5 pipeline/implementation/program.hex")
  )
  dut
  (
    .i_pc       (r_pc),
    .o_instr    (w_instr),
    .o_misalign (w_misalign)
  );

  integer pass_count, fail_count;

  task check;
    input [127:0] name;
    input [31:0]  pc_val;
    input [31:0]  exp_instr;
    input         exp_misalign;
    begin
      r_pc = pc_val;
      #1;                           // there's a tiny propagation delay in hardware.thus doesnt get w_instr immediately like in ideal combinational case.
      $display("--------------------------------------------------");      
      $display("TEST: %s", name);   //%s = print as string
      $display("  PC = 0x%h  → instr = 0x%h  (expect 0x%h)", r_pc, w_instr, exp_instr);
      $display("  misalign = %b  (expect %b)", w_misalign, exp_misalign);

      if (w_instr === exp_instr && w_misalign === exp_misalign) // === used here
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

    // PC=0 ; mem[0] = ADDI x1,x0,5  = 0x00500093
    check("PC=0x00 (word 0)", 32'h00000000, 32'h00500093, 1'b0);

    // PC=0x04 -> mem[1] = ADDI x2,x0,10 = 0x00A00113
    check("PC=0x04 (word 1)", 32'h00000004, 32'h00A00113, 1'b0);

    // PC=0x08 -> mem[2] = ADD x3,x1,x2  = 0x00208133
    check("PC=0x08 (word 2)", 32'h00000008, 32'h00208133, 1'b0);

    // PC=0x18 -> mem[6] = SW x3,0(x0)   = 0x00302023
    check("PC=0x18 (word 6)", 32'h00000018, 32'h00302023, 1'b0);

    // PC=0x28 -> mem[10] = JAL x1,0     = 0x0000006F
    check("PC=0x28 (word 10)", 32'h00000028, 32'h0000006F, 1'b0);

    // PC=0x2C -> first NOP padding word = 0x00000013
    check("PC=0x2C (NOP pad)", 32'h0000002C, 32'h00000013, 1'b0);

    // Misalignment test: PC=0x02 (not 4-byte aligned)
    check("PC=0x02 (misaligned)", 32'h00000002, 32'h00500093, 1'b1);

  $display("--------------------------------------------------");    
  $display("Results: %0d PASSED  /  %0d FAILED", pass_count, fail_count);
  $display("--------------------------------------------------");   
  $finish;
  end

endmodule