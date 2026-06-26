// Purpose:
//   Byte-addressable data memory supporting LB/LH/LW/LBU/LHU loads and SB/SH/SW stores. Width and sign-extension are selected by funct3
//   - WRITE is synchronous (posedge clk) — same theory as reg_file
//   - READ is asynchronous (combinational) — pipeline needs the
//     loaded value available within the same MEM cycle for WB
//   - Memory array stored as bytes, so byte/half/word stores can
//     all share the same underlying array cleanly

module datamemory
(
  input         i_clk,
  input         i_mem_read,    // from control unit
  input         i_mem_write,   // from control unit
  input  [2:0]  i_funct3,      // selects byte/half/word + sign
  input  [31:0] i_addr,        // from ALU (rs1 + imm)
  input  [31:0] i_wr_data,     // from rs2 (store data)
  output [31:0] o_rd_data      // loaded value (or 0 if not reading)
);
  
  // funct3 constants
  localparam F3_BYTE       = 3'b000; // LB / SB
  localparam F3_HALF       = 3'b001; // LH / SH
  localparam F3_WORD       = 3'b010; // LW / SW
  localparam F3_BYTE_U     = 3'b100; // LBU
  localparam F3_HALF_U     = 3'b101; // LHU

  // Memory array — byte addressable, 4096 bytes (1KB x4) by default
  localparam c_MEM_BYTES = 4096;
  reg [7:0] r_mem [0:c_MEM_BYTES-1]; //. Each element of r_mem is declared as 8 bits wide:

  // storing 8 bits zero in evry reg
  integer i;
  initial begin
    for (i = 0; i < c_MEM_BYTES; i = i + 1)
      r_mem[i] = 8'b0;
  end

  // WRITE — synchronous, byte/half/word selectable
  always @(posedge i_clk)
  begin
    if (i_mem_write)
    begin
      case (i_funct3)
        F3_BYTE: r_mem[i_addr] <= i_wr_data[7:0]; //Only the bottom 8 bits of i_wr_data matter;

        F3_HALF: // write 16 bits across two consecutive byte locations
        begin
          r_mem[i_addr]     <= i_wr_data[7:0];
          r_mem[i_addr + 1] <= i_wr_data[15:8];
        end

        F3_WORD: // same little-endian idea extended to all 4 bytes
        begin
          r_mem[i_addr]     <= i_wr_data[7:0];
          r_mem[i_addr + 1] <= i_wr_data[15:8];
          r_mem[i_addr + 2] <= i_wr_data[23:16];
          r_mem[i_addr + 3] <= i_wr_data[31:24];
        end

        default: ; // SB/SH/SW only — others ignored on write
      endcase
    end
  end

  // READ — combinational, sign/zero extension per funct3
  reg [31:0] r_rd_data;

  always @(*) begin
    r_rd_data = 32'b0; // safe default if mem_read=0 or bad funct3

    if (i_mem_read) begin
      case (i_funct3)
        F3_BYTE:   // LB — sign extend from bit 7
          r_rd_data = {{24{r_mem[i_addr][7]}}, r_mem[i_addr]};

        F3_BYTE_U: // LBU — zero extend
          r_rd_data = {24'b0, r_mem[i_addr]};

        F3_HALF:   // LH — sign extend from bit 15
          r_rd_data = {{16{r_mem[i_addr+1][7]}},r_mem[i_addr+1], r_mem[i_addr]};

        F3_HALF_U: // LHU — zero extend
          r_rd_data = {16'b0, r_mem[i_addr+1], r_mem[i_addr]};

        F3_WORD:   // LW — full word, no extension needed
          r_rd_data = {r_mem[i_addr+3], r_mem[i_addr+2], r_mem[i_addr+1], r_mem[i_addr]};

        default:r_rd_data = 32'b0;
      endcase
    end
  end
 assign o_rd_data = r_rd_data; // o_rd_data is a wire so cant be used inside always
endmodule