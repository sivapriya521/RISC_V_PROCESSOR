`timescale 1ns/1ps

module pc_tb;

  reg         r_clk;
  reg         r_rst_n;
  reg         r_pc_write;
  reg         r_pc_sel;
  reg  [31:0] r_branch_target;
  wire [31:0] w_pc;
  wire [31:0] w_pc_plus4;

  pc dut
  (
    .clk            (r_clk),
    .reset_n          (r_rst_n),
    .wr_en       (r_pc_write),
    .b_sel         (r_pc_sel),
    .b_target  (r_branch_target),
    .pc             (w_pc),
    .pc_4      (w_pc_plus4)
  );

  // Clock: 10ns period 
  initial r_clk = 1'b0;
  always #5 r_clk = ~r_clk;

  initial // intial means at time 0
  begin

    // Reset
    r_rst_n         = 1'b0;
    r_pc_write      = 1'b1;
    r_pc_sel        = 1'b0;
    r_branch_target = 32'h0000_0000;
    @(posedge r_clk);// wait until pos edge
    @(posedge r_clk);
    r_rst_n = 1'b1;

    // Sequential fetch: PC should step +4 each cycle (0,4,8,C,10)
    repeat (4) @(posedge r_clk);

    // Stall: for 2 cycles 
    r_pc_write = 1'b0;
    repeat (2) @(posedge r_clk);
    r_pc_write = 1'b1;

    // Branch resolved 
    r_pc_sel        = 1'b1;
    r_branch_target = 32'h0000_0040;
    @(posedge r_clk);
    r_pc_sel = 1'b0;

    // Resume sequential fetch from the branch target
    repeat (4) @(posedge r_clk);

    $display("Final PC = %h", w_pc);
    $finish;
  end

  always @(posedge r_clk)
    $display("t=%0t  rst_n=%b  pc_write=%b  pc_sel=%b  PC=%h  PC+4=%h",
              $time, r_rst_n, r_pc_write, r_pc_sel, w_pc, w_pc_plus4);

endmodule