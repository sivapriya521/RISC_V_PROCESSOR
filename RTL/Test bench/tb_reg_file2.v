`timescale 1ns/1ps
module reg_filetb;

    reg clk;

    reg [4:0] rs1_ad;
    reg [4:0] rs2_ad;

    reg we;
    reg [4:0] rd_ad;
    reg [31:0] rd_dat;

    wire [31:0] rs1_dat;
    wire [31:0] rs2_dat;

    reg_file uut(
        .clk(clk),

        .rs1_ad(rs1_ad),
        .rs1_dat(rs1_dat),

        .rs2_ad(rs2_ad),
        .rs2_dat(rs2_dat),

        .we(we),
        .rd_ad(rd_ad),
        .rd_dat(rd_dat)
    );
  
    // Clock Generation
    always #5 clk = ~clk;

    initial begin

        clk = 0;

        we = 0;
        rs1_ad = 0;
        rs2_ad = 0;
        rd_ad = 0;
        rd_dat = 0;

        // Write 100 to x1
        #10;
        we = 1;
        rd_ad = 5'd1;
        rd_dat = 32'd100;

        #10;
        we = 0;

        // Read x1
        rs1_ad = 5'd1;

        #10;

        // Write 200 to x2
        we = 1;
        rd_ad = 5'd2;
        rd_dat = 32'd200;

        #10;
        we = 0;

        // Read x1 and x2 together
        rs1_ad = 5'd1;
        rs2_ad = 5'd2;

        #10;

        // Try writing x0
        we = 1;
        rd_ad = 5'd0;
        rd_dat = 32'd999;

        #10;
        we = 0;

        // Read x0
        rs1_ad = 5'd0;

        #10;

        $stop;

    end

endmodule