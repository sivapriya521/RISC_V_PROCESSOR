`timescale 1ns/1ps
module ALU_tb;
    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] ctrl_sig;
    wire[31:0] result;

    ALU uut(
        .a(a),
        .b(b),
        .ctrl_sig(ctrl_sig),
        .result(result)
    );

initial begin

    a=10;
    b=5;
    ctrl_sig = 4'b0000; #10; // ADD
    ctrl_sig = 4'b0001; #10; // SUB
    ctrl_sig = 4'b0010; #10; // AND
    ctrl_sig = 4'b0011; #10; // OR
    ctrl_sig = 4'b0100; #10; // XOR

    a=8;
    b=2;
    ctrl_sig = 4'b0101; #10; // SLL
    ctrl_sig = 4'b0110; #10; // SRL

    a = -16;
    b = 2;
    ctrl_sig = 4'b0111; #10; // SRA

    a = -5;
    b = 3;
    ctrl_sig = 4'b1000; #10; // SLT

    a = 32'hFFFFFFFF;
    b = 32'd1;
    ctrl_sig = 4'b1001; #10; // SLTU

    $stop;
end
endmodule