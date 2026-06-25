module reg_file(
    input clk,we,
    input [4:0] rs1_ad, //adress of sorce reg 1
    input [4:0] rs2_ad,
    input [4:0] rd_ad,
    input [31:0] rd_dat, //input bcs regd is written back to this reg after final stage

    output [31:0] rs1_dat,
    output [31:0] rs2_dat
);

reg [31:0] reg_f [0:31];
integer i;
initial begin
    for (i=0;i<32;i=i+1)
        reg_f[i]=32'd0; // for doesnt need end for one statement
end 

assign rs1_dat = (rs1_ad==5'd0)? 32'd0 : reg_f[rs1_ad];
assign rs2_dat = (rs2_ad==5'd0)? 32'd0 : reg_f[rs2_ad];

always @(posedge clk) begin
    if (we && (rd_ad != 5'd0))
        reg_f[rd_ad] <= rd_dat; // at rising edge
end

endmodule
