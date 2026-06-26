// liu and auipc not included so do it in integrating file
module ALU(
    input [31:0] a,
    input [31:0] b,
    input [3:0] ctrl_sig,
    output reg [31:0] result //result in always block so used reg
);
always @(*) begin
    case(ctrl_sig)

    //arithmetic
    4'b0000 : result= a+b;
    4'b0001 : result= a-b;

    //logical
    4'b0010 : result= a&b;
    4'b0011 : result= a|b;
    4'b0100 : result= a^b;

    //shift
    4'b0101 : result= a<<b[4:0];  //sll
    4'b0110 : result= a>>b[4:0]; //srl
    4'b0111 : result= $signed(a)>>>b[4:0]; //sra

    // comparison
    4'b1000 : result= ($signed(a) < $signed(b))? 32'd1 : 32'd0; //slt
    4'b1001 : result= (a<b)?  32'd1 : 32'd0; //sltu

    default : result = 32'd0;
endcase
end
endmodule

