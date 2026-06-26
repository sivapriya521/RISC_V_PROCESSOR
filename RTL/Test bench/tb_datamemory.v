`timescale 1ns/1ps
module tb_datamemory;

  reg         r_clk = 0;
  reg         r_mem_read, r_mem_write;
  reg  [2:0]  r_funct3;
  reg  [31:0] r_addr, r_wr_data;
  wire [31:0] w_rd_data;

  always #5 r_clk = ~r_clk;

  datamemory dut
  (
    .i_clk      (r_clk),
    .i_mem_read (r_mem_read),
    .i_mem_write(r_mem_write),
    .i_funct3   (r_funct3),
    .i_addr     (r_addr),
    .i_wr_data  (r_wr_data),
    .o_rd_data  (w_rd_data)
  );

  localparam F3_BYTE   = 3'b000;
  localparam F3_HALF   = 3'b001;
  localparam F3_WORD   = 3'b010;
  localparam F3_BYTE_U = 3'b100;
  localparam F3_HALF_U = 3'b101;

  integer pass_count, fail_count;

  task do_store;
    input [31:0] addr;
    input [31:0] data;
    input [2:0]  funct3;
    begin
      r_mem_write = 1'b1;
      r_mem_read  = 1'b0;
      r_addr      = addr;
      r_wr_data   = data;
      r_funct3    = funct3;
      @(posedge r_clk); #1;
      r_mem_write = 1'b0;
    end
  endtask

  task check_load;
    input [127:0] name;
    input [31:0]  addr;
    input [2:0]   funct3;
    input [31:0]  exp_data;
    begin
      r_mem_read = 1'b1;
      r_addr     = addr;
      r_funct3   = funct3;
      #1;
    $display("----------------------------------------------");
      $display("TEST: %s  addr=0x%h  → data=0x%h  (expect 0x%h)",
                name, addr, w_rd_data, exp_data);

      if (w_rd_data === exp_data)
      begin
        $display("  >>> PASS <<<");
        pass_count = pass_count + 1;
      end
      else
      begin
        $display("  *** FAIL ***");
        fail_count = fail_count + 1;
      end
      r_mem_read = 1'b0;
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;

    // 1. SW then LW 
    do_store(32'h00, 32'h12345678, F3_WORD);
    check_load("LW basic", 32'h00, F3_WORD, 32'h12345678);

    // 2. Verify little-endian byte layout directly
    check_load("LB byte0 (LSB)", 32'h00, F3_BYTE, 32'h00000078);
    check_load("LB byte3 (MSB)", 32'h03, F3_BYTE, 32'h00000012);
    // 0x12 has sign bit set → sign-extends to 0xFFFFFF12

    // 3. LBU on same byte — should NOT sign extend
    check_load("LBU byte3 ad 3", 32'h03, F3_BYTE_U, 32'h00000012);

    // 4. SH then LH — halfword, positive value
    do_store(32'h10, 32'h00001234, F3_HALF);
    check_load("LH positive ad 10", 32'h10, F3_HALF, 32'h00001234);

    // 5. SH then LH — halfword, negative value (sign extend test)
    do_store(32'h14, 32'h0000FFFF, F3_HALF);
    check_load("LH negative adress 14", 32'h14, F3_HALF, 32'hFFFFFFFF);

    // 6. Same negative halfword read as LHU — zero extend instead
    check_load("LHU adress 14", 32'h14, F3_HALF_U, 32'h0000FFFF);

    // 7. SB then LB — single byte store/load
    do_store(32'h20, 32'h000000AB, F3_BYTE); // 1010 1011 - AB
    check_load("SB/LB roundtrip", 32'h20, F3_BYTE, 32'hFFFFFFAB);
    check_load("SB/LBU roundtrip", 32'h20, F3_BYTE_U, 32'h000000AB);

    // 8. Overwrite test — store twice, confirm second wins
    do_store(32'h30, 32'hAAAAAAAA, F3_WORD);
    do_store(32'h30, 32'hBBBBBBBB, F3_WORD);
    check_load("Overwrite", 32'h30, F3_WORD, 32'hBBBBBBBB);

    // 9. mem_read=0 must output 0 regardless of memory contents
    r_mem_read = 1'b0;
    r_addr     = 32'h00;
    r_funct3   = F3_WORD;
    #1;
    $display("----------------------------------------------");
    $display("TEST: mem_read=0  → data=0x%h  (expect 0x00000000)", w_rd_data);
    if (w_rd_data === 32'h0)
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