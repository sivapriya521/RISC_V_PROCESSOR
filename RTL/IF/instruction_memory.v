module instruction_memory
#(
  parameter DEPTH    = 256,               // words  (256 × 4 B = 1 KB)
  parameter HEX_FILE = "C:/Users/kmsiv/OneDrive/Documents/preps/risc v 5 pipeline/implementation/program.hex"      // preload file (relative path)
)
(
  input  wire [31:0] i_pc,        // byte address from PC
  output wire [31:0] o_instr,     // 32-bit instruction out
  output wire        o_misalign   // 1 = PC not 4-byte aligned (error flag)
);
  reg [31:0] mem [0:DEPTH-1];
  localparam ADDR_BITS = $clog2(DEPTH);

  initial
  begin
    $readmemh(HEX_FILE, mem);
  end

  assign o_instr    = mem[i_pc[ADDR_BITS+1 : 2]];

  assign o_misalign = |i_pc[1:0];   

endmodule