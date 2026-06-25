`timescale 1ns/1ps
//=====================================================================
// tb_single_cycle_cpu.v
// Runs the sample program (program.hex) through the whole datapath
// and checks final register/memory values.
//
// Program recap (see program.hex comments for full disassembly):
//   x1=5  x2=10  x3=15(x1+x2)  x4=5(x2-x1)  x5=0(x1&x2)  x6=15(x1|x2)
//   mem[0]=15 (SW x3)   x7=15 (LW from mem[0])
//   BEQ x1,x2 -> not taken (5 != 10)
//   x8=99
//   JAL x1,0  -> infinite self-loop; x1 becomes the JAL's own
//               address+4 (the return address), overwriting the
//               earlier x1=5
//
// NOTE ON HIERARCHICAL PEEKING:
//   reg_file's contents aren't exposed on any port except whichever
//   address happens to be presented by the live instruction stream.
//   For testbench verification only (not synthesizable, not part of
//   the design), we reach directly into the DUT's internal register
//   array via dot-path: dut.u_rf.reg_f[n]. This is a common, accepted
//   simulation-only technique for checking internal state.
//=====================================================================
module tb_single_cycle;

  reg r_clk = 0;
  reg r_rst_n;

  single_cycle dut
  (
    .i_clk   (r_clk),
    .i_rst_n (r_rst_n)
  );

  always #5 r_clk = ~r_clk;   // 10ns period

  integer pass_count, fail_count;

  task check_reg;
    input [127:0] name;
    input [4:0]   reg_num;
    input [31:0]  exp_val;
    begin
      $display("  %s = x%0d = 0x%h  (expect 0x%h)",
                name, reg_num, dut.u_rf.reg_f[reg_num], exp_val);
      if (dut.u_rf.reg_f[reg_num] === exp_val)
      begin
        $display("    >>> PASS <<<");
        pass_count = pass_count + 1;
      end
      else
      begin
        $display("    *** FAIL ***");
        fail_count = fail_count + 1;
      end
    end
  endtask

  initial
  begin
    pass_count = 0;
    fail_count = 0;

    // Reset for 2 cycles
    r_rst_n = 1'b0;
    @(posedge r_clk);
    @(posedge r_clk);
    r_rst_n = 1'b1;

    // 10 instructions execute before JAL (ADDI x1..ADDI x2..ADD..SUB
    // ..AND..OR..SW..LW..BEQ(not taken)..ADDI x8) -- check state here,
    // BEFORE JAL overwrites x1, so x1 still shows its original value.
    repeat (10) @(posedge r_clk);
    #1;

    $display("════════════════════════════════════════");
    $display("State after 10 instructions (before JAL):");
    $display("════════════════════════════════════════");
    check_reg("ADDI x1,x0,5",   5'd1, 32'd5);
    check_reg("ADDI x2,x0,10",  5'd2, 32'd10);
    check_reg("ADD  x3,x1,x2",  5'd3, 32'd15);
    check_reg("SUB  x4,x2,x1",  5'd4, 32'd5);
    check_reg("AND  x5,x1,x2",  5'd5, 32'd0);
    check_reg("OR   x6,x1,x2",  5'd6, 32'd15);
    check_reg("LW   x7,0(x0)",  5'd7, 32'd15);
    check_reg("ADDI x8,x0,99",  5'd8, 32'd99);

    // Check the SW actually landed in data memory
    $display("  mem word[0] = 0x%h (expect 0x0000000F)",
              {dut.u_dmem.r_mem[3], dut.u_dmem.r_mem[2],
               dut.u_dmem.r_mem[1], dut.u_dmem.r_mem[0]});
    if ({dut.u_dmem.r_mem[3], dut.u_dmem.r_mem[2],
         dut.u_dmem.r_mem[1], dut.u_dmem.r_mem[0]} === 32'd15)
    begin
      $display("    >>> PASS <<<"); pass_count = pass_count + 1;
    end
    else
    begin
      $display("    *** FAIL ***"); fail_count = fail_count + 1;
    end

    // One more cycle executes the JAL -- now x1 should hold the
    // JAL instruction's own PC+4 (the return address), since JAL
    // always writes the link register regardless of where it jumps.
    @(posedge r_clk);
    #1;
    $display("════════════════════════════════════════");
    $display("State after JAL executes:");
    $display("════════════════════════════════════════");
    check_reg("JAL x1,0 (link addr)", 5'd1, 32'h0000002C);

    // Confirm the CPU is now looping on the JAL forever: PC should
    // equal 0x28 every cycle from here on (JAL jumps to itself).
    repeat (3) @(posedge r_clk);
    #1;
    $display("  PC after looping = 0x%h (expect 0x00000028)", dut.w_pc);
    if (dut.w_pc === 32'h00000028)
    begin
      $display("    >>> PASS <<<  (infinite loop confirmed)");
      pass_count = pass_count + 1;
    end
    else
    begin
      $display("    *** FAIL ***");
      fail_count = fail_count + 1;
    end

    $display("════════════════════════════════════════");
    $display("Results: %0d PASSED  /  %0d FAILED", pass_count, fail_count);
    $display("════════════════════════════════════════");
    $finish;
  end

endmodule